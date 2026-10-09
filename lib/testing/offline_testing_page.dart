import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutriapp/dashboard/bottom_nav.dart';
import 'package:nutriapp/testing/calories_service.dart';
import 'package:nutriapp/testing/meal_service.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';

class OfflineTestingPage extends StatefulWidget {
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

  const OfflineTestingPage({
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
  State<OfflineTestingPage> createState() => _OfflineTestingPageState();
}

class _OfflineTestingPageState extends State<OfflineTestingPage> {
  final CalorieService _calorieService = CalorieService();
  final MealService _mealService = MealService();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  double predictedCalories = 0.0;
  String planSource = "General";

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

  // ✅ SAVE DATA TO FIRESTORE
  Future<void> _saveAndNavigate() async {
    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in");

      // 1. Prepare Data
      final Map<String, dynamic> aiData = {
        "dailyCalorieTarget": predictedCalories, // Save the number
        "generatedMealPlan": mealPlan, // Save the menu
        "generatedMealPlanCuisine": widget.dietType, // Keep in sync with DashboardScreen
        "planSource": planSource,
        "lastPlanGeneratedAt": FieldValue.serverTimestamp(),
      };

      // 2. Write to Firestore (Merge with existing profile)
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .set(aiData, SetOptions(merge: true));

      developer.log("✅ Data saved to Firestore", name: "OfflinePage");

      if (!mounted) return;

      // 3. Navigate to Dashboard (via BottomNav)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          // ✅ CORRECT: Navigate to BottomNav, not Dashboard directly
          builder: (context) => BottomNav(
            cameras: const [], // Empty list is fine
            yolo: YoloService(), // Pass a fresh instance
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      developer.log("❌ Error saving: $e", name: "OfflinePage");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _generateFullPlan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Step 1: Calories
      final double targetCalories = await _calorieService.predictCalories(
        age: widget.age,
        gender: widget.gender,
        height: widget.height,
        weight: widget.weight,
        activityLevel: widget.activityLevel,
        goal: widget.goal,
        weightChangePerWeek: widget.weightChangePerWeek,
        disease: widget.healthConditions,
      );

      // Step 2: Meals
      String lowerDiet = widget.dietType.toLowerCase();
      String cuisineChoice = "balanced";
      if (lowerDiet.contains("keto")) {
        cuisineChoice = "keto";
      } else if (lowerDiet.contains("mediterranean")) {
        cuisineChoice = "mediterranean";
      } else if (lowerDiet.contains("dash")) {
        cuisineChoice = "dash";
      } else if (lowerDiet.contains("pakistan")) {
        cuisineChoice = "pakistan";
      } else if (lowerDiet.contains("indian")) {
        cuisineChoice = "indian";
      }

      String combinedRestrictions =
          "${widget.restrictions}, ${widget.healthConditions}";

      final Map<String, String> planResult = await _mealService.recommendMeal(
        targetCalories: targetCalories,
        cuisine: cuisineChoice,
        dietType: widget.dietType,
        restriction: combinedRestrictions,
      );

      setState(() {
        predictedCalories = targetCalories;
        planSource = planResult['Source'] ?? "Offline Database";
        mealPlan = {
          "Breakfast": planResult['Breakfast'] ?? "No Breakfast",
          "Lunch": planResult['Lunch'] ?? "No Lunch",
          "Dinner": planResult['Dinner'] ?? "No Dinner",
          "Snack": planResult['Snack'] ?? "No Snack",
        };
        isLoading = false;
      });
    } catch (e, stack) {
      developer.log('Error: $e', stackTrace: stack, name: 'OfflinePage');
      setState(() {
        errorMessage = "Offline Error: $e";
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
        title: const Text('Your AI Plan'),
        backgroundColor: Colors.blueAccent,
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(errorMessage ?? "Unknown Error"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _generateFullPlan,
                      child: const Text("Retry"),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Daily Calorie Target",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${predictedCalories.toInt()} kcal",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Source: 100% Offline AI",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMealCard(
                    "Breakfast",
                    mealPlan['Breakfast']!,
                    Icons.wb_sunny_outlined,
                  ),
                  _buildMealCard("Lunch", mealPlan['Lunch']!, Icons.restaurant),
                  _buildMealCard(
                    "Dinner",
                    mealPlan['Dinner']!,
                    Icons.nights_stay_outlined,
                  ),
                  _buildMealCard(
                    "Snack",
                    mealPlan['Snack']!,
                    Icons.fastfood_outlined,
                  ),

                  const SizedBox(height: 30),

                  // ✅ SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveAndNavigate,
                      icon: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 28),
                      label: Text(
                        isSaving
                            ? "Saving..."
                            : "Accept Plan & Go to Dashboard",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
