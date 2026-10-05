import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/me/app_settings.dart';

class SocialNetworksPage extends StatelessWidget {
  const SocialNetworksPage({super.key});

  // Colors extracted from reference
  final Color _appBarGreen = const Color(0xFFBCE3C5); // Soft pastel green
  final Color _buttonGreen = const Color(0xFFA8D5A3); // Button green
  final Color _backgroundColor = const Color(0xFFF5F7FA); // Light grey bg

  Future<void> _launchSocialUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Link copied to clipboard: $url"),
          action: SnackBarAction(
            label: "Share",
            textColor: Colors.amberAccent,
            onPressed: () {
              Share.share("Check out NutriApp: $url");
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Connect with Us".tr(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Top Section (Image + Text)
            Container(
              color: Colors.white, // White background for the header part
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Illustration
                  // Make sure to add this image to your assets
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Image.asset(
                        'assets/images/connect-together.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if image isn't found
                          return const Center(
                            child: Icon(
                              Icons.groups_3,
                              size: 100,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Text Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Text(
                          "Join Our Community!".tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Stay connected, get daily tips, and share your journey with us on social media.".tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Social Media List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildSocialCard(
                    name: "Facebook",
                    logo: _buildFacebookLogo(),
                    btnText: "Follow".tr(),
                    onTap: () => _launchSocialUrl(context, "https://facebook.com"),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialCard(
                    name: "Instagram",
                    logo: _buildInstagramLogo(),
                    btnText: "Follow".tr(),
                    onTap: () => _launchSocialUrl(context, "https://instagram.com"),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialCard(
                    name: "X (formerly Twitter)",
                    logo: _buildXLogo(),
                    btnText: "Follow".tr(),
                    onTap: () => _launchSocialUrl(context, "https://x.com"),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialCard(
                    name: "Reddit",
                    logo: _buildRedditLogo(),
                    btnText: "Join".tr(),
                    onTap: () => _launchSocialUrl(context, "https://reddit.com"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSocialCard({
    required String name,
    required Widget logo,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          SizedBox(width: 50, height: 50, child: logo),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Button
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                btnText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Custom Logos (Built with Flutter Widgets) ---
  // You can replace these with Image.asset('assets/icons/facebook.png') later

  Widget _buildFacebookLogo() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1877F2), // Facebook Blue
      ),
      child: const Center(
        child: Text(
          "f",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,
            fontFamily: 'Roboto', // Default font works well for 'f'
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildXLogo() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
      ),
      child: const Center(
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: 28,
        ), // Using close icon as X approximation
      ),
    );
  }

  Widget _buildRedditLogo() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFF4500), // Reddit Orange
      ),
      child: const Center(
        // Using a generic face icon as a placeholder for the alien
        child: Icon(Icons.face, color: Colors.white, size: 30),
      ),
    );
  }
}
