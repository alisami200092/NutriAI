import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'weight_goal_tracker.dart';

class ActivityLevelPage extends StatefulWidget {
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender;
  final double targetWeight;
  final String dietaryGoal;
  final String eventName;
  final DateTime eventDate;

  const ActivityLevelPage({
    super.key,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.targetWeight,
    required this.dietaryGoal,
    required this.eventName,
    required this.eventDate,
  });

  @override
  State<ActivityLevelPage> createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  String? selectedActivityLabel;

  final List<Map<String, dynamic>> activityLevels = [
    {
      'emoji': '🛋️',
      'label': 'Sedentary',
      'description': 'Little to no exercise',
      'multiplier': 1.2,
    },
    {
      'emoji': '🚶‍♂️',
      'label': 'Lightly Active',
      'description': 'Light exercise 1–3 days/week',
      'multiplier': 1.375,
    },
    {
      'emoji': '🏃‍♀️',
      'label': 'Moderately Active',
      'description': 'Moderate exercise 3–5 days/week',
      'multiplier': 1.55,
    },
    {
      'emoji': '🔥',
      'label': 'Very Active',
      'description': 'Hard training 6–7 days/week',
      'multiplier': 1.725,
    },
  ];

  double get bmr {
    return widget.gender == 'male'
        ? (10 * widget.weightKg) +
              (6.25 * widget.heightCm) -
              (5 * widget.age) +
              5
        : (10 * widget.weightKg) +
              (6.25 * widget.heightCm) -
              (5 * widget.age) -
              161;
  }

  double get selectedMultiplier {
    return activityLevels.firstWhere(
      (level) => level['label'] == selectedActivityLabel,
      orElse: () => {'multiplier': 1.0},
    )['multiplier'];
  }

  double get tdee => bmr * selectedMultiplier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenHeight = constraints.maxHeight;
            double screenWidth = constraints.maxWidth;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
              ), // ✅ Adds spacing from screen edges
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // 🎭 Robot Animation (Smaller)
                  Lottie.asset(
                    "assets/animations/robot-working.json",
                    width: screenHeight * 0.15,
                    height: screenHeight * 0.15,
                  ),

                  SizedBox(height: screenHeight * 0.02),
                  Image.asset(
                    "assets/images/activity_level_symbol.png",
                    width: screenHeight * 0.1,
                    height: screenHeight * 0.1,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.fitness_center, size: 60),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 🎯 Title
                  Text(
                    "How active are you on a daily basis?",
                    style: TextStyle(
                      fontSize: screenHeight * 0.025,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // 🔢 BMR & TDEE Stats (Wrapped in a Container for Proper Padding)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                    ), // ✅ Prevents sticking to edges
                    child: Column(
                      children: [
                        _buildStatRow("BMR", "${bmr.toStringAsFixed(0)} kcal"),
                        _buildStatRow(
                          "Activity Multiplier",
                          "× ${selectedMultiplier.toStringAsFixed(3)}",
                        ),
                        _buildStatRow(
                          "TDEE",
                          "${tdee.toStringAsFixed(0)} kcal",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 📍 Activity Level Options (Adding Margin From Edges)
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics:
                          NeverScrollableScrollPhysics(), // Disable scrolling
                      itemCount: activityLevels.length,
                      itemBuilder: (context, index) {
                        final activity = activityLevels[index];
                        final isSelected =
                            selectedActivityLabel == activity['label'];

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: screenWidth * 0.02,
                          ), // ✅ Adds spacing
                          child: GestureDetector(
                            onTap: () => setState(
                              () => selectedActivityLabel = activity['label'],
                            ),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    activity['emoji'],
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity['label'],
                                          style: TextStyle(
                                            fontSize: screenHeight * 0.02,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.green
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          activity['description'],
                                          style: TextStyle(
                                            fontSize: screenHeight * 0.015,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.info_outline, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // ✅ Continue Button (Moved Upwards)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.02,
                    ), // ✅ Moves button up slightly
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selectedActivityLabel != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WeightGoalTracker(
                                      currentWeight: widget.weightKg,
                                      targetWeight: widget.targetWeight,
                                      dietaryGoal: widget.dietaryGoal,
                                      heightCm: widget.heightCm,
                                      age: widget.age,
                                      gender: widget.gender,
                                      eventName: widget.eventName,
                                      eventDate: widget.eventDate,
                                      activityLevel: selectedActivityLabel!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        label: Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: screenHeight * 0.022,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4), // ✅ Adds spacing between rows
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.info_outline, size: 16, color: Colors.black),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
