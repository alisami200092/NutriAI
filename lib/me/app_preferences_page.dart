import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/services/notification_service.dart';

class AppPreferencesPage extends StatefulWidget {
  const AppPreferencesPage({super.key});

  @override
  State<AppPreferencesPage> createState() => _AppPreferencesPageState();
}

class _AppPreferencesPageState extends State<AppPreferencesPage> {
  final Color _primaryColor = const Color(0xFF09B84F);
  final Color _tealColor = const Color(0xFF4DB6AC);

  bool _isLoading = true;

  // 1. Units
  String _weightUnit = "kg"; // kg, lbs
  String _heightUnit = "cm"; // cm, ft/in
  String _energyUnit = "kcal"; // kcal, kJ
  String _waterUnit = "ml"; // ml, fl oz

  // 2. Smart AI & Automation
  bool _aiMealAutopilot = true;
  bool _aiHealthySwaps = true;
  bool _smartFoodScanner = true;
  bool _calorieAlerts = true;

  // 3. Reminders
  bool _breakfastReminder = true;
  String _breakfastTime = "08:00 AM";
  bool _lunchReminder = true;
  String _lunchTime = "01:00 PM";
  bool _dinnerReminder = true;
  String _dinnerTime = "07:30 PM";
  bool _waterReminder = true;
  String _waterInterval = "Every 2 hours";

  // 4. Display
  String _weekStartsOn = "Monday"; // Monday, Sunday
  String _macroDisplayFormat = "Grams (g)"; // Grams (g), Percentage (%)
  bool _hapticFeedback = true;

  // 5. Dynamic Alerts & Notification Muting
  bool _notifMasterEnabled = true;
  bool _notifWaterEnabled = true;
  bool _notifMealsEnabled = true;
  bool _notifNutritionEnabled = true;
  bool _notifMineralsEnabled = true;
  bool _notifPremiumEnabled = true;
  bool _notifInAppPopups = true;
  bool _notifDesiSwaps = true;
  bool _notifFasting = true;
  bool _notifGlucose = true;
  bool _notifWorkout = true;
  bool _notifMindset = true;
  bool _notifGutHealth = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationServiceState();
    _loadPreferences();
  }

  void _loadNotificationServiceState() {
    final ns = NotificationService.instance;
    _notifMasterEnabled = ns.masterEnabled;
    _notifWaterEnabled = ns.waterEnabled;
    _notifMealsEnabled = ns.mealsEnabled;
    _notifNutritionEnabled = ns.nutritionEnabled;
    _notifMineralsEnabled = ns.mineralsEnabled;
    _notifPremiumEnabled = ns.premiumEnabled;
    _notifInAppPopups = ns.inAppPopupsEnabled;
    _notifDesiSwaps = ns.desiSwapsEnabled;
    _notifFasting = ns.fastingEnabled;
    _notifGlucose = ns.glucoseEnabled;
    _notifWorkout = ns.workoutEnabled;
    _notifMindset = ns.mindsetEnabled;
    _notifGutHealth = ns.gutHealthEnabled;
  }

  Future<void> _loadPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('UserProfiles')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          final prefs = data['appPreferences'] as Map<String, dynamic>?;

          if (prefs != null) {
            setState(() {
              _weightUnit = prefs['weightUnit'] ?? _weightUnit;
              _heightUnit = prefs['heightUnit'] ?? _heightUnit;
              _energyUnit = prefs['energyUnit'] ?? _energyUnit;
              _waterUnit = prefs['waterUnit'] ?? _waterUnit;

              _aiMealAutopilot = prefs['aiMealAutopilot'] ?? _aiMealAutopilot;
              _aiHealthySwaps = prefs['aiHealthySwaps'] ?? _aiHealthySwaps;
              _smartFoodScanner = prefs['smartFoodScanner'] ?? _smartFoodScanner;
              _calorieAlerts = prefs['calorieAlerts'] ?? _calorieAlerts;

              _breakfastReminder = prefs['breakfastReminder'] ?? _breakfastReminder;
              _breakfastTime = prefs['breakfastTime'] ?? _breakfastTime;
              _lunchReminder = prefs['lunchReminder'] ?? _lunchReminder;
              _lunchTime = prefs['lunchTime'] ?? _lunchTime;
              _dinnerReminder = prefs['dinnerReminder'] ?? _dinnerReminder;
              _dinnerTime = prefs['dinnerTime'] ?? _dinnerTime;
              _waterReminder = prefs['waterReminder'] ?? _waterReminder;
              _waterInterval = prefs['waterInterval'] ?? _waterInterval;

              _weekStartsOn = prefs['weekStartsOn'] ?? _weekStartsOn;
              _macroDisplayFormat = prefs['macroDisplayFormat'] ?? _macroDisplayFormat;
              _hapticFeedback = prefs['hapticFeedback'] ?? _hapticFeedback;

              _notifMasterEnabled = prefs['notifMasterEnabled'] ?? _notifMasterEnabled;
              _notifWaterEnabled = prefs['notifWaterEnabled'] ?? _notifWaterEnabled;
              _notifMealsEnabled = prefs['notifMealsEnabled'] ?? _notifMealsEnabled;
              _notifNutritionEnabled = prefs['notifNutritionEnabled'] ?? _notifNutritionEnabled;
              _notifMineralsEnabled = prefs['notifMineralsEnabled'] ?? _notifMineralsEnabled;
              _notifPremiumEnabled = prefs['notifPremiumEnabled'] ?? _notifPremiumEnabled;
              _notifInAppPopups = prefs['notifInAppPopups'] ?? _notifInAppPopups;
              _notifDesiSwaps = prefs['notifDesiSwaps'] ?? _notifDesiSwaps;
              _notifFasting = prefs['notifFasting'] ?? _notifFasting;
              _notifGlucose = prefs['notifGlucose'] ?? _notifGlucose;
              _notifWorkout = prefs['notifWorkout'] ?? _notifWorkout;
              _notifMindset = prefs['notifMindset'] ?? _notifMindset;
              _notifGutHealth = prefs['notifGutHealth'] ?? _notifGutHealth;
            });

            await NotificationService.instance.updatePreferences(
              master: _notifMasterEnabled,
              water: _notifWaterEnabled,
              meals: _notifMealsEnabled,
              nutrition: _notifNutritionEnabled,
              minerals: _notifMineralsEnabled,
              premium: _notifPremiumEnabled,
              inAppPopups: _notifInAppPopups,
              desiSwaps: _notifDesiSwaps,
              fasting: _notifFasting,
              glucose: _notifGlucose,
              workout: _notifWorkout,
              mindset: _notifMindset,
              gutHealth: _notifGutHealth,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading preferences: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      await NotificationService.instance.updatePreferences(
        master: _notifMasterEnabled,
        water: _notifWaterEnabled,
        meals: _notifMealsEnabled,
        nutrition: _notifNutritionEnabled,
        minerals: _notifMineralsEnabled,
        premium: _notifPremiumEnabled,
        inAppPopups: _notifInAppPopups,
        desiSwaps: _notifDesiSwaps,
        fasting: _notifFasting,
        glucose: _notifGlucose,
        workout: _notifWorkout,
        mindset: _notifMindset,
        gutHealth: _notifGutHealth,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('UserProfiles')
            .doc(user.uid)
            .set({
          'appPreferences': {
            'weightUnit': _weightUnit,
            'heightUnit': _heightUnit,
            'energyUnit': _energyUnit,
            'waterUnit': _waterUnit,
            'aiMealAutopilot': _aiMealAutopilot,
            'aiHealthySwaps': _aiHealthySwaps,
            'smartFoodScanner': _smartFoodScanner,
            'calorieAlerts': _calorieAlerts,
            'breakfastReminder': _breakfastReminder,
            'breakfastTime': _breakfastTime,
            'lunchReminder': _lunchReminder,
            'lunchTime': _lunchTime,
            'dinnerReminder': _dinnerReminder,
            'dinnerTime': _dinnerTime,
            'waterReminder': _waterReminder,
            'waterInterval': _waterInterval,
            'weekStartsOn': _weekStartsOn,
            'macroDisplayFormat': _macroDisplayFormat,
            'hapticFeedback': _hapticFeedback,
            'notifMasterEnabled': _notifMasterEnabled,
            'notifWaterEnabled': _notifWaterEnabled,
            'notifMealsEnabled': _notifMealsEnabled,
            'notifNutritionEnabled': _notifNutritionEnabled,
            'notifMineralsEnabled': _notifMineralsEnabled,
            'notifPremiumEnabled': _notifPremiumEnabled,
            'notifInAppPopups': _notifInAppPopups,
            'notifDesiSwaps': _notifDesiSwaps,
            'notifFasting': _notifFasting,
            'notifGlucose': _notifGlucose,
            'notifWorkout': _notifWorkout,
            'notifMindset': _notifMindset,
            'notifGutHealth': _notifGutHealth,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving preferences: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "drawer_preferences".tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, color: _primaryColor, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "Customize your nutrition tracking experience, measurement units, AI assistance, and reminder schedules.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. UNITS & MEASUREMENTS
            _buildSectionHeader("pref_units_header".tr()),
            _buildCard([
              _buildChoiceRow(
                icon: Icons.scale_outlined,
                title: "pref_weight_unit".tr(),
                value: _weightUnit.toUpperCase(),
                options: const ["kg", "lbs"],
                onSelected: (val) {
                  setState(() => _weightUnit = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildChoiceRow(
                icon: Icons.height,
                title: "pref_height_unit".tr(),
                value: _heightUnit == "cm" ? "Centimeters (cm)" : "Feet/Inches (ft/in)",
                options: const ["cm", "ft/in"],
                onSelected: (val) {
                  setState(() => _heightUnit = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildChoiceRow(
                icon: Icons.local_fire_department_outlined,
                title: "pref_energy_unit".tr(),
                value: _energyUnit == "kcal" ? "Calories (kcal)" : "Kilojoules (kJ)",
                options: const ["kcal", "kJ"],
                onSelected: (val) {
                  setState(() => _energyUnit = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildChoiceRow(
                icon: Icons.water_drop_outlined,
                title: "pref_water_unit".tr(),
                value: _waterUnit == "ml" ? "Milliliters (ml)" : "Fluid Ounces (fl oz)",
                options: const ["ml", "fl oz"],
                onSelected: (val) {
                  setState(() => _waterUnit = val);
                  _savePreferences();
                },
              ),
            ]),
            const SizedBox(height: 24),

            // 2. SMART AI & AUTOMATION
            _buildSectionHeader("pref_ai_header".tr()),
            _buildCard([
              _buildSwitchRow(
                icon: Icons.auto_awesome,
                title: "pref_ai_autopilot".tr(),
                subtitle: "pref_ai_autopilot_sub".tr(),
                value: _aiMealAutopilot,
                onChanged: (val) {
                  setState(() => _aiMealAutopilot = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildSwitchRow(
                icon: Icons.swap_horiz,
                title: "pref_ai_swaps".tr(),
                subtitle: "pref_ai_swaps_sub".tr(),
                value: _aiHealthySwaps,
                onChanged: (val) {
                  setState(() => _aiHealthySwaps = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildSwitchRow(
                icon: Icons.qr_code_scanner,
                title: "pref_scanner".tr(),
                subtitle: "pref_scanner_sub".tr(),
                value: _smartFoodScanner,
                onChanged: (val) {
                  setState(() => _smartFoodScanner = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildSwitchRow(
                icon: Icons.notifications_active_outlined,
                title: "pref_alerts".tr(),
                subtitle: "pref_alerts_sub".tr(),
                value: _calorieAlerts,
                onChanged: (val) {
                  setState(() => _calorieAlerts = val);
                  _savePreferences();
                },
              ),
            ]),
            const SizedBox(height: 24),

            // 3. MEAL & HYDRATION REMINDERS
            _buildSectionHeader("pref_reminders_header".tr()),
            _buildCard([
              _buildReminderRow(
                icon: Icons.breakfast_dining_outlined,
                title: "pref_rem_breakfast".tr(),
                time: _breakfastTime,
                enabled: _breakfastReminder,
                onToggle: (val) {
                  setState(() => _breakfastReminder = val);
                  _savePreferences();
                },
                onPickTime: () => _pickTime(_breakfastTime, (t) {
                  setState(() => _breakfastTime = t);
                  _savePreferences();
                }),
              ),
              const Divider(height: 1, indent: 50),
              _buildReminderRow(
                icon: Icons.lunch_dining_outlined,
                title: "pref_rem_lunch".tr(),
                time: _lunchTime,
                enabled: _lunchReminder,
                onToggle: (val) {
                  setState(() => _lunchReminder = val);
                  _savePreferences();
                },
                onPickTime: () => _pickTime(_lunchTime, (t) {
                  setState(() => _lunchTime = t);
                  _savePreferences();
                }),
              ),
              const Divider(height: 1, indent: 50),
              _buildReminderRow(
                icon: Icons.dinner_dining_outlined,
                title: "pref_rem_dinner".tr(),
                time: _dinnerTime,
                enabled: _dinnerReminder,
                onToggle: (val) {
                  setState(() => _dinnerReminder = val);
                  _savePreferences();
                },
                onPickTime: () => _pickTime(_dinnerTime, (t) {
                  setState(() => _dinnerTime = t);
                  _savePreferences();
                }),
              ),
              const Divider(height: 1, indent: 50),
              _buildChoiceRow(
                icon: Icons.opacity,
                title: "pref_rem_water".tr(),
                value: _waterReminder ? _waterInterval : "Disabled",
                options: const [
                  "Every 1 hour",
                  "Every 2 hours",
                  "Every 3 hours",
                  "Disabled",
                ],
                onSelected: (val) {
                  setState(() {
                    if (val == "Disabled") {
                      _waterReminder = false;
                    } else {
                      _waterReminder = true;
                      _waterInterval = val;
                    }
                  });
                  _savePreferences();
                },
              ),
            ]),
            const SizedBox(height: 24),

            // 4. DISPLAY & SCHEDULE
            _buildSectionHeader("pref_display_header".tr()),
            _buildCard([
              _buildChoiceRow(
                icon: Icons.calendar_today_outlined,
                title: "pref_week_starts".tr(),
                value: _weekStartsOn,
                options: const ["Monday", "Sunday"],
                onSelected: (val) {
                  setState(() => _weekStartsOn = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildChoiceRow(
                icon: Icons.pie_chart_outline,
                title: "pref_macro_format".tr(),
                value: _macroDisplayFormat,
                options: const ["Grams (g)", "Percentage (%)"],
                onSelected: (val) {
                  setState(() => _macroDisplayFormat = val);
                  _savePreferences();
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildSwitchRow(
                icon: Icons.vibration,
                title: "pref_haptic".tr(),
                subtitle: "Vibrate slightly when logging meals and hitting targets",
                value: _hapticFeedback,
                onChanged: (val) {
                  setState(() => _hapticFeedback = val);
                  _savePreferences();
                },
              ),
            ]),
            const SizedBox(height: 24),

            // 5. NOTIFICATION & ALERT CONTROLS (MUTING)
            _buildSectionHeader("Alerts & Notification Muting"),
            _buildCard([
              _buildSwitchRow(
                icon: Icons.notifications_active,
                title: "Allow In-App Notifications",
                subtitle: "Enable or mute all dynamic 24h health alerts",
                value: _notifMasterEnabled,
                onChanged: (val) {
                  setState(() => _notifMasterEnabled = val);
                  _savePreferences();
                },
              ),
              if (_notifMasterEnabled) ...[
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.water_drop_outlined,
                  title: "Water Intake Alerts",
                  subtitle: "Periodic reminders when water hasn't been logged",
                  value: _notifWaterEnabled,
                  onChanged: (val) {
                    setState(() => _notifWaterEnabled = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.restaurant_outlined,
                  title: "Meal Logging Reminders",
                  subtitle: "Breakfast, Lunch and Dinner diary checks",
                  value: _notifMealsEnabled,
                  onChanged: (val) {
                    setState(() => _notifMealsEnabled = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.pie_chart_outline,
                  title: "Nutrition & Macro Deficits",
                  subtitle: "Alerts for Protein, Fiber, and Sodium imbalances",
                  value: _notifNutritionEnabled,
                  onChanged: (val) {
                    setState(() => _notifNutritionEnabled = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.biotech_outlined,
                  title: "Mineral & Vitamin Insights",
                  subtitle: "Iron, Potassium, Calcium and Magnesium alerts",
                  value: _notifMineralsEnabled,
                  onChanged: (val) {
                    setState(() => _notifMineralsEnabled = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.restaurant_menu,
                  title: "Smart Desi Swaps & Oil Alerts",
                  subtitle: "Culturally smart swaps, chai sugar audits & ghee checks",
                  value: _notifDesiSwaps,
                  onChanged: (val) {
                    setState(() => _notifDesiSwaps = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.hourglass_bottom,
                  title: "Intermittent Fasting & Timers",
                  subtitle: "Eating window closing warnings & 16:8 completion",
                  value: _notifFasting,
                  onChanged: (val) {
                    setState(() => _notifFasting = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.directions_walk,
                  title: "Post-Meal Glucose Walk Prompts",
                  subtitle: "10-minute walk prompt after high-carb meals",
                  value: _notifGlucose,
                  onChanged: (val) {
                    setState(() => _notifGlucose = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.fitness_center,
                  title: "Workout Fueling & Protein Windows",
                  subtitle: "Pre-workout glycogen & post-workout anabolic recovery",
                  value: _notifWorkout,
                  onChanged: (val) {
                    setState(() => _notifWorkout = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.psychology,
                  title: "Mindful Eating & Anti-Guilt Shifts",
                  subtitle: "Craving checks, satiety signals & cheat meal reset coaching",
                  value: _notifMindset,
                  onChanged: (val) {
                    setState(() => _notifMindset = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.spa,
                  title: "Gut Diversity & Plant Challenges",
                  subtitle: "30-plant challenge, microbiome health & probiotic tips",
                  value: _notifGutHealth,
                  onChanged: (val) {
                    setState(() => _notifGutHealth = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.stars_outlined,
                  title: "AI & Premium Special Offers",
                  subtitle: "Autopilot perks and exclusive subscription discounts",
                  value: _notifPremiumEnabled,
                  onChanged: (val) {
                    setState(() => _notifPremiumEnabled = val);
                    _savePreferences();
                  },
                ),
                const Divider(height: 1, indent: 50),
                _buildSwitchRow(
                  icon: Icons.ad_units_outlined,
                  title: "In-App Floating Toast Banners",
                  subtitle: "Show top banner popup when an alert fires in app",
                  value: _notifInAppPopups,
                  onChanged: (val) {
                    setState(() => _notifInAppPopups = val);
                    _savePreferences();
                  },
                ),
              ],
            ]),
            const SizedBox(height: 24),

            // 6. CACHE & STORAGE
            _buildSectionHeader("pref_data_header".tr()),
            _buildCard([
              ListTile(
                leading: Icon(Icons.cloud_done_outlined, color: _primaryColor),
                title: Text(
                  "pref_offline_db".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  "pref_offline_sub".tr(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.check, color: Color(0xFF09B84F)),
              ),
              const Divider(height: 1, indent: 50),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
                title: Text(
                  "pref_clear_cache".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  "pref_clear_sub".tr(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("cache_cleared".tr()),
                        backgroundColor: _primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Text("clear".tr(), style: const TextStyle(color: Colors.orange)),
                ),
              ),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
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
      ),
      child: Column(children: children),
    );
  }

  Widget _buildChoiceRow({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: _tealColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Select $title",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...options.map(
                  (opt) => ListTile(
                    title: Text(opt),
                    trailing: opt.toLowerCase() == value.toLowerCase()
                        ? Icon(Icons.check, color: _primaryColor)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelected(opt);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: _tealColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      activeColor: _primaryColor,
      onChanged: onChanged,
    );
  }

  Widget _buildReminderRow({
    required IconData icon,
    required String title,
    required String time,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onPickTime,
  }) {
    return ListTile(
      leading: Icon(icon, color: _tealColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: enabled
          ? InkWell(
              onTap: onPickTime,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 12, color: _primaryColor),
                  ],
                ),
              ),
            )
          : const Text("Disabled", style: TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: enabled,
        activeColor: _primaryColor,
        onChanged: onToggle,
      ),
    );
  }

  void _pickTime(String currentTime, ValueChanged<String> onSelected) async {
    // Parse current time string if possible
    int hour = 8;
    int minute = 0;
    try {
      final parts = currentTime.split(' ');
      final hm = parts[0].split(':');
      hour = int.parse(hm[0]);
      minute = int.parse(hm[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == "PM" && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == "AM" && hour == 12) {
        hour = 0;
      }
    } catch (_) {}

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null && mounted) {
      final formatted = picked.format(context);
      onSelected(formatted);
    }
  }
}
