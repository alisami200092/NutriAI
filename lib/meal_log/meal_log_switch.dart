import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/meal_log/view_all_meals.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';

class MealLogSwitchPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;
  const MealLogSwitchPage({
    super.key,
    required this.cameras,
    required this.yolo,
    required DateTime selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 40),
              const Icon(Icons.restaurant, size: 40, color: Colors.black87),
              const SizedBox(height: 24),
              const Text(
                "Log Your Meal",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF153D27),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose how you want to record your meal.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              // 📝 Manual Meal Log Button
              _gradientButton(
                context,
                label: "Manual Meal Log",
                description: "Enter details yourself",
                icon: Icons.assignment_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF37C97D), Color(0xFF4AC0B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllMealsPage(
                        initialDate: DateTime.now(),
                        cameras: cameras,
                        yolo: yolo,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 📷 Camera Meal Log Button
              _gradientButton(
                context,
                label: "Camera Meal Log",
                description: "Snap a photo",
                icon: Icons.camera_alt_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFF6F91)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/camera");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientButton(
    BuildContext context, {
    required String label,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 55, color: Colors.white), // 🔧 Bigger icon
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20, // 🔧 Bigger title inside button
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16, // 🔧 Bigger subtitle inside button
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
