import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String category; // 'water', 'meal', 'nutrition', 'mineral', 'premium', 'streak', 'desi_swaps', 'fasting', 'glucose_crash', 'workout_fuel', 'mindset', 'gut_health'
  final String? actionRoute; // 'water', 'meal', 'premium', 'macros', 'fasting'

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.category,
    this.actionRoute,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'category': category,
        'actionRoute': actionRoute,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
            : DateTime.now(),
        isRead: json['isRead'] ?? false,
        category: json['category'] ?? 'general',
        actionRoute: json['actionRoute'],
      );

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return "${difference.inDays}d ago";
    }
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  static const String _storageKey = 'nutri_dynamic_notifications_v2';
  static const String _prefMaster = 'notif_master_enabled';
  static const String _prefWater = 'notif_water_enabled';
  static const String _prefMeals = 'notif_meals_enabled';
  static const String _prefNutrition = 'notif_nutrition_enabled';
  static const String _prefMinerals = 'notif_minerals_enabled';
  static const String _prefPremium = 'notif_premium_enabled';
  static const String _prefInAppPopups = 'notif_in_app_popup';

  // Advanced Smart Notification Preferences
  static const String _prefDesiSwaps = 'notif_desi_swaps_enabled';
  static const String _prefFasting = 'notif_fasting_enabled';
  static const String _prefGlucose = 'notif_glucose_walk_enabled';
  static const String _prefWorkout = 'notif_workout_fuel_enabled';
  static const String _prefMindset = 'notif_mindset_enabled';
  static const String _prefGutHealth = 'notif_gut_health_enabled';

  final List<NotificationItem> _notifications = [];
  Timer? _simulationTimer;
  final Random _random = Random();

  // Local notifications plugin for external status bar alerts
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isNotificationsInitialized = false;

  // Observable for new incoming notification to show in-app banner/toast
  final ValueNotifier<NotificationItem?> latestAlertNotifier =
      ValueNotifier<NotificationItem?>(null);

  // Preference Settings
  bool masterEnabled = true;
  bool waterEnabled = true;
  bool mealsEnabled = true;
  bool nutritionEnabled = true;
  bool mineralsEnabled = true;
  bool premiumEnabled = true;
  bool inAppPopupsEnabled = false; // Default to false so user is not interrupted in-app

  // Advanced toggles
  bool desiSwapsEnabled = true;
  bool fastingEnabled = true;
  bool glucoseEnabled = true;
  bool workoutEnabled = true;
  bool mindsetEnabled = true;
  bool gutHealthEnabled = true;

  List<NotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    await _initLocalNotifications();
    await loadPreferences();
    await _loadFromStorage();

    if (_notifications.isEmpty) {
      _seedInitialNotifications();
      await _saveToStorage();
    }

    _startSimulationTimer();
  }

  /// Request Android 13/14 and iOS notification permissions interactively
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted = await androidImpl?.requestNotificationsPermission();
        if (granted == true) return true;

        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
      return false;
    }
  }

  /// Check whether system notification permission is granted
  Future<bool> checkPermissionStatus() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initLocalNotifications() async {
    if (_isNotificationsInitialized) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("External notification response payload: ${response.payload}");
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        // Create explicit high-importance notification channel for Android status bar
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'nutriapp_live_alerts_v4',
          'Nutrition & Health Alerts',
          description:
              'High-priority notifications for meals, water, and health tips',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidImpl?.createNotificationChannel(channel);
        await androidImpl?.requestNotificationsPermission();

        // Also request permission explicitly via permission_handler for Android 13/14
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }

      _isNotificationsInitialized = true;
    } catch (e) {
      debugPrint("Error initializing local notifications: $e");
    }
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      masterEnabled = prefs.getBool(_prefMaster) ?? true;
      waterEnabled = prefs.getBool(_prefWater) ?? true;
      mealsEnabled = prefs.getBool(_prefMeals) ?? true;
      nutritionEnabled = prefs.getBool(_prefNutrition) ?? true;
      mineralsEnabled = prefs.getBool(_prefMinerals) ?? true;
      premiumEnabled = prefs.getBool(_prefPremium) ?? true;
      inAppPopupsEnabled = prefs.getBool(_prefInAppPopups) ?? false; // Default to false

      desiSwapsEnabled = prefs.getBool(_prefDesiSwaps) ?? true;
      fastingEnabled = prefs.getBool(_prefFasting) ?? true;
      glucoseEnabled = prefs.getBool(_prefGlucose) ?? true;
      workoutEnabled = prefs.getBool(_prefWorkout) ?? true;
      mindsetEnabled = prefs.getBool(_prefMindset) ?? true;
      gutHealthEnabled = prefs.getBool(_prefGutHealth) ?? true;

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading notification preferences: $e");
    }
  }

  Future<void> updatePreferences({
    bool? master,
    bool? water,
    bool? meals,
    bool? nutrition,
    bool? minerals,
    bool? premium,
    bool? inAppPopups,
    bool? desiSwaps,
    bool? fasting,
    bool? glucose,
    bool? workout,
    bool? mindset,
    bool? gutHealth,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (master != null) {
      masterEnabled = master;
      await prefs.setBool(_prefMaster, master);
    }
    if (water != null) {
      waterEnabled = water;
      await prefs.setBool(_prefWater, water);
    }
    if (meals != null) {
      mealsEnabled = meals;
      await prefs.setBool(_prefMeals, meals);
    }
    if (nutrition != null) {
      nutritionEnabled = nutrition;
      await prefs.setBool(_prefNutrition, nutrition);
    }
    if (minerals != null) {
      mineralsEnabled = minerals;
      await prefs.setBool(_prefMinerals, minerals);
    }
    if (premium != null) {
      premiumEnabled = premium;
      await prefs.setBool(_prefPremium, premium);
    }
    if (inAppPopups != null) {
      inAppPopupsEnabled = inAppPopups;
      await prefs.setBool(_prefInAppPopups, inAppPopups);
    }
    if (desiSwaps != null) {
      desiSwapsEnabled = desiSwaps;
      await prefs.setBool(_prefDesiSwaps, desiSwaps);
    }
    if (fasting != null) {
      fastingEnabled = fasting;
      await prefs.setBool(_prefFasting, fasting);
    }
    if (glucose != null) {
      glucoseEnabled = glucose;
      await prefs.setBool(_prefGlucose, glucose);
    }
    if (workout != null) {
      workoutEnabled = workout;
      await prefs.setBool(_prefWorkout, workout);
    }
    if (mindset != null) {
      mindsetEnabled = mindset;
      await prefs.setBool(_prefMindset, mindset);
    }
    if (gutHealth != null) {
      gutHealthEnabled = gutHealth;
      await prefs.setBool(_prefGutHealth, gutHealth);
    }
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonString);
        _notifications.clear();
        for (var item in list) {
          _notifications.add(NotificationItem.fromJson(item));
        }
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading notifications from storage: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error saving notifications: $e");
    }
  }

  void _seedInitialNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationItem(
        id: "seed_desi_1",
        title: "Smart Desi Swap 🍛",
        message: "Having Karahi or Biryani tonight? Swap fried Paratha for Tandoori Roti to cut 220 kcal easily without giving up your favorite food!",
        timestamp: now.subtract(const Duration(minutes: 8)),
        isRead: false,
        category: "desi_swaps",
        actionRoute: "meal",
      ),
      NotificationItem(
        id: "seed_glucose_1",
        title: "10-Minute Walk Prompt 👟",
        message: "Finished lunch? A brisk 10-minute post-meal walk blunts blood sugar spikes by up to 34% and stops the 3 PM afternoon slump.",
        timestamp: now.subtract(const Duration(minutes: 35)),
        isRead: false,
        category: "glucose_crash",
        actionRoute: "macros",
      ),
      NotificationItem(
        id: "seed_fasting_1",
        title: "Fasting Window Closing ⏳",
        message: "Your eating window closes in 45 minutes! Finish your last bite to optimize overnight fat oxidation and deep REM sleep.",
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        isRead: false,
        category: "fasting",
        actionRoute: "fasting",
      ),
      NotificationItem(
        id: "seed_water_1",
        title: "Hydration Alert 💧",
        message: "You haven't logged water in 3 hours. Time for a refreshing 250ml glass!",
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
        isRead: false,
        category: "water",
        actionRoute: "water",
      ),
      NotificationItem(
        id: "seed_nutr_1",
        title: "Protein Target Alert 🥩",
        message: "You need 35g more protein today to hit your muscle recovery goal. Try chicken, lentils, or paneer!",
        timestamp: now.subtract(const Duration(hours: 4)),
        isRead: true,
        category: "nutrition",
        actionRoute: "macros",
      ),
      NotificationItem(
        id: "seed_min_1",
        title: "Iron & Bioavailability 🥬",
        message: "Eating Daal tonight? Squeeze fresh lemon over it! Vitamin C quadruples plant-based iron absorption.",
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: true,
        category: "mineral",
        actionRoute: "macros",
      ),
      NotificationItem(
        id: "seed_mindset_1",
        title: "Anti-Guilt Mindset Shift 🛡️",
        message: "Remember: One heavy meal never ruins a whole week of fat loss. Don't starve yourself tomorrow; stay hydrated and keep going!",
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
        category: "mindset",
        actionRoute: "macros",
      ),
      NotificationItem(
        id: "seed_prem_1",
        title: "Unlock AI Autopilot 🌟",
        message: "Generate 100% personalized Indian & Pakistani meal plans matching your exact calorie macros with 1-click on NutriAI Premium.",
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
        category: "premium",
        actionRoute: "premium",
      ),
    ]);
  }

  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    // Regular dynamic alert schedule: delivers a smart health reminder every 1 hour
    _simulationTimer = Timer.periodic(const Duration(hours: 1), (_) {
      generateRandomAlert(showPopup: false, showSystemNotification: true);
    });
  }

  /// Triggers a smart dynamic alert based on user preferences and current hour
  NotificationItem? generateRandomAlert({
    bool showPopup = false,
    bool showSystemNotification = true,
  }) {
    if (!masterEnabled) return null;

    // Collect allowed categories
    final List<String> eligibleCategories = [];
    if (waterEnabled) eligibleCategories.add('water');
    if (mealsEnabled) eligibleCategories.add('meal');
    if (desiSwapsEnabled) eligibleCategories.add('desi_swaps');
    if (fastingEnabled) eligibleCategories.add('fasting');
    if (glucoseEnabled) eligibleCategories.add('glucose_crash');
    if (workoutEnabled) eligibleCategories.add('workout_fuel');
    if (nutritionEnabled) eligibleCategories.add('nutrition');
    if (mineralsEnabled) eligibleCategories.add('mineral');
    if (mindsetEnabled) eligibleCategories.add('mindset');
    if (gutHealthEnabled) eligibleCategories.add('gut_health');
    if (premiumEnabled) eligibleCategories.add('premium');
    eligibleCategories.add('streak');

    if (eligibleCategories.isEmpty) return null;

    final selectedCategory =
        eligibleCategories[_random.nextInt(eligibleCategories.length)];
    final candidateAlerts = _alertPool[selectedCategory];
    if (candidateAlerts == null || candidateAlerts.isEmpty) return null;

    final selected = candidateAlerts[_random.nextInt(candidateAlerts.length)];
    final newItem = NotificationItem(
      id: "alert_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}",
      title: selected["title"]!,
      message: selected["message"]!,
      timestamp: DateTime.now(),
      isRead: false,
      category: selectedCategory,
      actionRoute: selected["actionRoute"],
    );

    // Keep notifications capped at 50 to maintain great performance
    _notifications.insert(0, newItem);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }

    _saveToStorage();
    notifyListeners();

    if (showPopup && inAppPopupsEnabled) {
      latestAlertNotifier.value = newItem;
    }

    if (showSystemNotification) {
      _showExternalSystemNotification(newItem);
    }

    return newItem;
  }

  Future<void> _showExternalSystemNotification(NotificationItem item) async {
    if (kIsWeb) return;
    try {
      if (!_isNotificationsInitialized) {
        await _initLocalNotifications();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'nutriapp_live_alerts_v4',
        'Nutrition & Health Alerts',
        channelDescription:
            'High-priority notifications for meals, water, and health tips',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final int notifId = item.id.hashCode & 0x7FFFFFFF;

      await _localNotifications.show(
        id: notifId,
        title: item.title,
        body: item.message,
        notificationDetails: platformDetails,
        payload: item.actionRoute,
      );
      debugPrint("🔔 SENT SYSTEM NOTIFICATION: ${item.title} (ID: $notifId)");
    } catch (e) {
      debugPrint("Error showing external system notification: $e");
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveToStorage();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    latestAlertNotifier.dispose();
    super.dispose();
  }

  // --- Dynamic Alert Templates Pool ---
  static const Map<String, List<Map<String, String>>> _alertPool = {
    'desi_swaps': [
      {
        "title": "Smart Desi Swap 🍛",
        "message": "Craving Karahi or Biryani tonight? Opt for Tandoori Roti instead of Naan/Paratha to save 220 kcal easily!",
        "actionRoute": "meal",
      },
      {
        "title": "Chai Sugar Audit ☕",
        "message": "Cutting just 1 spoon of refined sugar from your daily Doodh Patti cuts ~18,000 kcal a year — that's 2.5 kg of pure body fat!",
        "actionRoute": "meal",
      },
      {
        "title": "Cooking Oil Check 🍳",
        "message": "Cooking Desi curries today? 1 extra tablespoon of Ghee or Mustard oil adds 120 untracked calories. Measure with a spoon!",
        "actionRoute": "meal",
      },
      {
        "title": "Daal Bioavailability Boost 🍋",
        "message": "Eating Daal tonight? Pair it with a fresh squeeze of lemon (Vitamin C) to quadruple your plant-based iron absorption!",
        "actionRoute": "meal",
      },
    ],
    'fasting': [
      {
        "title": "Fasting Window Closing ⏳",
        "message": "Your eating window closes in 30 minutes! Wrap up your final meal to maximize nighttime insulin sensitivity.",
        "actionRoute": "fasting",
      },
      {
        "title": "16:8 Fast Completed ✨",
        "message": "Awesome discipline! Your digestive system has rested. Break your fast gently with healthy fats or eggs rather than heavy sugar.",
        "actionRoute": "fasting",
      },
      {
        "title": "Late Night Craving Guard 🌙",
        "message": "Eating after 10 PM disrupts REM sleep and spikes morning fasting blood glucose. Try warm chamomile tea instead!",
        "actionRoute": "fasting",
      },
    ],
    'glucose_crash': [
      {
        "title": "10-Minute Walk Prompt 👟",
        "message": "Logged a high-carb meal? Take a brisk 10-minute walk now! Studies show it blunts glucose spikes by up to 34%.",
        "actionRoute": "macros",
      },
      {
        "title": "Food Sequencing Secret 🥦",
        "message": "Pro-tip: Eat your veggies and fiber first, proteins second, and rice/roti last to prevent the 3 PM afternoon slump.",
        "actionRoute": "macros",
      },
    ],
    'workout_fuel': [
      {
        "title": "Pre-Workout Fueling ⚡",
        "message": "Hitting the gym in 45 minutes? Eat an easily digestible carb like a banana or two dates for explosive ATP muscle glycogen.",
        "actionRoute": "macros",
      },
      {
        "title": "Anabolic Recovery Window 🏋️",
        "message": "Post-workout muscles are primed for protein synthesis! Aim for 25-35g of protein in the next 60 minutes.",
        "actionRoute": "macros",
      },
    ],
    'mindset': [
      {
        "title": "Hungry or Bored? 🧠",
        "message": "Sudden intense craving for sweets? Ask yourself: are you truly hungry or just stressed? Drink 300ml cold water and wait 10 mins.",
        "actionRoute": "macros",
      },
      {
        "title": "Anti-Guilt Reset 🛡️",
        "message": "Over your calorie budget at dinner? Relax: 1 meal never ruins a week of progress. Don't starve yourself tomorrow; stay consistent!",
        "actionRoute": "macros",
      },
      {
        "title": "Mindful Satiety Rule 🧘",
        "message": "It takes 20 minutes for your stomach to signal leptin (fullness) to your brain. Chew slowly and pause before second helpings!",
        "actionRoute": "macros",
      },
    ],
    'gut_health': [
      {
        "title": "Gut Microbiome Diversity 🌱",
        "message": "Have you eaten 5 different colors of plants today? Diversity in seeds, herbs, and greens builds a resilient gut microbiome.",
        "actionRoute": "macros",
      },
      {
        "title": "Fermented Food Boost 🥣",
        "message": "Add a bowl of fresh homemade Dahi (yogurt) or pickled veggies today to introduce billions of live beneficial probiotics!",
        "actionRoute": "meal",
      },
    ],
    'water': [
      {
        "title": "Hydration Reminder 💧",
        "message": "You haven't logged water recently. Stay on track: Drink a 250ml glass now!",
        "actionRoute": "water",
      },
      {
        "title": "Beat Afternoon Fatigue 💧",
        "message": "Midday dehydration reduces focus by 20%. Grab a water refill!",
        "actionRoute": "water",
      },
      {
        "title": "Water Goal Progress 💧",
        "message": "You're doing great! Keep up with your hydration target before evening.",
        "actionRoute": "water",
      },
    ],
    'meal': [
      {
        "title": "Did you forget your meal? 🍳",
        "message": "You haven't logged food in a while. Keep your diary updated for exact calorie calculations!",
        "actionRoute": "meal",
      },
      {
        "title": "Lunch Check 🥗",
        "message": "Time to recharge! Log your afternoon lunch and track your macro splits.",
        "actionRoute": "meal",
      },
      {
        "title": "Dinner Ahead 🍲",
        "message": "Evening is approaching. Check your remaining calorie allowance before dinner!",
        "actionRoute": "meal",
      },
    ],
    'nutrition': [
      {
        "title": "Low Protein Alert 🥩",
        "message": "Your logged meals are short on protein today. Add chicken breast, eggs, or lentils to reach your target!",
        "actionRoute": "macros",
      },
      {
        "title": "Fiber Intake Low 🥑",
        "message": "You need more dietary fiber for optimal digestion. Try oats, beans, or chia seeds.",
        "actionRoute": "macros",
      },
      {
        "title": "Sodium Awareness 🧂",
        "message": "Sodium intake is on the higher side today. Balance it with plenty of fresh water!",
        "actionRoute": "macros",
      },
    ],
    'mineral': [
      {
        "title": "Iron Deficiency Insight 🥬",
        "message": "You are under on Iron today. Spinach, dark greens, or chickpeas will boost your blood oxygenation!",
        "actionRoute": "macros",
      },
      {
        "title": "Potassium Boost 🍌",
        "message": "Muscles feeling tight? Boost potassium with a banana, coconut water, or baked potato.",
        "actionRoute": "macros",
      },
      {
        "title": "Calcium Check 🥛",
        "message": "Support your bones and teeth! Include yogurt, milk, or fortified plant milk in your next snack.",
        "actionRoute": "macros",
      },
      {
        "title": "Magnesium for Recovery 🍫",
        "message": "Low magnesium can cause muscle cramps and poor sleep. Dark chocolate or pumpkin seeds can help!",
        "actionRoute": "macros",
      },
    ],
    'premium': [
      {
        "title": "Unlock AI Autopilot ⭐",
        "message": "Generate complete, chef-balanced Indian & Pakistani meal plans with 1-click. Upgrade to Premium!",
        "actionRoute": "premium",
      },
      {
        "title": "Missing Out on Full Macro Analysis 📊",
        "message": "Premium users get vitamin breakdowns, mineral trackers, and unlimited camera scans.",
        "actionRoute": "premium",
      },
      {
        "title": "20% Discount for You! 🎉",
        "message": "Get 20% off NutriAI Yearly Premium this week. Reach your target body fat faster!",
        "actionRoute": "premium",
      },
    ],
    'streak': [
      {
        "title": "Calorie Target Streak! 🔥",
        "message": "You are staying consistent! Maintaining your target calories speeds up fat loss.",
        "actionRoute": "macros",
      },
      {
        "title": "Consistency Pays Off 🎯",
        "message": "Daily food logging users lose 2x more weight. Keep logging every meal!",
        "actionRoute": "meal",
      },
    ],
  };
}
