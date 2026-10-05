import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'chatbot_screen.dart';
import 'chat_provider.dart';
import 'chatbot_services.dart';

final logger = Logger();

mixin ChatbotLogic on State<ChatbotPage> {
  // --- Controllers ---
  final TextEditingController textController = TextEditingController();
  final ScrollController messagesController = ScrollController();
  late AnimationController dotsController;

  // --- State Variables ---
  bool isLoading = false;
  bool showTyping = false;
  int userMessageCount = 0;

  // --- Suggestions Variables ---
  bool showSuggestions = false;
  final List<String> suggestionLabels = const [
    "Get a Meal Plan",
    "Track My Food",
    "Analyze this food photo",
    "Set a fitness Goal",
  ];
  late List<bool> suggestionVisible;

  // --- Profile & Media Variables ---
  Map<String, dynamic>? profile;
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  bool speechAvailable = false;
  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Initialize Animation
    dotsController = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize Suggestions (Hidden by default)
    suggestionVisible = List<bool>.filled(suggestionLabels.length, false);

    // ✅ Startup Logic
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // 1. Ensure we have an active chat
      if (chatProvider.activeChatId == null) {
        await chatProvider.setActiveToLatestOrNull();
      }

      // 2. Load Profile (for context)
      await _loadProfile();

      // 3. ✅ Check and Trigger Greeting + Animation
      if (chatProvider.activeChatId != null) {
        await _handleInitialGreeting(chatProvider);
      }
    });
  }

  @override
  void dispose() {
    messagesController.dispose();
    dotsController.dispose();
    textController.dispose();
    speech.stop();
    super.dispose();
  }

  // --- Helper Methods ---

  void _initSpeech() async {
    try {
      speechAvailable = await speech.initialize(
        onStatus: (status) => logger.d('Speech status: $status'),
        onError: (error) => logger.e('Speech error: $error'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      logger.e("Speech initialization failed: $e");
    }
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ChatbotService.loadUserProfile();
      if (!mounted) return;
      setState(() => profile = p);
    } catch (e) {
      logger.e('Failed to load profile: $e');
    }
  }

  // ✅ NEW: Handles the UI Animation + DB Call for Greeting
  Future<void> _handleInitialGreeting(ChatProvider chatProvider) async {
    final chatId = chatProvider.activeChatId;
    if (chatId == null) return;

    try {
      // Check if chat is actually empty first
      final msgs = await FirebaseFirestore.instance
          .collection('ChatsCollection')
          .doc(chatId)
          .collection('messages')
          .limit(1) // Optimization: Only fetch 1 to check existence
          .get();

      if (msgs.docs.isEmpty) {
        // Chat is empty! Start Typing Animation
        if (!mounted) return;
        setState(() => showTyping = true);
        dotsController.repeat();

        // Wait for visual effect (1.5 seconds)
        await Future.delayed(const Duration(milliseconds: 1500));

        // Call Provider to save the greeting to DB
        // (Provider handles fetching profile and formatting text)
        await chatProvider.checkAndSendGreeting();

        // Stop Animation
        if (!mounted) return;
        setState(() => showTyping = false);
        dotsController.stop();
      }
    } catch (e) {
      logger.e("Error handling greeting: $e");
    }
  }

  // --- Input Actions ---

  void toggleListening() async {
    if (!speechAvailable) {
      bool perm = await Permission.microphone.request().isGranted;
      if (!perm) return;
      _initSpeech();
    }

    if (isListening) {
      speech.stop();
      setState(() => isListening = false);
    } else {
      setState(() => isListening = true);
      speech.listen(
        onResult: (val) {
          setState(() {
            textController.text = val.recognizedWords;
            textController.selection = TextSelection.fromPosition(
              TextPosition(offset: textController.text.length),
            );
          });
        },
      );
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 40,
      );
      if (picked != null) {
        setState(() {
          selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      logger.e("Error picking image: $e");
    }
  }

  void removeSelectedImage() {
    setState(() => selectedImage = null);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && selectedImage == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final isSuggestionTap = suggestionLabels.contains(trimmed);

    if (!mounted) return;
    setState(() {
      isLoading = true;
      showTyping = true;
      userMessageCount += 1;
      if (isSuggestionTap || showSuggestions) _hideSuggestions();
    });

    dotsController.repeat();

    // 1. Send User Message
    String? base64ImageString;
    if (selectedImage != null) {
      final bytes = await selectedImage!.readAsBytes();
      base64ImageString = base64Encode(bytes);
    }

    await chatProvider.addMessage(
      "user",
      trimmed,
      imageBase64: base64ImageString,
    );

    final File? imageToSend = selectedImage;
    if (!mounted) return;
    textController.clear();
    setState(() {
      selectedImage = null;
      isListening = false;
    });
    scrollToLatest();

    // 2. Fetch Recent Conversation History for memory
    final history = await chatProvider.getRecentMessages(limit: 6);

    // 3. Ensure profile is loaded and fetch reply with live context & tools
    profile ??= await ChatbotService.loadUserProfile();

    final response = await ChatbotService.fetchGptTurboReply(
      userText: trimmed,
      profile: profile,
      conversationHistory: history,
      imageFile: imageToSend,
    );

    String botReplyText = "I encountered an error connecting with my nutrition brain.";

    if (response is String) {
      botReplyText = response;
    } else if (response is Map && response["isToolCall"] == true) {
      final toolCalls = response["toolCalls"] as List;
      List<String> logResults = [];

      for (var tool in toolCalls) {
        final functionName = tool["function"]["name"];
        final args = jsonDecode(tool["function"]["arguments"]);

        // --- Tool 1: log_meal ---
        if (functionName == "log_meal") {
          final foodName = args["food_name"] ?? "Meal";
          final category = args["category"] ?? "lunch";
          final estimatedCals = args["estimated_calories"] is num
              ? (args["estimated_calories"] as num).toInt()
              : null;
          final protein = (args["protein_g"] as num?)?.toDouble();
          final carbs = (args["carbs_g"] as num?)?.toDouble();
          final fat = (args["fat_g"] as num?)?.toDouble();
          final portion = args["portion"] as String?;

          String result = await _performDbLogging(
            foodName,
            category,
            estimatedCalories: estimatedCals,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            portion: portion,
          );
          logResults.add(result);
        }
        // --- Tool 2: log_water ---
        else if (functionName == "log_water") {
          final glasses = (args["glasses"] as num?)?.toDouble();
          final amountMl = (args["amount_ml"] as num?)?.toDouble();
          String result = await _performWaterLogging(glasses, amountMl);
          logResults.add(result);
        }
        // --- Tool 3: update_meal_plan ---
        else if (functionName == "update_meal_plan") {
          final mealType = args["meal_type"] ?? "Lunch";
          final foodName = args["food_name"] ?? "Healthy Choice";
          String result = await _performMealPlanUpdate(mealType, foodName);
          logResults.add(result);
        }
        // --- Tool 4: update_user_goals ---
        else if (functionName == "update_user_goals") {
          final targetWeight = (args["target_weight_kg"] as num?)?.toDouble();
          final calorieTarget = (args["daily_calorie_target"] as num?)?.toInt();
          final dietPref = args["diet_preference"] as String?;
          String result = await _performGoalUpdate(
            targetWeightKg: targetWeight,
            dailyCalorieTarget: calorieTarget,
            dietPreference: dietPref,
          );
          logResults.add(result);
        }
        // --- Tool 5: get_daily_summary ---
        else if (functionName == "get_daily_summary") {
          String result = await _performDailySummaryFetch();
          logResults.add(result);
        }
      }

      final assistantMsg = response["assistantMessage"] as String?;
      if (assistantMsg != null && assistantMsg.trim().isNotEmpty) {
        botReplyText = "$assistantMsg\n\n${logResults.join('\n\n')}";
      } else if (logResults.isNotEmpty) {
        botReplyText = logResults.join("\n\n");
      }
    }

    await _showBotTypingThenReply(botReplyText);

    if (_containsTriggerKeyword(trimmed)) {
      if (!mounted) return;
      setState(() {
        showSuggestions = true;
        suggestionVisible = List<bool>.filled(suggestionLabels.length, false);
      });
      _runSuggestionStagger();
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
      showTyping = false;
    });
    dotsController.stop();
  }

  Future<String> _performMealPlanUpdate(
    String mealType,
    String foodName,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return "You need to be logged in to update your plan.";
      }

      // We use SetOptions(merge: true) to update ONLY the specific meal
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .set({
            "generatedMealPlan": {mealType: foodName},
          }, SetOptions(merge: true));

      return "✅ I've updated your **$mealType** to **$foodName** on your dashboard.";
    } catch (e) {
      logger.e("Meal Plan Update Error: $e");
      return "I tried to update your plan, but an error occurred: $e";
    }
  }

  Future<String> _performWaterLogging(double? glasses, double? amountMl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "You need to be logged in to log water.";

      double numGlasses = glasses ?? (amountMl != null ? amountMl / 250.0 : 1.0);
      if (numGlasses <= 0) numGlasses = 1.0;

      await FirebaseFirestore.instance.collection('WaterIntake').add({
        'uid': user.uid,
        'amount': numGlasses,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final ml = (numGlasses * 250).round();
      return "💧 Logged **$numGlasses glass${numGlasses == 1.0 ? '' : 'es'}** (~$ml ml) to your daily water tracker! Keep staying hydrated.";
    } catch (e) {
      logger.e("Water Logging Error: $e");
      return "Error logging water: $e";
    }
  }

  Future<String> _performGoalUpdate({
    double? targetWeightKg,
    int? dailyCalorieTarget,
    String? dietPreference,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "You need to be logged in to update goals.";

      final Map<String, dynamic> updates = {};
      if (targetWeightKg != null) updates['targetWeight'] = targetWeightKg;
      if (dailyCalorieTarget != null) updates['dailyCalorieTarget'] = dailyCalorieTarget;
      if (dietPreference != null) updates['dietPreference'] = dietPreference;

      if (updates.isEmpty) return "No changes specified.";

      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      await _loadProfile();

      List<String> changes = [];
      if (targetWeightKg != null) changes.add("• Target Weight: **${targetWeightKg}kg**");
      if (dailyCalorieTarget != null) changes.add("• Daily Calorie Goal: **$dailyCalorieTarget kcal**");
      if (dietPreference != null) changes.add("• Diet Style: **$dietPreference**");

      return "🎯 Goal updated successfully!\n${changes.join('\n')}";
    } catch (e) {
      logger.e("Goal Update Error: $e");
      return "Error updating goals: $e";
    }
  }

  Future<String> _performDailySummaryFetch() async {
    try {
      final summary = await ChatbotService.loadDailyIntakeSummary();
      final totalCals = (summary['totalCalories'] as num?)?.toInt() ?? 0;
      final protein = summary['protein'] ?? 0;
      final carbs = summary['carbs'] ?? 0;
      final fat = summary['fat'] ?? 0;
      final waterGlasses = summary['waterGlasses'] ?? 0.0;
      final waterMl = summary['waterMl'] ?? 0;
      final burnedCals = (summary['burnedCalories'] as num?)?.toInt() ?? 0;

      final liveProfile = profile ?? await ChatbotService.loadUserProfile();
      final dynamic rawTarget = liveProfile?['dailyCalorieTarget'];
      final int baseTarget = (rawTarget is num)
          ? rawTarget.round()
          : (num.tryParse(rawTarget?.toString() ?? '')?.round() ?? 2000);
      final int totalBudget = baseTarget + burnedCals;
      final int remaining = totalBudget - totalCals;

      return """
📊 **Today's Nutrition Breakdown**:
• **Calories Eaten**: $totalCals kcal
• **Daily Calorie Budget**: $totalBudget kcal${burnedCals > 0 ? ' (Includes $burnedCals kcal from exercise)' : ''}
• **Calories Remaining**: ${remaining >= 0 ? '$remaining kcal left to eat' : '${remaining.abs()} kcal over budget'}
• **Protein**: ${protein}g
• **Carbohydrates**: ${carbs}g
• **Fats**: ${fat}g
• **Water Intake**: $waterGlasses glasses (~$waterMl ml)
""";
    } catch (e) {
      return "Unable to fetch today's summary right now: $e";
    }
  }

  Future<String> _performDbLogging(
    String foodQuery,
    String category, {
    int? estimatedCalories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? portion,
  }) async {
    try {
      String toTitleCase(String text) {
        if (text.isEmpty) return text;
        return text
            .split(' ')
            .map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');
      }

      String formattedQuery = toTitleCase(foodQuery.trim());

      // Search in Firestore meals
      final querySnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .where('name', isGreaterThanOrEqualTo: formattedQuery)
          .where('name', isLessThan: '${formattedQuery}z')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return await _logFoodDoc(querySnapshot.docs.first, category);
      }

      // Check lowercase fallback
      final retrySnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .where('name', isGreaterThanOrEqualTo: foodQuery.toLowerCase())
          .where('name', isLessThan: '${foodQuery.toLowerCase()}z')
          .limit(1)
          .get();

      if (retrySnapshot.docs.isNotEmpty) {
        return await _logFoodDoc(retrySnapshot.docs.first, category);
      }

      // ✅ SMART FALLBACK: If not in DB, use AI-calculated macros so logging never fails!
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Error: You must be logged in.";
      final uid = user.uid;
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final catLower = category.toLowerCase();

      final cals = estimatedCalories ?? 300;
      final p = proteinG ?? 15.0;
      final c = carbsG ?? 35.0;
      final f = fatG ?? 10.0;

      final customLog = {
        'name': formattedQuery,
        'food_name': formattedQuery,
        'estCalories': cals,
        'calories': cals,
        'carbs': c,
        'protein': p,
        'fat': f,
        'date': todayDate,
        'category': catLower,
        'timestamp': FieldValue.serverTimestamp(),
        'loggedServing': {
          'amount': portion ?? '1 serving',
          'unit': 'serving',
          'calculatedGrams': 100.0,
        },
      };

      await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(todayDate)
          .collection(catLower)
          .add(customLog);

      return "✅ Logged **$formattedQuery** (~$cals kcal | ${p.round()}g Protein | ${c.round()}g Carbs | ${f.round()}g Fat) to your **$category** diary!";
    } catch (e) {
      logger.e("DB Logging Error: $e");
      return "I encountered a logging error: $e";
    }
  }

  // Helper to avoid code duplication

  Future<String> _logFoodDoc(
    QueryDocumentSnapshot foodDoc,
    String category,
  ) async {
    // 1. Get User ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Error: You must be logged in.";
    final uid = user.uid;

    final foodData = foodDoc.data() as Map<String, dynamic>;

    // 2. Calculate Calories
    double grams = 100.0;
    final dynamic rawServing = foodData['servingSizes'];

    if (rawServing is List && rawServing.isNotEmpty) {
      final firstOption = rawServing[0];
      if (firstOption is Map) {
        grams = double.tryParse(firstOption['grams'].toString()) ?? 100.0;
      }
    } else if (rawServing is Map) {
      grams = double.tryParse(rawServing['grams'].toString()) ?? 100.0;
    }

    double calPer100 =
        double.tryParse(foodData['caloriesPer100g'].toString()) ?? 0;
    int estCalories = ((calPer100 * grams) / 100).round();

    // Calculate Macros
    double carbsPer100 =
        double.tryParse(foodData['carbsPer100g'].toString()) ?? 0;
    double proteinPer100 =
        double.tryParse(foodData['proteinPer100g'].toString()) ?? 0;
    double fatPer100 = double.tryParse(foodData['fatPer100g'].toString()) ?? 0;

    double ratio = grams / 100.0;
    double displayCarbs = carbsPer100 * ratio;
    double displayProtein = proteinPer100 * ratio;
    double displayFat = fatPer100 * ratio;

    // 3. Prepare Data
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String catLower = category.toLowerCase(); // Ensure lowercase for path

    final logData = {
      ...foodData,
      // Overwrite/Add Calculated Values
      'estCalories': estCalories,
      'calories': estCalories,
      'carbs': displayCarbs,
      'protein': displayProtein,
      'fat': displayFat,

      // Meta Data
      'date': todayDate,
      'category': catLower,
      'timestamp': FieldValue.serverTimestamp(),

      // Save Serving Info
      'loggedServing': {
        'amount': grams,
        'unit': 'g', // Defaulting to grams for chatbot quick log
        'calculatedGrams': grams,
      },
    };

    // 4. ✅ SAVE TO CORRECT NEW HIERARCHY
    // Path: mealslog -> {uid} -> days -> {date} -> {category}
    await FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(todayDate)
        .collection(catLower)
        .add(logData);

    return "Successfully logged **${foodData['name']}** ($estCalories kcal) to your **$category**.";
  }

  Future<void> _showBotTypingThenReply(String reply) async {
    if (!mounted) return;
    setState(() => showTyping = true);
    dotsController.repeat();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.addMessage("bot", reply);

    if (!mounted) return;
    setState(() => showTyping = false);
    dotsController.stop();
    scrollToLatest();
  }

  void scrollToLatest() {
    if (!messagesController.hasClients) return;
    messagesController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _hideSuggestions() {
    if (!mounted) return;
    setState(() {
      showSuggestions = false;
      suggestionVisible = List<bool>.filled(suggestionLabels.length, false);
    });
  }

  void _runSuggestionStagger() async {
    for (int i = 0; i < suggestionLabels.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 200));
      if (!mounted || !showSuggestions) return;
      setState(() {
        suggestionVisible[i] = true;
      });
    }
  }

  bool _containsTriggerKeyword(String text) {
    final t = text.toLowerCase();
    const keywords = ["help", "options", "menu", "what can you do", "features"];
    return keywords.any((k) => t.contains(k));
  }
}
