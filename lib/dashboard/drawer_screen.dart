import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/me/app_devices.dart';
import 'package:nutriapp/me/app_language_page.dart';
import 'package:nutriapp/me/app_preferences_page.dart';
import 'package:nutriapp/me/app_settings.dart';
import 'package:nutriapp/me/overview_plan.dart';
import 'package:nutriapp/me/personal_info.dart';
import 'package:nutriapp/me/progress_photos.dart';
import 'package:nutriapp/me/refer_friend_page.dart';
import 'package:nutriapp/me/support_faq_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. Header with live user data
          StreamBuilder<DocumentSnapshot>(
            stream: uid.isNotEmpty
                ? FirebaseFirestore.instance.collection('UserProfiles').doc(uid).snapshots()
                : null,
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final String name = data?['name'] ?? user?.displayName ?? "User";
              final String email = user?.email ?? data?['email'] ?? "user@nutriai.com";
              final String? photoUrl = data?['photoUrl'] ?? user?.photoURL;
              final String diet = data?['dietPreference'] ?? data?['dietType'] ?? "Balanced";

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.eco, color: Color(0xFF09B84F), size: 28),
                        SizedBox(width: 8),
                        Text(
                          "NutriAI",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09B84F),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF09B84F),
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.asset(
                                'assets/images/robot-working.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Email
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Active Diet Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09B84F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$diet ${'Diet'.tr()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  text: "Dashboard".tr(),
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  text: "My Profile".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.restaurant_menu_outlined,
                  text: "Meal Plan & Macros".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPlanPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.photo_library_outlined,
                  text: "Progress Photos".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressPhotosPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.watch_outlined,
                  text: "Apps & Devices".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppsAndDevicesPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.card_giftcard_outlined,
                  text: "Invite Friends".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReferFriendPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  text: "Help & Support".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportCenterPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.tune_outlined,
                  text: "Preferences".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppPreferencesPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.language_outlined,
                  text: "Language".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppLanguagePage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  text: "All Settings".tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppSettingsPage()),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  text: "Log Out".tr(),
                  color: Colors.red,
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "NutriAI v1.0.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Sign Out".tr()),
        content: Text("Are you sure you want to sign out?".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel".tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close drawer
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
              }
            },
            child: Text("Log Out".tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      dense: true,
    );
  }
}

