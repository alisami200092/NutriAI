import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/activity/activity_log_page.dart';
import 'package:nutriapp/dashboard/bottom_nav.dart';
import 'package:nutriapp/dashboard/calories-analysis/summary_foods_tab.dart';
import 'package:nutriapp/dashboard/water_log_screen.dart';
import 'package:nutriapp/meal_log/breakfast_screen.dart';
import 'package:nutriapp/meal_log/dinner_screen.dart';
import 'package:nutriapp/meal_log/lunch_screen.dart';
import 'package:nutriapp/meal_log/snack_screen.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';
import 'dashboard_widgets.dart';
import 'package:nutriapp/meal_log/view_all_meals.dart';
import 'dashboard_service.dart';
import 'ai_meal_plan_generator.dart';
import 'drawer_screen.dart';
import 'package:nutriapp/services/fat_calculator_service.dart';
import 'gut_shield_banner.dart';

class NutriAIApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const NutriAIApp({super.key, required this.cameras, required this.yolo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF37C97D),
          primary: const Color(0xFF37C97D),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        useMaterial3: true,
      ),
      // ✅ CHANGE THIS LINE:
      home: BottomNav(cameras: cameras, yolo: yolo),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService? yolo;

  const DashboardScreen({super.key, required this.cameras, this.yolo});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // ✅ DYNAMIC DATA VARIABLES
  int _calorieBudget = 2000;

  // ✅ Dynamic Macro Targets & Body Composition
  int _targetCarbs = 250;
  int _targetProtein = 150;
  int _targetFat = 65;
  double _bodyFatPercentage = 0.0;

  final int _steps = 605; // Static for now (as requested)

  // ✅ Service Instance for Real-time Updates
  final DashboardService _dashboardService = DashboardService();

  String _userName = "User";
  String _planType = "Healthy";
  String _userDietType = "";
  String _userRestrictions = "";
  String _userHealthConditions = "";
  bool _isLoadingProfile = true;

  DateTime selectedDate = DateTime.now();

  // --- STATE FOR MEAL PLAN ---
  int _selectedDayIndex = 1;
  final List<String> _weekDays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];

  late MealItem _currentBreakfast;
  late MealItem _currentLunch;
  late MealItem _currentDinner;
  late MealItem _currentSnack;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  // --- GUT SHIELD STATE ---
  bool _gutShieldActive = false;
  List<String> _activeGiTriggers = [];
  String _symptomSummary = "";

  @override
  void initState() {
    super.initState();
    _setFallbackMeals();
    AIMealPlanGenerator.loadData().then((_) {
      if (mounted) {
        setState(() {});
        if (_currentBreakfast.title.startsWith("Loading")) {
          _regenerateFromCSV();
        }
      }
    });
    _listenToUserProfile();
    _fetchWeeklyGraphData();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _fetchWeeklyGraphData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<double> data = await _dashboardService.getWeeklyCalories(
        user.uid,
        selectedDate,
      );
      if (mounted) {
        setState(() {
          _weeklyCalories = data;
        });
      }
    }
  }

  void _setFallbackMeals() {
    _currentBreakfast = MealItem(
      title: "Loading...",
      emoji: "⏳",
      benefits: [],
      nutrition: {},
      timeSuggestion: "8:00 AM",
      highlights: [],
    );
    _currentLunch = MealItem(
      title: "Loading...",
      emoji: "⏳",
      benefits: [],
      nutrition: {},
      timeSuggestion: "1:00 PM",
      highlights: [],
    );
    _currentDinner = MealItem(
      title: "Loading...",
      emoji: "⏳",
      benefits: [],
      nutrition: {},
      timeSuggestion: "7:00 PM",
      highlights: [],
    );
    _currentSnack = MealItem(
      title: "Loading...",
      emoji: "⏳",
      benefits: [],
      nutrition: {},
      timeSuggestion: "4:00 PM",
      highlights: [],
    );
  }

  void _listenToUserProfile() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingProfile = false);
        return;
      }

      _profileSubscription?.cancel();
      _profileSubscription = FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (!doc.exists || !mounted) {
          if (mounted) setState(() => _isLoadingProfile = false);
          return;
        }

        final data = doc.data() as Map<String, dynamic>;
        final String rawGoal = data['dietaryGoal'] ?? "Healthy";
        final String newPlanType;

        if (rawGoal.toLowerCase().contains("gain")) {
          newPlanType = "Weight Gain";
        } else if (rawGoal.toLowerCase().contains("loss") ||
            rawGoal.toLowerCase().contains("lose")) {
          newPlanType = "Weight Loss";
        } else {
          newPlanType = "Maintenance";
        }

        int newCalorieBudget = _calorieBudget;
        if (data['dailyCalorieTarget'] != null) {
          newCalorieBudget = (data['dailyCalorieTarget'] as num).toInt();
        }

        final double userWeight = (data['weight'] ?? 70.0).toDouble();
        final double userHeight = (data['height'] ?? 170.0).toDouble();
        final int userAge = (data['age'] ?? 25) is int
            ? data['age']
            : (data['age'] as num).toInt();
        final String userGender = data['gender'] ?? "male";

        // ✅ Robust Diet Type & Restrictions reading
        final String newDietType =
            data['dietPreference'] ?? data['dietType'] ?? "";
        final dynamic rawRest =
            data['dietaryRestrictions'] ?? data['restrictions'];
        final String newRestrictions = rawRest is List
            ? rawRest.join(", ")
            : (rawRest?.toString() ?? "");
        final String newHealthConditions = data['healthConditions'] ?? "";

        // ✅ Calculate Clinical Body Fat % (Deurenberg Formula)
        final double newBodyFat = FatCalculatorService.calculateBodyFatPercentage(
          weightKg: userWeight,
          heightCm: userHeight,
          age: userAge,
          gender: userGender,
        );

        // ✅ Calculate Macro Targets
        final targets = FatCalculatorService.calculateMacroTargets(
          weightKg: userWeight,
          calorieBudget: newCalorieBudget,
          goal: rawGoal,
          dietPreference: newDietType,
        );

        // Detect if diet preference or restrictions changed from current state
        final bool dietChanged = _userDietType.isNotEmpty &&
            _userDietType.trim().toLowerCase() != newDietType.trim().toLowerCase();
        final bool restrictionsChanged = _userRestrictions.isNotEmpty &&
            _userRestrictions.trim().toLowerCase() !=
                newRestrictions.trim().toLowerCase();

        final String? savedCuisine =
            data['generatedMealPlanCuisine']?.toString();
        final bool savedCuisineMatches = savedCuisine != null &&
            savedCuisine.trim().toLowerCase() == newDietType.trim().toLowerCase();

        // ✅ Read Gut Shield Status and Active Triggers
        final bool newGutShieldActive = data['gut_shield_active'] == true;
        final List<String> newGiTriggers = List<String>.from(
          (data['active_gi_triggers'] as List?)?.map((e) => e.toString()) ?? [],
        );
        final String newSymptomSummary = data['symptom_summary'] ?? "";
        final bool gutShieldChanged = _gutShieldActive != newGutShieldActive ||
            _activeGiTriggers.join(',') != newGiTriggers.join(',');

        setState(() {
          _userName = data['name'] ?? "User";
          _planType = newPlanType;
          _calorieBudget = newCalorieBudget;
          _userDietType = newDietType;
          _userRestrictions = newRestrictions;
          _userHealthConditions = newHealthConditions;
          _bodyFatPercentage = newBodyFat;
          _targetCarbs = targets.carbs;
          _targetProtein = targets.protein;
          _targetFat = targets.fat;
          _gutShieldActive = newGutShieldActive;
          _activeGiTriggers = newGiTriggers;
          _symptomSummary = newSymptomSummary;
          _isLoadingProfile = false;

          // If diet, restrictions, or Gut Shield changed, or saved plan is from a different cuisine,
          // automatically regenerate fresh meals for the active cuisine and safety requirements!
          if (dietChanged ||
              restrictionsChanged ||
              gutShieldChanged ||
              !savedCuisineMatches ||
              data['generatedMealPlan'] == null) {
            _regenerateFromCSV();
          } else {
            final plan = data['generatedMealPlan'] as Map<String, dynamic>;
            _currentBreakfast = _createMealItem(
              plan['Breakfast'],
              "Breakfast",
              0.25,
            );
            _currentLunch = _createMealItem(plan['Lunch'], "Lunch", 0.35);
            _currentDinner = _createMealItem(plan['Dinner'], "Dinner", 0.30);
            _currentSnack = _createMealItem(plan['Snack'], "Snack", 0.10);
          }
        });
      }, onError: (e) {
        debugPrint("Error listening to UserProfiles: $e");
        if (mounted) setState(() => _isLoadingProfile = false);
      });
    } catch (e) {
      debugPrint("Error initializing user profile stream: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  MealItem _createMealItem(String? foodName, String type, double ratio) {
    int estCals = (_calorieBudget * ratio).toInt();

    // Scale meal macros proportionally to the user's scientific daily targets
    int estCarbs = (_targetCarbs * ratio).round();
    int estProtein = (_targetProtein * ratio).round();
    int estFat = (_targetFat * ratio).round();

    // 3. Set Emoji and Time based on meal type
    String emoji = "🍳";
    String time = "8:00 AM";
    if (type == "Lunch") {
      emoji = "🥗";
      time = "1:00 PM";
    } else if (type == "Dinner") {
      emoji = "🍲";
      time = "7:00 PM";
    } else if (type == "Snack") {
      emoji = "🍎";
      time = "4:00 PM";
    }

    return MealItem(
      title: foodName ?? "Not assigned",
      nutrition: {
        "Calories": "$estCals", // 🔥 Fire icon usually checks for "Calories"
        "Protein":
            "${estProtein}g", // 🍗 Chicken icon usually checks for "Protein"
        "Fat": "${estFat}g", // 🥑/💧 Oil icon usually checks for "Fat"
        "Carbs": "${estCarbs}g", // 🍞/🌾 Wheat icon usually checks for "Carbs"
      },
      benefits: ["Optimized for $_planType"],
      timeSuggestion: time,
      highlights: ["AI Pick", "Healthy"],
      emoji: emoji,
    );
  }

  Future<void> _saveCurrentMealPlanToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('UserProfiles')
            .doc(user.uid)
            .set({
          "generatedMealPlan": {
            "Breakfast": _currentBreakfast.title,
            "Lunch": _currentLunch.title,
            "Dinner": _currentDinner.title,
            "Snack": _currentSnack.title,
          },
          "generatedMealPlanCuisine": _userDietType,
          "lastPlanGeneratedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving updated meal plan: $e");
    }
  }

  void _regenerateFromCSV() {
    final int bCals = (_calorieBudget * 0.25).toInt();
    final int lCals = (_calorieBudget * 0.35).toInt();
    final int dCals = (_calorieBudget * 0.30).toInt();
    final int sCals = (_calorieBudget * 0.10).toInt();
    final List<String> triggers =
        _gutShieldActive ? _activeGiTriggers : const [];

    setState(() {
      _currentBreakfast = AIMealPlanGenerator.getBreakfast(
        cuisine: _userDietType,
        dietPreference: _userDietType,
        restrictions: _userRestrictions,
        healthConditions: _userHealthConditions,
        currentMeal: _currentBreakfast,
        calorieBudget: bCals,
        forceNew: true,
        activeGiTriggers: triggers,
      );
      _currentLunch = AIMealPlanGenerator.getLunch(
        cuisine: _userDietType,
        dietPreference: _userDietType,
        restrictions: _userRestrictions,
        healthConditions: _userHealthConditions,
        currentMeal: _currentLunch,
        calorieBudget: lCals,
        forceNew: true,
        activeGiTriggers: triggers,
      );
      _currentDinner = AIMealPlanGenerator.getDinner(
        cuisine: _userDietType,
        dietPreference: _userDietType,
        restrictions: _userRestrictions,
        healthConditions: _userHealthConditions,
        currentMeal: _currentDinner,
        calorieBudget: dCals,
        forceNew: true,
        activeGiTriggers: triggers,
      );
      _currentSnack = AIMealPlanGenerator.getSnack(
        cuisine: _userDietType,
        dietPreference: _userDietType,
        restrictions: _userRestrictions,
        healthConditions: _userHealthConditions,
        currentMeal: _currentSnack,
        calorieBudget: sCals,
        forceNew: true,
        activeGiTriggers: triggers,
      );
    });
    _saveCurrentMealPlanToFirestore();
    _fetchWeeklyGraphData();
  }

  // --- DISMISS GUT SHIELD ACTION ---
  Future<void> _dismissGutShield() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('UserProfiles')
            .doc(user.uid)
            .set({
          'gut_shield_active': false,
          'active_gi_triggers': <String>[],
          'gut_shield_deactivated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _gutShieldActive = false;
            _activeGiTriggers = [];
          });
          _regenerateFromCSV();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gut Shield Deactivated".tr()),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error dismissing Gut Shield: $e");
    }
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    if (diffDays == 0) return "Today".tr();
    if (diffDays == 1) return "${"Tomorrow".tr()}, ${date.day} ${months[date.month - 1]}";
    if (diffDays == -1) {
      return "${"Yesterday".tr()}, ${date.day} ${months[date.month - 1]}";
    }
    return "${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}";
  }

  void _showMacroPopup(BuildContext context, String macroName) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              "Available in Premium".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "In-depth analysis of $macroName is available in Premium. This version provides in-depth analysis of calories and salt.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SummaryFoodAnalysis(selectedDate: selectedDate),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "View Calorie Analysis".tr(),
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "View Salt Analysis".tr(),
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "More Info".tr(),
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Cancel".tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF09B84F)),
        ),
      );
    }

    // ✅ GET USER ID SAFELY
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09B84F),
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Dashboard".tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    "Premium".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: const Color(0xFF09B84F),
            child: Container(
              margin: const EdgeInsets.only(bottom: 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF09B84F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _goToPreviousDay,
                    icon: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.1416),
                      child: const Text(
                        '➤',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _dateLabel(selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _goToNextDay,
                    icon: const Text(
                      '➤',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ START OF DYNAMIC STATS SECTION
              // Wraps the main Stats Card in a StreamBuilder to get real-time database updates
              StreamBuilder<DashboardData>(
                stream: _dashboardService.getDashboardStream(
                  currentUserId,
                  selectedDate,
                ),
                builder: (context, snapshot) {
                  // Fallback if data is loading
                  final data = snapshot.data ?? DashboardData();

                  return Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Text(
                              'Calorie Budget'.tr(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // ✅ Dynamic Budget
                            Text(
                              _calorieBudget.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WorkoutScreen(),
                                        ),
                                      );
                                    },
                                    child: StatLabelValue(
                                      label: 'Exercise'.tr(),
                                      value: data.burned
                                          .toString(), // ✅ DYNAMIC EXERCISE
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  StatLabelValue(
                                    label: 'Steps'.tr(),
                                    value: _steps.toString(),
                                  ), // Static
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WaterTrackerScreen(),
                                        ),
                                      );
                                    },
                                    child: StatLabelValue(
                                      label: 'Water'.tr(),
                                      value: '0',
                                    ), // Static
                                  ),
                                  const SizedBox(height: 6),
                                  StatLabelValue(
                                    label: 'Body Fat'.tr(),
                                    value: _bodyFatPercentage > 0
                                        ? '$_bodyFatPercentage%'
                                        : '--',
                                  ),
                                ],
                              ),
                            ),

                            // ✅ DYNAMIC CIRCULAR WIDGET
                            CircularCalorieWidget(
                              consumed: data.totalEaten, // ✅ Dynamic Eaten
                              budget: (_calorieBudget + data.burned)
                                  .toInt(), // ✅ Dynamic Budget + Burned
                              size: 120,
                              strokeWidth: 8,
                              arcColor: const Color(0xFF37C97D),
                              backgroundArcColor: const Color(0xFFE7ECEF),
                              buildCenter: (context, budget, consumed) {
                                // Logic: (BaseBudget + Exercise) - Food = Left
                                final left = budget - consumed;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      left.toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Calories Left'.tr(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            Expanded(
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BreakfastScreen(
                                            selectedDate: selectedDate,
                                            cameras: widget.cameras,
                                            yolo: widget.yolo!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: StatLabelValue(
                                      label: 'Breakfast'.tr(),
                                      value: data.breakfast.toString(),
                                    ), // ✅ DYNAMIC BREAKFAST
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LunchScreen(
                                            selectedDate: selectedDate,
                                            cameras: widget.cameras,
                                            yolo: widget.yolo!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: StatLabelValue(
                                      label: 'Lunch'.tr(),
                                      value: data.lunch.toString(),
                                    ), // ✅ DYNAMIC LUNCH
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DinnerScreen(
                                            selectedDate: selectedDate,
                                            cameras: widget.cameras,
                                            yolo: widget.yolo!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: StatLabelValue(
                                      label: 'Dinner'.tr(),
                                      value: data.dinner.toString(),
                                    ), // ✅ DYNAMIC DINNER
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SnacksScreen(
                                            selectedDate: selectedDate,
                                            cameras: widget.cameras,
                                            yolo: widget.yolo!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: StatLabelValue(
                                      label: 'Snacks'.tr(),
                                      value: data.snack.toString(),
                                    ), // ✅ DYNAMIC SNACK
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllMealsPage(
                                  initialDate: selectedDate,
                                  cameras: widget.cameras,
                                  yolo: widget.yolo!,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF37C97D),
                          ),
                          child: Text(
                            'View All Meals'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ✅ DYNAMIC MACROS
                        SizedBox(
                          height: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // --- CARBS ---
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showMacroPopup(context, "Carbs"),
                                  child: MacroCircle(
                                    label: 'Carbs'.tr(),
                                    // Calculate % based on user target
                                    percentage: _targetCarbs > 0
                                        ? (data.carbs / _targetCarbs > 1.0
                                              ? 1.0
                                              : data.carbs / _targetCarbs)
                                        : 0.0,
                                    consumedText: '${data.carbs.toInt()}g/',
                                    leftText:
                                        '${_targetCarbs}g', // Dynamic Target
                                    color: const Color(0xFF37C97D),
                                  ),
                                ),
                              ),
                              // --- PROTEIN ---
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showMacroPopup(context, "Protein"),
                                  child: MacroCircle(
                                    label: 'Protein'.tr(),
                                    percentage: _targetProtein > 0
                                        ? (data.protein / _targetProtein > 1.0
                                              ? 1.0
                                              : data.protein / _targetProtein)
                                        : 0.0,
                                    consumedText: '${data.protein.toInt()}g/',
                                    leftText:
                                        '${_targetProtein}g', // Dynamic Target
                                    color: const Color(0xFF37C97D),
                                  ),
                                ),
                              ),
                              // --- FAT ---
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showMacroPopup(context, "Fat"),
                                  child: MacroCircle(
                                    label: 'Fat'.tr(),
                                    percentage: _targetFat > 0
                                        ? (data.fat / _targetFat > 1.0
                                              ? 1.0
                                              : data.fat / _targetFat)
                                        : 0.0,
                                    consumedText: '${data.fat.toInt()}g/',
                                    leftText:
                                        '${_targetFat}g', // Dynamic Target
                                    color: const Color(0xFF37C97D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: weeklyCalorieChart(
                            values: _weeklyCalories,
                            budget: _calorieBudget.toDouble(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // END OF DYNAMIC STATS SECTION
              const SizedBox(height: 20),

              // --- WEEK SELECTOR (DYNAMIC UPDATE) ---
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: List.generate(7, (index) {
                    // 1. Calculate the date for this specific column (Mon-Sun)
                    final now = DateTime.now();
                    // Find the most recent Monday
                    final startOfWeek = now.subtract(
                      Duration(days: now.weekday - 1),
                    );
                    final dayDate = startOfWeek.add(Duration(days: index));

                    // 2. Check if this is the selected date
                    // We compare year/month/day to ignore precise time
                    final isSelected =
                        selectedDate.year == dayDate.year &&
                        selectedDate.month == dayDate.month &&
                        selectedDate.day == dayDate.day;

                    BorderRadius borderRadius;
                    if (index == 0) {
                      borderRadius = const BorderRadius.horizontal(
                        left: Radius.circular(30),
                      );
                    } else if (index == 6) {
                      borderRadius = const BorderRadius.horizontal(
                        right: Radius.circular(30),
                      );
                    } else {
                      borderRadius = BorderRadius.zero;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            // Update the date variable
                            selectedDate = dayDate;
                            // Update the index variable (for UI consistency if used elsewhere)
                            _selectedDayIndex = index;
                            // 🚀 TRIGGER REFRESH: Load specific food for this date
                            _regenerateFromCSV();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF09B84F)
                                : Colors.transparent,
                            borderRadius: borderRadius,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Text(
                                _weekDays[index], // Mon, Tue, Wed
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Show the actual day number (e.g., 27)
                              Text(
                                "${dayDate.day}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // --- GUT SHIELD BANNER (ACTIVE WHEN SYMPTOMS REPORTED) ---
              if (_gutShieldActive) ...[
                GutShieldBanner(
                  symptomSummary: _symptomSummary,
                  activeTriggers: _activeGiTriggers,
                  onDismiss: _dismissGutShield,
                ),
                const SizedBox(height: 16),
              ],

              // --- MEAL PLAN HEADER ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isLoadingProfile
                              ? "Loading Plan...".tr()
                              : "$_userName's ${_planType.tr()} ${'Plan'.tr()} (${_weekDays[_selectedDayIndex]})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (_userDietType.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF09B84F).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _userDietType.toLowerCase().contains("pakistan")
                                    ? "🇵🇰 "
                                    : _userDietType.toLowerCase().contains("indian")
                                        ? "🍛 "
                                        : "🥗 ",
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                _userDietType,
                                style: const TextStyle(
                                  color: Color(0xFF09B84F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        _regenerateFromCSV();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Plan Refreshed".tr(),
                            ),
                            backgroundColor: const Color(0xFF09B84F),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF09B84F)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ RESTORED AI BUTTON TEXT & ICON
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(0xFF09B84F),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "AI Replace All".tr(),
                              style: const TextStyle(
                                color: Color(0xFF09B84F),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- MEAL CARDS (Kept Exact UI) ---
              mealSummaryCard(
                mealLabel: "Breakfast".tr(),
                emoji: _currentBreakfast.emoji,
                foodTitle: _currentBreakfast.title,
                healthBenefits: _currentBreakfast.benefits,
                nutrition: _currentBreakfast.nutrition,
                timeSuggestion: _currentBreakfast.timeSuggestion,
                nutrientHighlights: _currentBreakfast.highlights,
                onReplace: () {
                  final int bCals = (_calorieBudget * 0.25).toInt();
                  setState(() {
                    _currentBreakfast = AIMealPlanGenerator.getBreakfast(
                      cuisine: _userDietType,
                      dietPreference: _userDietType,
                      restrictions: _userRestrictions,
                      healthConditions: _userHealthConditions,
                      currentMeal: _currentBreakfast,
                      calorieBudget: bCals,
                      forceNew: true,
                    );
                  });
                  _saveCurrentMealPlanToFirestore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${'Breakfast'.tr()} ${'updated!'.tr()}"),
                      duration: const Duration(milliseconds: 800),
                      backgroundColor: const Color(0xFF09B84F),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              mealSummaryCard(
                mealLabel: "Lunch".tr(),
                emoji: _currentLunch.emoji,
                foodTitle: _currentLunch.title,
                healthBenefits: _currentLunch.benefits,
                nutrition: _currentLunch.nutrition,
                timeSuggestion: _currentLunch.timeSuggestion,
                nutrientHighlights: _currentLunch.highlights,
                onReplace: () {
                  final int lCals = (_calorieBudget * 0.35).toInt();
                  setState(() {
                    _currentLunch = AIMealPlanGenerator.getLunch(
                      cuisine: _userDietType,
                      dietPreference: _userDietType,
                      restrictions: _userRestrictions,
                      healthConditions: _userHealthConditions,
                      currentMeal: _currentLunch,
                      calorieBudget: lCals,
                      forceNew: true,
                    );
                  });
                  _saveCurrentMealPlanToFirestore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${'Lunch'.tr()} ${'updated!'.tr()}"),
                      duration: const Duration(milliseconds: 800),
                      backgroundColor: const Color(0xFF09B84F),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              mealSummaryCard(
                mealLabel: "Dinner".tr(),
                emoji: _currentDinner.emoji,
                foodTitle: _currentDinner.title,
                healthBenefits: _currentDinner.benefits,
                nutrition: _currentDinner.nutrition,
                timeSuggestion: _currentDinner.timeSuggestion,
                nutrientHighlights: _currentDinner.highlights,
                onReplace: () {
                  final int dCals = (_calorieBudget * 0.30).toInt();
                  setState(() {
                    _currentDinner = AIMealPlanGenerator.getDinner(
                      cuisine: _userDietType,
                      dietPreference: _userDietType,
                      restrictions: _userRestrictions,
                      healthConditions: _userHealthConditions,
                      currentMeal: _currentDinner,
                      calorieBudget: dCals,
                      forceNew: true,
                    );
                  });
                  _saveCurrentMealPlanToFirestore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${'Dinner'.tr()} ${'updated!'.tr()}"),
                      duration: const Duration(milliseconds: 800),
                      backgroundColor: const Color(0xFF09B84F),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              mealSummaryCard(
                mealLabel: "Snacks".tr(),
                emoji: _currentSnack.emoji,
                foodTitle: _currentSnack.title,
                healthBenefits: _currentSnack.benefits,
                nutrition: _currentSnack.nutrition,
                timeSuggestion: _currentSnack.timeSuggestion,
                nutrientHighlights: _currentSnack.highlights,
                onReplace: () {
                  final int sCals = (_calorieBudget * 0.10).toInt();
                  setState(() {
                    _currentSnack = AIMealPlanGenerator.getSnack(
                      cuisine: _userDietType,
                      dietPreference: _userDietType,
                      restrictions: _userRestrictions,
                      healthConditions: _userHealthConditions,
                      currentMeal: _currentSnack,
                      calorieBudget: sCals,
                      forceNew: true,
                    );
                  });
                  _saveCurrentMealPlanToFirestore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${'Snacks'.tr()} ${'updated!'.tr()}"),
                      duration: const Duration(milliseconds: 800),
                      backgroundColor: const Color(0xFF09B84F),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
