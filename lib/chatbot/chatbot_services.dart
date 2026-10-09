import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'package:nutriapp/services/red_flag_triage_service.dart';

final _serviceLogger = Logger();

class ChatbotService {
  static const String redFlagTriageNotice = RedFlagTriageService.triageNotice;

  /// Checks for clinical red-flag symptoms requiring immediate medical triage.
  static bool hasRedFlagSymptoms(String input) =>
      RedFlagTriageService.hasRedFlag(input);

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
You are NutriBot, an empathetic, friendly personal nutrition coach and wellness companion.

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
1. NEVER swap or confuse eaten calories with remaining calories!
   - If the user asks how much they ate: Tell them they have eaten $totalEaten kcal today.
   - If the user asks how many calories they have remaining/left: Tell them they have $remainingCals kcal left out of their $totalBudgetCals kcal daily budget.
   - The user has EATEN $totalEaten kcal, and has $remainingCals kcal REMAINING.
2. If remaining calories is positive ($remainingCals > 0), they still have room to consume $remainingCals kcal.

### 💬 STRICT CONVERSATIONAL VOICE & FORMATTING RULES:
1. **Talk Like a Human, Not a Bot**:
   - Speak in a natural, caring, human conversational voice, like an expert nutrition coach texting with a friend.
   - DO NOT use triple asterisks (***) or annoying markdown symbols. Avoid asterisk clutter.
   - DO NOT format responses like a robotic AI report with rigid headers (avoid headers like 'Meal Recommendation Breakdown:', 'Key Observations:', 'Nutritional Summary:').
   - When listing meals, options, or tips, use clean bullet points (•) or a numbered format like 1), 2), 3) instead of dashes or raw asterisks.
   - Keep answers conversational in natural, pleasant paragraphs with warm emojis.
2. **Context-Aware Suggestions**:
   - You always know what they ate today. If they ask what to eat for lunch or dinner, look at their remaining calories ($remainingCals kcal) and protein (${proteinEaten}g so far), and warmly recommend specific meals from their preferred cuisine ($dietType) that fit their remaining budget.
3. **Strict Medical Guardrails & Clinical Non-Prescriptive Safety Boundaries**:
   - You are a supportive nutrition and wellness coach, NOT a medical doctor or physician.
   - You must NEVER suggest, recommend, or prescribe medications (e.g., antacids, loperamide, laxatives, bismuth, antibiotics, omeprazole, painkillers) and NEVER diagnose diseases, conditions, or illnesses.
   - Non-prescriptive dietary and lifestyle guidance ONLY.
   - ⚠️ IMMEDIATE RED-FLAG SYMPTOM TRIAGE GUARD:
     If the user reports any of the following critical red-flag warning signs:
     • Severe localized / sharp abdominal pain
     • High fever
     • Blood in stool / black stool
     • Continuous vomiting or unable to hold liquids for 24 hours
     • Unexplained fainting or severe dizziness
     You MUST IMMEDIATELY DISENGAGE from meal planning and dietary suggestions.
     Do NOT recommend home remedies, foods, or medicines.
     Output EXACTLY this mandatory clinical triage notice:
     "⚠️ These symptoms may require immediate medical attention. Please consult a qualified doctor or visit an urgent care center promptly."

4. **App Tools Execution**:
   - When the user mentions eating something, call `log_meal`.
   - When the user logs water, call `log_water`.
   - When the user wants to adjust their dashboard meal plan, call `update_meal_plan`.
   - When the user wants to update their weight target or calorie goal, call `update_user_goals`.
   - When the user asks for their full daily summary, call `get_daily_summary`.
   - When the user mentions digestive distress, upset stomach, or GI motility changes, IMMEDIATELY call `report_gi_symptoms`:
     • If Constipation (e.g., haven't gone in 2 days, straining, hard stool):
       motility_state: "constipation", dietary_strategy: "high_fiber_hydration", blocked_triggers: ["dry_refined"]
     • If Diarrhea / loose stools (e.g., watery stools, stomach running, loose motions):
       motility_state: "diarrhea", dietary_strategy: "low_residue_bland", blocked_triggers: ["spicy", "dairy", "heavy_oil", "insoluble_roughage"]
     • If Nausea (e.g., feeling sick to stomach, queasy, want to throw up):
       motility_state: "nausea", dietary_strategy: "gastric_sparing", blocked_triggers: ["heavy_oil", "spicy", "heavy_fat"]
     • If other digestive discomfort (reflux, heartburn, bloating):
       motility_state: "normal", dietary_strategy: "normal", blocked_triggers: ["spicy", "acidic", "deep_fried"]
   - When the user reports feeling better or wanting to deactivate Gut Shield, call `deactivate_gut_shield`.
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
      // Deterministic Red-Flag Triage Guard:
      if (hasRedFlagSymptoms(userText)) {
        return redFlagTriageNotice;
      }

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
        // 6. Report GI Symptoms (Gut Shield & Motility Management)
        {
          "type": "function",
          "function": {
            "name": "report_gi_symptoms",
            "description":
                "Triggered when user mentions digestive distress, motility changes (constipation, diarrhea, nausea), bloating, reflux, or cramping.",
            "parameters": {
              "type": "object",
              "properties": {
                "motility_state": {
                  "type": "string",
                  "enum": ["constipation", "diarrhea", "nausea", "normal"],
                  "description":
                      "Functional GI motility state: 'constipation', 'diarrhea', 'nausea', or 'normal'.",
                },
                "dietary_strategy": {
                  "type": "string",
                  "enum": [
                    "high_fiber_hydration",
                    "low_residue_bland",
                    "gastric_sparing",
                    "normal"
                  ],
                  "description":
                      "Targeted dietary strategy: 'high_fiber_hydration' (for constipation), 'low_residue_bland' (for diarrhea), 'gastric_sparing' (for nausea), or 'normal'.",
                },
                "blocked_triggers": {
                  "type": "array",
                  "items": {
                    "type": "string",
                  },
                  "description":
                      "List of trigger categories to block (e.g. ['dry_refined'] for constipation; ['spicy', 'dairy', 'heavy_oil', 'insoluble_roughage'] for diarrhea; ['heavy_oil', 'spicy', 'heavy_fat'] for nausea).",
                },
                "symptom_summary": {
                  "type": "string",
                  "description":
                      "Brief clinical non-diagnostic summary of the user's reported symptoms.",
                },
                "is_flare_up": {
                  "type": "boolean",
                  "description":
                      "Set to true when the user is experiencing an active symptom flare-up.",
                },
              },
              "required": [
                "motility_state",
                "dietary_strategy",
                "blocked_triggers",
                "symptom_summary",
                "is_flare_up"
              ],
            },
          },
        },
        // 7. Deactivate Gut Shield
        {
          "type": "function",
          "function": {
            "name": "deactivate_gut_shield",
            "description":
                "Triggered when the user reports that their stomach feels better, symptoms are resolved, or they want to turn off the Gut Shield.",
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

  // ---------------------------------------------------------------------------
  // STEP 3: GENERATE CLINICAL DOCTOR SUMMARY REPORT
  // ---------------------------------------------------------------------------
  static Future<String> generateDoctorSummaryReport({
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? giData,
    required List<Map<String, dynamic>> recentMeals,
  }) async {
    try {
      await ensureEnvLoaded();
      final apiKey = dotenv.env['OPENAI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        return "Error: OpenAI API Key is missing in assets/api-key.env.";
      }

      final name = profile?['name'] ?? 'Patient';
      final age = profile?['age'] ?? 'N/A';
      final gender = profile?['gender'] ?? 'N/A';
      final conditions = profile?['healthConditions'] ?? 'None reported';
      final dietType =
          profile?['dietPreference'] ?? profile?['dietType'] ?? 'Standard';

      final symptomSummary =
          giData?['symptom_summary'] ?? 'Occasional digestive discomfort';
      final activeTriggers =
          (giData?['active_gi_triggers'] as List?)?.join(', ') ?? 'None';
      final lastIncident = giData?['last_gi_incident'] != null
          ? giData!['last_gi_incident'].toString()
          : 'Recent';

      final mealsBuffer = StringBuffer();
      if (recentMeals.isEmpty) {
        mealsBuffer.writeln("No specific meals logged in the recent window.");
      } else {
        for (final m in recentMeals) {
          mealsBuffer.writeln(
            "- ${m['category'] ?? 'Meal'}: ${m['name'] ?? 'Food Item'} (${m['calories'] ?? 0} kcal)",
          );
        }
      }

      final prompt = """
You are an expert Clinical Medical Scribe and Dietetic Assistant preparing a structured, objective, and professional "Patient Dietary & GI Symptom Summary" consultation note for a licensed Medical Doctor / Gastroenterologist.

PATIENT RECORD:
- Name: $name
- Age: $age | Biological Sex: $gender
- Baseline Dietary Pattern: $dietType
- Known Baseline Conditions: $conditions
- Active Symptom Flare-Up: $symptomSummary
- Identified Trigger Categories: $activeTriggers
- Incident Timestamp/Window: $lastIncident

RECENT FOOD INTAKE LOG (Preceding Flare-Up):
$mealsBuffer

INSTRUCTIONS:
1. Format as an official medical EHR consultation note for a physician with clear capitalized section headers (DO NOT use '#' hashtags, and DO NOT use raw bullet asterisks '***' or '- **'):
   [CHIEF COMPLAINT & SYMPTOM TIMELINE]
   [PATIENT DEMOGRAPHICS & CLINICAL CONTEXT]
   [NUTRITIONAL RECALL & GI TRIGGER CORRELATION]
   [CONSIDERATIONS FOR THE PHYSICIAN]
2. Under each section, write concise, professional clinical sentences or clean bullet points describing the patient's data, logged meals, and potential food triggers (acidic, spicy, dairy, high FODMAP, etc.).
3. Present static facts, findings, and history as clean bullet points (-). NEVER use checklist tick boxes, bracketed boxes, or task boxes like '[ ]', '[x]', or '[X]'.
4. Maintain an objective, professional, and clinical scribe tone (avoid casual conversational chatter or emojis).
5. Do NOT invent fake vitals or lab results. Stick strictly to the patient's data.
6. End with a short standard observational disclaimer.
""";

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a professional clinical scribe formatting patient dietary intake and digestive symptoms for a medical doctor.",
            },
            {
              "role": "user",
              "content": prompt,
            },
          ],
          "max_tokens": 800,
          "temperature": 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"] ??
            "No report generated.";
      } else {
        return "Error from report service: HTTP ${response.statusCode}";
      }
    } catch (e) {
      _serviceLogger.e("Doctor summary generation failed: $e");
      return "Unable to generate doctor report at this time: $e";
    }
  }
}
