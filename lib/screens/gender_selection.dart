import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? selectedGender;
  final Logger _logger = Logger(); // Logger instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Lottie Animation
              Lottie.asset(
                "assets/animations/robot-working.json",
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 10),

              // Gender symbol image
              Image.asset(
                "assets/images/gender_symbol.png",
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, size: 80, color: Colors.red);
                },
              ),

              const SizedBox(height: 10),

              const Text(
                "What is your gender?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // Gender selection options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildGenderOption(
                        "Male",
                        "assets/images/male.jpg",
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildGenderOption(
                        "Female",
                        "assets/images/female.jpg",
                        Colors.pink,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "We use your gender to design the best diet plan.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Continue button with navigation
              AnimatedOpacity(
                opacity: selectedGender != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: selectedGender != null
                      ? _continueToNextScreen
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.subdirectory_arrow_right, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Continue",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ],
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

  void _continueToNextScreen() {
    _logger.i("Navigating to Height Page...");
    Navigator.pushNamed(context, "/height", arguments: selectedGender);
  }

  Widget _buildGenderOption(String label, String imagePath, Color borderColor) {
    bool isSelected = selectedGender == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = label;
          _logger.i("$label selected");
        });
      },
      child: Container(
        width: 160,
        height: 260, // Increased height to ensure full image visibility
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: borderColor, width: 4) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: 160,
            height: 260,
            fit: BoxFit
                .contain, // Changed from `cover` to `contain` to show full image
          ),
        ),
      ),
    );
  }
}
