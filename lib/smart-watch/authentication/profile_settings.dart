import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut() async {
    // This triggers the StreamBuilder in watch_app.dart
    // effectively redirecting the user back to Login automatically.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user to display email
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. User Avatar / Icon
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.cyanAccent,
                child: Icon(Icons.person, color: Colors.black, size: 24),
              ),
              const SizedBox(height: 8),

              // 2. User Email (Truncated if too long)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  user?.email ?? "User",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 15),

              // 3. The Rectangular Sign Out Button
              GestureDetector(
                onTap: _signOut,
                child: Container(
                  width: 140, // Fixed width for nice rectangle look
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900], // Dark background
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Rectangular with slight curve
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ), // Subtle red border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      // Prefix Icon
                      Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      // Text
                      Text(
                        "Sign Out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
