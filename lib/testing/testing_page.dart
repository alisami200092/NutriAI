import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestingPage extends StatefulWidget {
  // Inputs from the previous screen
  final int age;
  final double height;
  final double weight;
  final double weightChangePerWeek;
  final String gender;
  final String activityLevel;
  final String goal;
  final String dietType;
  final String healthConditions;
  final String restrictions;

  const TestingPage({
    super.key,
    required this.age,
    required this.height,
    required this.weight,
    required this.weightChangePerWeek,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dietType,
    required this.healthConditions,
    required this.restrictions,
  });

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  // --------------------------------------------------------
  // ✅ NGROK URL (Kept exactly as requested)
  // --------------------------------------------------------
  static const _baseUrl = 'https://rayna-spriggy-scarlett.ngrok-free.dev';

  bool isLoading = true;
  String? errorMessage;

  double predictedCalories = 0.0;
  String planSource = "General"; // To track if it's Indian or General

  // Map to store the meal plan results
  Map<String, String> mealPlan = {
    "Breakfast": "No Breakfast",
    "Lunch": "No Lunch",
    "Dinner": "No Dinner",
    "Snack": "No Snack",
  };

  @override
  void initState() {
    super.initState();
    _generateFullPlan();
  }

  // Helper: Convert string activity to float (Matches Python logic)
  double _getActivityMultiplier(String level) {
    final lower = level.toLowerCase().trim();
    if (lower.contains("sedentary")) return 1.2;
    if (lower.contains("light")) return 1.375;
    if (lower.contains("moderate")) return 1.55;
    if (lower.contains("very active")) return 1.725;
    if (lower.contains("super")) return 1.9;
    return 1.55;
  }

  // Helper: Convert string goal to encoding (Matches Python logic)
  int _getGoalEncoded(String goal) {
    final lower = goal.toLowerCase().trim();
    if (lower.contains("loss")) return -1;
    if (lower.contains("gain")) return 1;
    return 0; // Maintenance
  }

  Future<void> _generateFullPlan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // ====================================================
      // STEP 1: Predict Calories (Hits Model 1 - Hybrid)
      // ====================================================
      final predictPayload = {
        "Age": widget.age,
        "Gender": widget.gender,
        "Height": widget.height,
        "Weight": widget.weight,
        "ActivityMultiplier": _getActivityMultiplier(widget.activityLevel),
        "GoalEncoded": _getGoalEncoded(widget.goal),
        "Weight_Change": widget.weightChangePerWeek,
        "Disease": widget.healthConditions,
        "Severity": widget.restrictions,
      };

      developer.log('Step 1 Request: $predictPayload', name: 'TestingPage');

      final calResponse = await http.post(
        Uri.parse('$_baseUrl/predict_calories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(predictPayload),
      );

      if (calResponse.statusCode != 200) {
        throw Exception('Calorie API Failed: ${calResponse.body}');
      }

      final calData = jsonDecode(calResponse.body);
      if (calData['status'] == 'error') {
        throw Exception(calData['message']);
      }

      final dynamic predictedRaw = calData['predicted_calories'];
      if (predictedRaw == null) throw Exception('No calories returned');

      final double targetCalories = (predictedRaw is num)
          ? predictedRaw.toDouble()
          : double.tryParse(predictedRaw.toString()) ?? 0.0;

      // ====================================================
      // STEP 2: Get Meal Plan (Hits Model 2 - KNN)
      // ====================================================

      // Logic: Route to Pakistani, Indian, or Balanced dataset based on user selection
      final String lowerDiet = widget.dietType.toLowerCase();
      String cuisineChoice = "balanced";
      if (lowerDiet.contains("pakistan")) {
        cuisineChoice = "pakistan";
      } else if (lowerDiet.contains("indian")) {
        cuisineChoice = "indian";
      }

      final recommendPayload = {
        "target_calories": targetCalories,
        "diet_type": widget.dietType,
        "disease": widget.healthConditions,
        "cuisine": cuisineChoice,
      };

      developer.log('Step 2 Request: $recommendPayload', name: 'TestingPage');

      final mealResponse = await http.post(
        Uri.parse('$_baseUrl/recommend_meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(recommendPayload),
      );

      if (mealResponse.statusCode != 200) {
        throw Exception('Meal API Failed: ${mealResponse.body}');
      }

      // Handle Python NaN
      String safeBody = mealResponse.body.replaceAll('NaN', 'null');
      final mealData = jsonDecode(safeBody);

      if (mealData['status'] == 'fail') {
        throw Exception(mealData['message'] ?? 'No plan found');
      }

      final planDetails = Map<String, dynamic>.from(mealData['meal_plan'] as Map);

      // Extract details
      final breakfast = planDetails['Breakfast']?.toString() ?? "No Breakfast";
      final lunch = planDetails['Lunch']?.toString() ?? "No Lunch";
      final dinner = planDetails['Dinner']?.toString() ?? "No Dinner";
      final snack = planDetails['Snack']?.toString() ?? "No Snack";
      final source = planDetails['Source']?.toString() ?? "General";

      setState(() {
        predictedCalories = targetCalories;
        planSource = source;
        mealPlan = {
          "Breakfast": breakfast,
          "Lunch": lunch,
          "Dinner": dinner,
          "Snack": snack,
        };
        isLoading = false;
      });

    } catch (e, stack) {
      developer.log('Error: $e', stackTrace: stack, name: 'TestingPage');
      setState(() {
        errorMessage = e.toString().replaceAll("Exception:", "").trim();
        isLoading = false;
      });
    }
  }

  Widget _buildMealCard(String title, String description, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Meal Plan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              const Text(
                "Oops!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage ?? "Unknown Error",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _generateFullPlan,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calorie Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    "Daily Calorie Target",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${predictedCalories.toInt()} kcal",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Plan Source: $planSource",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Recommended Meals",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMealCard("Breakfast", mealPlan['Breakfast']!, Icons.wb_sunny_outlined),
            _buildMealCard("Lunch", mealPlan['Lunch']!, Icons.restaurant),
            _buildMealCard("Dinner", mealPlan['Dinner']!, Icons.nights_stay_outlined),
            _buildMealCard("Snack", mealPlan['Snack']!, Icons.fastfood_outlined),
          ],
        ),
      ),
    );
  }
}