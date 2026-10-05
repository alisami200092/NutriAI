import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/authentication/auth_service.dart';
import 'package:nutriapp/dashboard/notification_screen.dart';
import 'package:nutriapp/services/notification_service.dart';
import 'package:nutriapp/me/app_devices.dart';
import 'package:nutriapp/me/app_language_page.dart';
import 'package:nutriapp/me/app_preferences_page.dart';
import 'package:nutriapp/me/app_settings.dart';
import 'package:nutriapp/me/health_catalog.dart';
import 'package:nutriapp/me/overview_plan.dart';
import 'package:nutriapp/me/personal_info.dart';
import 'package:nutriapp/me/professional_connect.dart';
import 'package:nutriapp/me/progress_photos.dart';
import 'package:nutriapp/me/refer_friend_page.dart';
import 'package:nutriapp/me/social_networks_page.dart';
import 'package:nutriapp/me/support_faq_page.dart';
import 'package:nutriapp/meal_log/all-meals-sections/full_day_food_report.dart';
import 'package:nutriapp/meal_log/full_camera_screen.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/services/meal_database_seeder.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';

class MePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const MePage({super.key, required this.cameras, required this.yolo});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final Color _primaryColor = const Color(0xFF37C97D);

  String _userName = "User";
  String _userInitials = "U";
  String _memberStatus = "Member";
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('UserProfiles')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] as String?)?.trim() ?? user.displayName ?? "User";

          String initials = "U";
          final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
          if (parts.length >= 2) {
            initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
          } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
            initials = parts[0][0].toUpperCase();
          }

          final bool isPremium = data['isPremium'] == true || data['subscription'] != null;

          setState(() {
            _userName = name;
            _userInitials = initials;
            _memberStatus = isPremium ? "Premium Member" : "Free Member";
            _photoUrl = data['photoUrl'] ?? user.photoURL;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching me page profile: $e");
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seedMealsToDatabase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Color(0xFF37C97D)),
            SizedBox(width: 10),
            Text(
              "Seeding Meals DB",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF37C97D)),
            const SizedBox(height: 16),
            Text(
              "Uploading ${MealDatabaseSeeder.foodCatalog.length} curated dataset foods to Firestore 'meals' collection...",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );

    try {
      final totalAdded = await MealDatabaseSeeder.seedFoodsDatabase();
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Successfully uploaded $totalAdded foods to 'meals' collection!",
            ),
            backgroundColor: const Color(0xFF00C853),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error uploading foods: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onLogFoodButtonPressed() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Food Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF37C97D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload, color: Color(0xFF37C97D)),
                ),
                title: const Text(
                  "Seed All Foods to Firebase DB",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Uploads all ${MealDatabaseSeeder.foodCatalog.length} curated dataset foods into the 'meals' Firestore collection.",
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _seedMealsToDatabase();
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text(
                  "Scan / Log Food via Camera",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Open AI camera scanner to detect and log food.",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullCameraViewMin(
                        cameras: widget.cameras,
                        yolo: widget.yolo,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text("Sign Out".tr()),
          content: Text("Are you sure you want to sign out?".tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("Cancel".tr(), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                AuthService().signOut(
                  context,
                  cameras: widget.cameras,
                  yolo: widget.yolo,
                );
              },
              child: Text(
                "Sign Out".tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Me'.tr(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: AnimatedBuilder(
                animation: NotificationService.instance,
                builder: (context, _) {
                  final unread = NotificationService.instance.unreadCount;
                  return Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationScreen(
                              cameras: widget.cameras,
                              yolo: widget.yolo,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onLogFoodButtonPressed,
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Log Food".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Header (Dynamic)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalInfoPage(),
                  ),
                );
                _fetchUserData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                color: Colors.transparent,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _primaryColor.withValues(alpha: 0.15),
                      backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                          ? NetworkImage(_photoUrl!)
                          : null,
                      child: _photoUrl == null || _photoUrl!.isEmpty
                          ? Text(
                              _userInitials,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoading ? "Loading...".tr() : "Hello, $_userName!",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                size: 16,
                                color: _memberStatus.contains("Premium")
                                    ? Colors.amber.shade600
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _memberStatus.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _memberStatus.contains("Premium")
                                      ? Colors.amber.shade700
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 2. Premium Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4DB6AC), // Teal
                    Color(0xFFFFCC80), // Peach/Orange
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Unlock Your Journey's Full Potential".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      "Explore Premium".tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Section: My Profile & Goals
            _buildSectionTitle("My Profile & Goals".tr()),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.monitor_weight_outlined,
                    title: "My Weight Goal & Plan".tr(),
                    subtitle: "Overview of your custom nutrition plan".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPlanPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.favorite_border,
                    title: "Personal Info".tr(),
                    subtitle: "Age, Gender, Height, Weight & Goals".tr(),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInfoPage(),
                        ),
                      );
                      _fetchUserData();
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.health_and_safety_outlined,
                    title: "Health Catalog".tr(),
                    subtitle: "Track vitals, measurements & devices".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HealthCatalogPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 4. Section: Food & Recipes
            _buildSectionTitle("Food & Recipes".tr()),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.restaurant_menu,
                    title: "Premium Recipes & Meals".tr(),
                    subtitle: "Personalized AI recipes and meal plans".tr(),
                    isPremium: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 5. Section: Reports & Analytics
            _buildSectionTitle("Reports & Analytics".tr()),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.photo_camera_back_outlined,
                    title: "Progress Photos".tr(),
                    subtitle: "Visually track your transformation".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressPhotosPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.analytics_outlined,
                    title: "Food Analysis".tr(),
                    subtitle: "Full day nutritional insights & reports".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DayFoodReportPage(
                            selectedDate: DateTime.now(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 6. Section: General
            _buildSectionTitle("General".tr()),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.watch,
                    title: "Apps & Devices".tr(),
                    subtitle: "Connect with trackers & smart devices".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppsAndDevicesPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.tune_outlined,
                    title: "App Preferences".tr(),
                    subtitle: "Units, notifications & customization".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppPreferencesPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.language_outlined,
                    title: "App Language".tr(),
                    subtitle: "Choose your language".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppLanguagePage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.settings_outlined,
                    title: "App Settings".tr(),
                    subtitle: "Notifications, privacy & security".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 7. Section: Community & Support
            _buildSectionTitle("Community & Support".tr()),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.medical_services_outlined,
                    title: "Professional Connect".tr(),
                    subtitle: "Dietitian & Nutritionist consults".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfessionalConnectPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.people_outline,
                    title: "Refer Friends".tr(),
                    subtitle: "Invite friends and earn rewards".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReferFriendPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.thumb_up_alt_outlined,
                    title: "NutriAI Social Networks".tr(),
                    subtitle: "Join our active community".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SocialNetworksPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.help_outline,
                    title: "Support & FAQs".tr(),
                    subtitle: "Frequently asked questions & help".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportCenterPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 8. Sign Out Button
            Container(
              width: double.infinity,
              decoration: _cardDecoration(),
              child: ListTile(
                onTap: () => _handleSignOut(context),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout, color: Colors.red.shade400),
                ),
                title: Text(
                  "Sign Out".tr(),
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.05),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPremium = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black54),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPremium)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Premium",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
