import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/me/app_settings.dart';

class ReferFriendPage extends StatelessWidget {
  const ReferFriendPage({super.key});

  final Color _primaryTeal = const Color(0xFF4DB6AC);
  final Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String referralCode = user != null
        ? "NUTRI-${user.uid.substring(0, math.min(6, user.uid.length)).toUpperCase()}"
        : "HEALTHYPAL2024";

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Refer a Friend".tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppSettingsPage()),
              );
            },
          ),
        ],
      ),
      // "Old Style": SingleScrollView allows scrolling if screen is small,
      // but fits everything naturally on larger screens.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 1. IMAGE SECTION
              // Since the background is white, this image will blend in perfectly.
              SizedBox(
                height: 280, // Good height to show detail but leave room
                width: double.infinity,
                child: Image.asset(
                  'assets/images/refer.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // 2. HEADERS
              Text(
                "Share the Health!".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  "Invite your friends to NutriGuide and you both get special rewards!".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 3. REWARDS BOX (Green)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1), // Light Mint Green
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRewardItem(
                          Icons.star,
                          "You Get:".tr(),
                          "1 Month Premium Access".tr(),
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                        indent: 5,
                        endIndent: 5,
                      ),
                      Expanded(
                        child: _buildRewardItem(
                          Icons.card_giftcard,
                          "Your Friend Gets".tr(),
                          "10% Off First Subscription".tr(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 4. REFERRAL CODE SECTION
              Text(
                "Your Referral Code".tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),

              // Dotted/Bordered Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: Center(
                  child: SelectableText(
                    referralCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Copy Button
              SizedBox(
                width: 160,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: referralCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Code $referralCode copied!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    "Copy Code".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 5. SOCIAL SHARE
              Text(
                "Share Your Code via:".tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialBtn(
                    Icons.chat,
                    const Color(0xFF25D366),
                    onTap: () {
                      Share.share(
                        "Hey! Join me on NutriApp to track nutrition and meals! Use my referral code: $referralCode for exclusive benefits. https://nutriapp.com",
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildSocialBtn(
                    Icons.sms,
                    const Color(0xFFFFA000),
                    onTap: () {
                      Share.share(
                        "Join me on NutriApp! Use code: $referralCode to get rewards. https://nutriapp.com",
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildSocialBtn(
                    Icons.email,
                    const Color(0xFFEF5350),
                    onTap: () {
                      Share.share(
                        "I'm inviting you to NutriApp! Use my referral code: $referralCode to receive special perks. https://nutriapp.com",
                        subject: "NutriApp Invitation",
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildSocialBtn(
                    Icons.share,
                    const Color(0xFF42A5F5),
                    onTap: () {
                      Share.share(
                        "Check out NutriApp! Use code: $referralCode to get 10% off your subscription: https://nutriapp.com",
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 6. HOW IT WORKS
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "How it Works".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildStepRow("1.", "Share your unique code.".tr()),
              _buildStepRow("2.", "Friend signs up using code.".tr()),
              _buildStepRow("3.", "You both get rewards!".tr()),

              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Icon(icon, color: _primaryTeal, size: 28),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, {VoidCallback? onTap}) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: color,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
