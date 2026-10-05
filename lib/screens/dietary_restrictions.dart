import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nutriapp/screens/diet_preference.dart';

class DietaryRestrictionsPage extends StatefulWidget {
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

  const DietaryRestrictionsPage({
    super.key,
    required this.age,
    required this.heightCm, // ← NEW
    required this.gender, // ← NEW
    required this.weightKg,
    required this.targetWeight,
    required this.dietaryGoal,
    required this.eventName,
    required this.eventDate,
    required this.activityLevel,
    required this.weightChangePerWeek,
  });

  @override
  State<DietaryRestrictionsPage> createState() =>
      _DietaryRestrictionsPageState();
}

class _DietaryRestrictionsPageState extends State<DietaryRestrictionsPage> {
  List<String> selectedRestrictions = [];

  final List<Map<String, String>> restrictionOptions = [
    {'emoji': '❌', 'label': 'None'},
    {'emoji': '🥦', 'label': 'Vegetarian'},
    {'emoji': '🌱', 'label': 'Vegan'},
    {'emoji': '🌾', 'label': 'Low Sodium'},
    {'emoji': '🥛🚫', 'label': 'Low Sugar'},
    {'emoji': '🍖', 'label': 'Omnivore'},
    {'emoji': '🥜⚠', 'label': 'Nut Allergy'},
  ];

  void toggleRestriction(String label) {
    setState(() {
      if (label == 'None') {
        selectedRestrictions = ['None'];
      } else {
        selectedRestrictions.remove('None');
        if (selectedRestrictions.contains(label)) {
          selectedRestrictions.remove(label);
        } else {
          selectedRestrictions.add(label);
        }
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
                "assets/images/dietary_restrictions.png",
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.fastfood, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                "Do you have any dietary restrictions, allergies, or foods you dislike?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Column(
                children: restrictionOptions.map((restriction) {
                  final label = restriction['label']!;
                  final isSelected = selectedRestrictions.contains(label);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: GestureDetector(
                      onTap: () => toggleRestriction(label),
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
                              restriction['emoji']!,
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
                onPressed: selectedRestrictions.isNotEmpty
                    ? () {
                        final restrictionString = selectedRestrictions.join(
                          ", ",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DietPreferencePage(
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
                              restrictions: restrictionString,
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
