import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer';

// ✅ Import Target Weight Page
import 'package:nutriapp/screens/target_weight.dart';

class DietaryGoalsPage extends StatefulWidget {
  final int age;
  final String gender;
  final double heightCm;
  final double currentWeight;

  const DietaryGoalsPage({
    super.key,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.currentWeight,
  });

  @override
  State<DietaryGoalsPage> createState() => _DietaryGoalsPageState();
}

class _DietaryGoalsPageState extends State<DietaryGoalsPage> {
  String selectedGoal = "";

  // --- BMI Calculation Helper ---
  double get _bmi {
    if (widget.heightCm <= 0) return 0.0;
    double heightM = widget.heightCm / 100;
    return widget.currentWeight / (heightM * heightM);
  }

  // --- Recommendation Logic ---
  Map<String, dynamic> get _recommendation {
    double bmi = _bmi;
    if (bmi < 18.5) {
      return {
        "status": "Underweight",
        "recGoal": "Weight Gain",
        "color": Colors.orange,
        "icon": Icons.warning_amber_rounded,
        "message":
            "Your BMI is ${bmi.toStringAsFixed(1)} (Underweight).\nWe recommend focusing on Weight Gain.",
      };
    } else if (bmi >= 18.5 && bmi < 25) {
      return {
        "status": "Normal",
        "recGoal": "Weight Maintain",
        "color": Colors.green,
        "icon": Icons.check_circle_outline,
        "message":
            "Your BMI is ${bmi.toStringAsFixed(1)} (Healthy).\nGreat job! We recommend Weight Maintenance.",
      };
    } else {
      // Overweight (25-30) or Obese (>30)
      return {
        "status": "Overweight",
        "recGoal": "Weight Loss",
        "color": Colors.redAccent,
        "icon": Icons.health_and_safety_outlined,
        "message":
            "Your BMI is ${bmi.toStringAsFixed(1)} (${bmi >= 30 ? 'Obese' : 'Overweight'}).\nWe recommend a Weight Loss plan for better health.",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Lottie.asset(
                "assets/animations/robot-working.json",
                width: 140,
                height: 140,
              ),

              const SizedBox(height: 10),

              Image.asset(
                "assets/images/goals.png",
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.error, size: 80, color: Colors.red),
              ),

              const SizedBox(height: 8),

              const Text(
                "What are your dietary goals?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // --- RECOMMENDATION BANNER ---
              Container(
                width: 350,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (recommendation['color'] as Color).withValues(
                    alpha: 0.1,
                  ),
                  border: Border.all(
                    color: recommendation['color'],
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      recommendation['icon'],
                      color: recommendation['color'],
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _goalOption("Weight Loss", "⚖️"),
              // Renamed from Improved Health to Weight Maintain
              _goalOption("Weight Maintain", "🌿"),
              _goalOption("Weight Gain", "💪"),

              const SizedBox(height: 40),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton.icon(
                  onPressed: selectedGoal.isNotEmpty
                      ? () {
                          log("Selected Goal: $selectedGoal");

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TargetWeightPage(
                                dietaryGoal: selectedGoal,
                                currentWeight: widget.currentWeight,
                                heightCm: widget.heightCm,
                                age: widget.age,
                                gender: widget.gender,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGoal.isNotEmpty
                        ? Colors.green
                        : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalOption(String goal, String emoji) {
    bool isSelected = selectedGoal == goal;

    // Check if this is the recommended option to add a subtle "Recommended" tag or highlight
    // (Optional visual cue)
    bool isRecommended = _recommendation['recGoal'] == goal;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = goal;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 350,
            padding: const EdgeInsets.symmetric(vertical: 15),
            margin: const EdgeInsets.symmetric(
              vertical: 6,
            ), // slightly more spacing
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey[300],
              border: Border.all(
                color: isSelected
                    ? Colors.green
                    : (isRecommended
                          ? Colors.orangeAccent.withValues(alpha: 0.5)
                          : Colors.transparent),
                width: isSelected ? 2 : (isRecommended ? 1.5 : 0),
              ),
            ),
            child: Center(
              child: Text(
                "$emoji $goal",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green[800] : Colors.black,
                ),
              ),
            ),
          ),

          // Optional: Tiny "Recommended" badge for the suggested goal
          if (isRecommended)
            Positioned(
              right: 10,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Recommended",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
