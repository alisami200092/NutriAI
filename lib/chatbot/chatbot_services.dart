import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

final _serviceLogger = Logger();

class ChatbotService {
  static Future<void> ensureEnvLoaded() async {
    if (!dotenv.isInitialized) {
      try {
        await dotenv.load(fileName: "assets/api-key.env");
      } catch (e) {
        _serviceLogger.e("Failed to lazy-load env: $e");
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Load the Logged-in User's Profile
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _serviceLogger.w("No user logged in.");
        return null;
      }

      final doc = await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      _serviceLogger.e("Error loading user profile: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Load Live Daily Intake Context (Food Diary + Water + Macros)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> loadDailyIntakeSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final uid = user.uid;
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    double totalCals = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    Map<String, List<String>> loggedMeals = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };

    // 1. Fetch today's logged meals from mealslog/{uid}/days/{todayDate}/{category}
    for (var cat in ['breakfast', 'lunch', 'dinner', 'snack']) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('mealslog')
            .doc(uid)
            .collection('days')
            .doc(todayDate)
            .collection(cat)
            .get();

        for (var doc in snap.docs) {
          final d = doc.data();
          final name = d['name'] ?? d['food_name'] ?? 'Meal';
          final cals = (d['estCalories'] as num?)?.toDouble() ??
              (d['calories'] as num?)?.toDouble() ??
              0.0;
          final p = (d['protein'] as num?)?.toDouble() ?? 0.0;
          final c = (d['carbs'] as num?)?.toDouble() ?? 0.0;
          final f = (d['fat'] as num?)?.toDouble() ?? 0.0;

          totalCals += cals;
          totalProtein += p;
          totalCarbs += c;
          totalFat += f;

          loggedMeals[cat]!.add("$name (${cals.round()} kcal, ${p.round()}g P, ${c.round()}g C, ${f.round()}g F)");
        }
      } catch (e) {
        _serviceLogger.w("Error fetching today's $cat: $e");
      }
    }

    // 2. Fetch today's water from WaterIntake
    double totalWaterGlasses = 0;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final waterSnap = await FirebaseFirestore.instance
          .collection('WaterIntake')
          .where('uid', isEqualTo: uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in waterSnap.docs) {
        final d = doc.data();
        if (d.containsKey('amount')) {
          totalWaterGlasses += (d['amount'] as num).toDouble();
        }
      }
    } catch (e) {
      _serviceLogger.w("Error fetching today's water: $e");
    }

    // 3. Fetch today's burned calories from ActivityLog
    int burnedCalories = 0;
    try {
      final now = DateTime.now();
      final actSnap = await FirebaseFirestore.instance
          .collection('ActivityLog')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in actSnap.docs) {
        final d = doc.data();
        if (d['date'] != null) {
          final docDate = (d['date'] as Timestamp).toDate();
          if (docDate.year == now.year &&
              docDate.month == now.month &&
              docDate.day == now.day) {
            burnedCalories += (d['caloriesBurned'] as num? ?? 0).toInt();
          }
        }
      }
    } catch (e) {
      _serviceLogger.w("Error fetching today's activity: $e");
    }

    return {
      'date': todayDate,
      'totalCalories': totalCals.round(),
      'protein': totalProtein.round(),
      'carbs': totalCarbs.round(),
      'fat': totalFat.round(),
      'waterGlasses': totalWaterGlasses,
      'waterMl': (totalWaterGlasses * 250).round(),
      'burnedCalories': burnedCalories,
      'loggedMeals': loggedMeals,
    };
  }

  // ---------------------------------------------------------------------------
  // Build Empathetic, Highly Context-Aware System Prompt
  // ---------------------------------------------------------------------------
  static String _buildSystemPrompt(
    Map<String, dynamic>? profile,
    Map<String, dynamic>? dailyIntake,
  ) {
    final name = profile?['name'] ?? 'Friend';
    final age = profile?['age']?.toString() ?? '25';
    final gender = profile?['gender'] ?? 'Not specified';
    final height = profile?['height']?.toString() ?? '175';
    final weight = profile?['weight']?.toString() ?? '75';
    final targetWeight = profile?['targetWeight']?.toString() ?? '70';
    final goal = profile?['dietaryGoal'] ?? 'Fat Loss & Healthy Living';
    final activity = profile?['activityLevel'] ?? 'Moderate';
    final dietType = profile?['dietPreference'] ?? profile?['dietType'] ?? 'Pakistani / Indian';
    final conditions = profile?['healthConditions'] ?? 'None';
    final restrictions = profile?['restrictions'] ?? 'None';
    final eventName = profile?['eventName'] ?? 'Healthy Lifestyle';

    // Robust Calorie Target Parsing
    final dynamic rawTarget = profile?['dailyCalorieTarget'];
    final int baseTargetCals = (rawTarget is num)
        ? rawTarget.round()
        : (num.tryParse(rawTarget?.toString() ?? '')?.round() ?? 2000);

    final int burnedCals = (dailyIntake?['burnedCalories'] as num?)?.toInt() ?? 0;
    final int totalBudgetCals = baseTargetCals + burnedCals;

    // Daily Intake Details
    final int totalEaten = (dailyIntake?['totalCalories'] as num?)?.toInt() ?? 0;
    final int remainingCals = totalBudgetCals - totalEaten;
    final proteinEaten = dailyIntake?['protein'] ?? 0;
    final carbsEaten = dailyIntake?['carbs'] ?? 0;
    final fatEaten = dailyIntake?['fat'] ?? 0;
    final waterGlasses = dailyIntake?['waterGlasses'] ?? 0.0;
    final waterMl = dailyIntake?['waterMl'] ?? 0;

    final loggedMeals = dailyIntake?['loggedMeals'] as Map<String, dynamic>?;
    final breakfastList = (loggedMeals?['breakfast'] as List?)?.join(', ') ?? 'None logged yet';
    final lunchList = (loggedMeals?['lunch'] as List?)?.join(', ') ?? 'None logged yet';
    final dinnerList = (loggedMeals?['dinner'] as List?)?.join(', ') ?? 'None logged yet';
    final snackList = (loggedMeals?['snack'] as List?)?.join(', ') ?? 'None logged yet';

    return """
You are NutriAI, an empathetic, highly knowledgeable, and friendly personal nutrition companion and live wellness coach.

### USER BIOMETRIC & GOAL PROFILE:
- Name: $name
- Age: $age | Gender: $gender | Height: $height cm | Weight: $weight kg
- Target Weight: $targetWeight kg (Working towards: $eventName)
- Goal: $goal | Activity Level: $activity
- Cuisine/Diet Preference: $dietType (Supports authentic Indian, Pakistani & Global meals)
- Dietary Restrictions: $restrictions
- Health Conditions: $conditions
- Daily Calorie Target: $baseTargetCals kcal

### 🎯 LIVE DAILY TRACKING DATA (TODAY):
• FOOD EATEN TODAY: $totalEaten kcal
• DAILY CALORIE BUDGET: $totalBudgetCals kcal (Base Goal: $baseTargetCals kcal${burnedCals > 0 ? ' + $burnedCals kcal earned from exercise' : ''})
• CALORIES REMAINING TO EAT: $remainingCals kcal (${remainingCals >= 0 ? '$remainingCals kcal remaining left' : '${remainingCals.abs()} kcal over budget!'})
• PROTEIN CONSUMED: ${proteinEaten}g
• CARBS CONSUMED: ${carbsEaten}g
• FAT CONSUMED: ${fatEaten}g
• WATER LOGGED: $waterGlasses glasses (~$waterMl ml / 2000 ml target)
• MEALS LOGGED TODAY:
  • Breakfast: $breakfastList
  • Lunch: $lunchList
  • Dinner: $dinnerList
  • Snacks: $snackList

### ⚠️ ABSOLUTE ACCURACY RULES FOR CALORIES:
1. **NEVER SWAP OR CONFUSE EATEN CALORIES WITH REMAINING CALORIES!**
   - If the user asks: "How much did I eat?", "How many calories have I consumed?", or similar:
     👉 ANSWER: "You have eaten **$totalEaten kcal** today."
   - If the user asks: "How many calories do I have remaining / left?", "Can I eat more?", or similar:
     👉 ANSWER: "You have **$remainingCals kcal remaining** today out of your $totalBudgetCals kcal daily budget."
   - **CRITICAL**: The user has **EATEN $totalEaten kcal**, and has **$remainingCals kcal REMAINING**. NEVER tell them they have "$totalEaten kcal remaining"! That is what they ate.
2. If remaining calories is positive ($remainingCals > 0), they still have room to consume $remainingCals kcal.

### COACHING PERSONA & RULES:
1. **Friendly & Conversational**: Talk like a supportive, knowledgeable friend. Celebrate their consistency, use emojis warmly, and explain the science of food simply. Never sound robotic or judgmental.
2. **Daily Context Awareness**: You ALWAYS know what they've already eaten today. If they ask what to eat for lunch or dinner, inspect their remaining calories ($remainingCals kcal) and protein balance (${proteinEaten}g so far) and suggest meals from their preference ($dietType) that fit their remaining budget!
3. **Medical Guardrails & Harmful Food Warnings**:
   - If the user has health conditions ($conditions), warn them if a food they ask about is dangerous. E.g., for Diabetes: high glycemic carbs/refined sugar cause acute glucose spikes; for Hypertension: high sodium causes fluid retention and blood pressure spikes.
   - If they want to eat junk food or high-calorie treats, explain the physiological reaction warmly: "That will spike insulin and use most of your remaining $remainingCals kcal. If you crave it, let's have half and add cucumber raita or salad to slow digestion!"
4. **App Interaction via Tools (EXECUTE WHENEVER REQUESTED)**:
   - When the user mentions having eaten something, call `log_meal`. If the food isn't in a database, provide estimated calories and macros so it still logs!
   - When the user logs water (e.g. "I drank 2 glasses of water"), call `log_water`.
   - When the user wants to adjust their dashboard meal plan (e.g. "Change my lunch to Chicken Karahi"), call `update_meal_plan`.
   - When the user wants to update their weight target or calorie goal, call `update_user_goals`.
   - When the user asks for their progress or full breakdown, call `get_daily_summary`.
""";
  }

  // ---------------------------------------------------------------------------
  // STEP 2: OPENAI API CALL WITH EXPANDED TOOLS & LIVE CONTEXT
  // ---------------------------------------------------------------------------
  static Future<dynamic> fetchGptTurboReply({
    required String userText,
    required Map<String, dynamic>? profile,
    Map<String, dynamic>? dailyIntake,
    List<Map<String, dynamic>>? conversationHistory,
    File? imageFile,
  }) async {
    try {
      await ensureEnvLoaded();
      final apiKey = dotenv.env['OPENAI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        return "Error: OpenAI API Key is missing in assets/api-key.env.";
      }

      // If profile or dailyIntake wasn't passed, fetch them now dynamically
      final liveProfile = profile ?? await loadUserProfile();
      final liveIntake = dailyIntake ?? await loadDailyIntakeSummary();
      final systemContent = _buildSystemPrompt(liveProfile, liveIntake);

      List<Map<String, dynamic>> messages = [
        {"role": "system", "content": systemContent},
      ];

      // Add recent conversation history (last 6 messages for context memory)
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final recent = conversationHistory.length > 6
            ? conversationHistory.sublist(conversationHistory.length - 6)
            : conversationHistory;
        for (var msg in recent) {
          messages.add(msg);
        }
      }

      // Current user turn
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        messages.add({
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": userText.isEmpty
                  ? "Identify all the food items in this photo. Estimate the portion size (grams), total calories, protein, carbs, and fat. Give practical advice and ask if I would like you to log this meal."
                  : userText,
            },
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,$base64Image",
                "detail": "auto",
              },
            },
          ],
        });
      } else {
        messages.add({"role": "user", "content": userText});
      }

      // ✅ COMPREHENSIVE TOOLS FOR APP INTERACTION
      final tools = [
        // 1. Log Meal
        {
          "type": "function",
          "function": {
            "name": "log_meal",
            "description":
                "Log a food item with calories and macros to the user's food diary for today.",
            "parameters": {
              "type": "object",
              "properties": {
                "food_name": {
                  "type": "string",
                  "description": "Name of the food item in Title Case (e.g., 'Chicken Biryani', 'Greek Yogurt', '2 Boiled Eggs').",
                },
                "category": {
                  "type": "string",
                  "enum": ["breakfast", "lunch", "dinner", "snack"],
                  "description": "The meal category.",
                },
                "portion": {
                  "type": "string",
                  "description": "Portion size (e.g. '1 plate', '250g', '2 slices').",
                },
                "estimated_calories": {
                  "type": "integer",
                  "description": "Estimated calories if not found in db (e.g. 450).",
                },
                "protein_g": {
                  "type": "number",
                  "description": "Estimated protein in grams.",
                },
                "carbs_g": {
                  "type": "number",
                  "description": "Estimated carbs in grams.",
                },
                "fat_g": {
                  "type": "number",
                  "description": "Estimated fat in grams.",
                },
              },
              "required": ["food_name", "category"],
            },
          },
        },
        // 2. Log Water
        {
          "type": "function",
          "function": {
            "name": "log_water",
            "description":
                "Record water intake to the user's daily water tracker.",
            "parameters": {
              "type": "object",
              "properties": {
                "glasses": {
                  "type": "number",
                  "description": "Number of glasses (e.g. 1.0, 2.0, 0.5). Each glass is 250ml.",
                },
                "amount_ml": {
                  "type": "number",
                  "description": "Amount in milliliters (e.g. 250, 500, 1000).",
                },
              },
            },
          },
        },
        // 3. Update Meal Plan on Dashboard
        {
          "type": "function",
          "function": {
            "name": "update_meal_plan",
            "description":
                "Update a specific meal in the user's live dashboard meal plan (e.g. 'Change my lunch to Grilled Fish').",
            "parameters": {
              "type": "object",
              "properties": {
                "meal_type": {
                  "type": "string",
                  "enum": ["Breakfast", "Lunch", "Dinner", "Snack"],
                  "description": "The meal slot to update.",
                },
                "food_name": {
                  "type": "string",
                  "description": "The new food name in Title Case.",
                },
              },
              "required": ["meal_type", "food_name"],
            },
          },
        },
        // 4. Update User Goals
        {
          "type": "function",
          "function": {
            "name": "update_user_goals",
            "description":
                "Update user's target weight, calorie budget, or dietary preference in their profile.",
            "parameters": {
              "type": "object",
              "properties": {
                "target_weight_kg": {
                  "type": "number",
                  "description": "New target weight in kilograms.",
                },
                "daily_calorie_target": {
                  "type": "integer",
                  "description": "New daily calorie budget in kcal.",
                },
                "diet_preference": {
                  "type": "string",
                  "description": "Updated diet or cuisine preference (e.g. 'Pakistani', 'Indian', 'Keto', 'High Protein').",
                },
              },
            },
          },
        },
        // 5. Get Daily Summary
        {
          "type": "function",
          "function": {
            "name": "get_daily_summary",
            "description":
                "Fetch up-to-the-minute calories, macros, and water status for today.",
            "parameters": {
              "type": "object",
              "properties": {},
            },
          },
        },
      ];

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": messages,
          "tools": tools,
          "tool_choice": "auto",
          "max_tokens": 500,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choice = data["choices"][0]["message"];

        if (choice["tool_calls"] != null) {
          return {
            "isToolCall": true,
            "toolCalls": choice["tool_calls"],
            "assistantMessage": choice["content"],
          };
        }

        return choice["content"];
      } else {
        _serviceLogger.e(
          "OpenAI Error: ${response.statusCode} - ${response.body}",
        );
        return "I'm having trouble connecting to my AI brain right now (${response.statusCode}). Please verify your OpenAI key.";
      }
    } catch (e) {
      _serviceLogger.e("Exception in fetchGptTurboReply: $e");
      return "Something went wrong: $e";
    }
  }
}
