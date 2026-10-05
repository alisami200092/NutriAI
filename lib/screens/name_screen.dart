import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'final_summary_page.dart';

class NameScreen extends StatefulWidget {
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
  final String healthConditions;

  const NameScreen({
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
    required this.healthConditions,
  });

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _errorText;

  void _navigateToSummary() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = "Please enter your name.";
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalSummaryPage(
            name: name,
            age: widget.age,
            heightCm: widget.heightCm, // ← now passed
            gender: widget.gender, // ← now passed
            weight: widget.weightKg,
            targetWeight: widget.targetWeight,
            dietaryGoal: widget.dietaryGoal,
            eventName: widget.eventName,
            eventDate: widget.eventDate,
            activityLevel: widget.activityLevel,
            weightChangePerWeek: widget.weightChangePerWeek,
            restrictions: widget.restrictions,
            dietType: widget.dietType,
            healthConditions: widget.healthConditions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Lottie.asset(
                    "assets/animations/robot-working.json",
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 12),
                  Image.asset(
                    "assets/images/name_symbol.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "What is your name?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Enter your name here",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      errorText: _errorText,
                    ),
                    style: const TextStyle(fontSize: 18),
                    cursorColor: Colors.green,
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: MediaQuery.of(context).size.width * 0.8,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _navigateToSummary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Finish",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
