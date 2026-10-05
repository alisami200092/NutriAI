import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'name_screen.dart';

class HealthConditionsPage extends StatefulWidget {
  final int age;
  final double heightCm;
  final String gender;
  final double weightKg;
  final double targetWeight;
  final String dietaryGoal;
  final String eventName;
  final DateTime eventDate;
  final String activityLevel;
  final double weightChangePerWeek;
  final String restrictions;
  final String dietType;

  const HealthConditionsPage({
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
    required this.dietType,
  });

  @override
  State<HealthConditionsPage> createState() => _HealthConditionsPageState();
}

class _HealthConditionsPageState extends State<HealthConditionsPage> {
  List<String> selectedConditions = [];
  String otherConditionText = '';

  // ✅ UPDATED LIST: Matches Python Backend capabilities
  // ❌ EXCLUDED: "Obesity" (User must type this in "Other" if needed)
  final List<Map<String, String>> conditionOptions = [
    {'emoji': '✅', 'label': 'None'},
    {'emoji': '❤️', 'label': 'Hypertension'},
    {'emoji': '🍬', 'label': 'Diabetes'},
    {'emoji': '🫀', 'label': 'Heart Disease'},
    {'emoji': '🩺', 'label': 'Kidney Disease'},
    {'emoji': '🧠', 'label': 'Bipolar'},
    {'emoji': '💧', 'label': 'Acne'},
    {'emoji': '❓', 'label': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    // Logic to compile the final string for the API
    final resolvedString = selectedConditions
        .map((label) {
      if (label == 'Other') {
        // If "Other" is selected, send the typed text
        return otherConditionText.trim().isNotEmpty
            ? otherConditionText.trim()
            : 'Other';
      }
      return label;
    })
        .join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) => SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- Header Animations ---
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        Lottie.asset(
                          "assets/animations/robot-working.json",
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 10),
                        Image.asset(
                          "assets/images/heart-beat.png",
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                          const Icon(Icons.favorite, size: 60, color: Colors.red),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Do you have any health conditions?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                          child: Text(
                            "This helps our AI adjust your calories and nutrients for safety.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),

                    // --- Condition Selection List ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: conditionOptions.map((cond) {
                          final label = cond['label']!;
                          final isSelected = selectedConditions.contains(label);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (label == 'None') {
                                  // If None clicked, clear others
                                  selectedConditions = ['None'];
                                  otherConditionText = '';
                                } else {
                                  // If other items clicked, remove 'None'
                                  selectedConditions.remove('None');
                                  if (isSelected) {
                                    selectedConditions.remove(label);
                                  } else {
                                    selectedConditions.add(label);
                                  }
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    cond['emoji']!,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // --- "Other" Text Input (Only shows if "Other" is selected) ---
                    if (selectedConditions.contains('Other')) ...{
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: TextField(
                          onChanged: (v) =>
                              setState(() => otherConditionText = v),
                          decoration: InputDecoration(
                            hintText: "e.g., Obesity, PCOS, Thyroid...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    },

                    const SizedBox(height: 20),

                    // --- Continue Button ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton(
                        onPressed: () {
                          // Validation: Ensure something is selected
                          if (selectedConditions.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select an option or 'None'")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NameScreen(
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
                                dietType: widget.dietType,
                                // Pass the processed string to the next screen
                                healthConditions: resolvedString,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(280, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}