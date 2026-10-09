import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nutriapp/screens/health_conditions.dart';

class DietPreferencePage extends StatefulWidget {
  final int age;
  final double heightCm; // ← NEW
  final String gender; // ← NEW
  final double weightKg;
  final double targetWeight;
  final String dietaryGoal;
  final String eventName;
  final DateTime eventDate;
  final String activityLevel;
  final double weightChangePerWeek;
  final String restrictions;

  const DietPreferencePage({
    super.key,
    required this.age,
    required this.heightCm, 
    required this.gender,
    required this.weightKg,
    required this.targetWeight,
    required this.dietaryGoal,
    required this.eventName,
    required this.eventDate,
    required this.activityLevel,
    required this.weightChangePerWeek,
    required this.restrictions,
  });

  @override
  State<DietPreferencePage> createState() => _DietPreferencePageState();
}

class _DietPreferencePageState extends State<DietPreferencePage> {
  List<String> selectedDiets = [];

  final List<Map<String, String>> dietOptions = [
    {'emoji': '🇵🇰', 'label': 'Pakistani'},
    {'emoji': '🍛', 'label': 'Indian'},
    {'emoji': '⚖️', 'label': 'Balanced'},
    {'emoji': '🏺', 'label': 'Mediterranean'},
    {'emoji': '🥑', 'label': 'Keto'},
    {'emoji': '🥗', 'label': 'Dash'},
    {'emoji': '🍞🚫', 'label': 'Low Carb'},
    {'emoji': '💪', 'label': 'High Protein'},
    {'emoji': '🥓🚫', 'label': 'Low Fat'},
  ];

  void toggleDiet(String label) {
    setState(() {
      if (selectedDiets.contains(label)) {
        selectedDiets.remove(label);
      } else {
        selectedDiets.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/animations/robot-working.json",
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              Image.asset(
                "assets/images/diet-preference.png",
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.restaurant_menu, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                "What kind of diet do you prefer?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Column(
                children: dietOptions.map((diet) {
                  final label = diet['label']!;
                  final isSelected = selectedDiets.contains(label);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: GestureDetector(
                      onTap: () => toggleDiet(label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                            right: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              diet['emoji']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.info_outline, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: selectedDiets.isNotEmpty
                    ? () {
                        final dietTypeString = selectedDiets.join(", ");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HealthConditionsPage(
                              age: widget.age,
                              heightCm: widget.heightCm,
                              gender: widget.gender,
                              weightKg: widget.weightKg,
                              targetWeight: widget.targetWeight,
                              dietaryGoal: widget.dietaryGoal,
                              eventName: widget.eventName,
                              eventDate: widget.eventDate,
                              activityLevel: widget.activityLevel,
                              weightChangePerWeek: widget.weightChangePerWeek,
                              restrictions: widget.restrictions,
                              dietType: dietTypeString,
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
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
