import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer';
import 'package:nutriapp/screens/weight.dart';

class AgeSelectionPage extends StatefulWidget {
  final String selectedGender;
  final double heightCm;

  const AgeSelectionPage({
    super.key,
    required this.selectedGender,
    required this.heightCm,
  });

  @override
  State<AgeSelectionPage> createState() => _AgeSelectionPageState();
}

class _AgeSelectionPageState extends State<AgeSelectionPage> {
  int selectedAge = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Lottie Animation (Top)
            Lottie.asset(
              "assets/animations/robot-working.json",
              width: 150,
              height: 150,
            ),

            const SizedBox(height: 5),

            // Cake/Age Symbol Image (Below Lottie)
            Image.asset(
              "assets/images/age.png",
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.error, size: 80, color: Colors.red),
            ),

            const SizedBox(height: 2),

            // Question Text ("What is your age?")
            const Text(
              "What is your age?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40), // Adjust gap before wheel picker
            // Scrollable Age Picker (ListWheelScrollView)
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: FixedExtentScrollController(
                  initialItem: selectedAge - 1,
                ),
                itemExtent: 50,
                diameterRatio:
                    1.2, // ✅ This reduces visible numbers from 7 to 5
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedAge = index + 1;
                    log("Selected Age: $selectedAge"); // ✅ Logging selection
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    return Center(
                      child: Container(
                        width: 120,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: selectedAge == index + 1
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: selectedAge == index + 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedAge == index + 1
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 100,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Continue Button (Bottom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeightPage(
                        selectedAge: selectedAge,
                        heightCm: widget.heightCm,
                        selectedGender: widget.selectedGender,
                        // Passing empty string because we haven't asked for Goal yet.
                        // Ideally, you should remove 'required this.dietaryGoal' from WeightPage
                        // if you plan to ask for the Goal AFTER the weight screen.
                        dietaryGoal: "",
                      ),
                    ),
                  );
                  log(
                    "User confirmed selection: Age $selectedAge",
                  ); // ✅ Logging button press
                },
                icon: const Icon(
                  Icons.subdirectory_arrow_right,
                  color: Colors.white,
                ),
                label: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
