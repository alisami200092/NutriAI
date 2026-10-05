import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/authentication/login_page.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signOut(
    BuildContext context, {
    required List<CameraDescription> cameras,
    required YoloService yolo,
  }) async {
    try {
      // 1. Sign out from Firebase
      await _auth.signOut();

      // 2. Clear Local Data (Crucial for your logic)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // This wipes 'profileCompleted', ensuring the user doesn't skip login next time.

      // 3. Navigate back to Login Page
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginPage(cameras: cameras, yolo: yolo),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error signing out: $e")));
      }
    }
  }
}
