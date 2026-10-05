import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added Auth
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/meal_log/all-meals-sections/day_nutrition_service.dart';
import 'package:nutriapp/meal_log/all-meals-sections/view_all_meals_nutrients.dart';
import 'package:nutriapp/meal_log/all-meals-sections/view_nutrients_insights.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'breakfast_screen.dart';
import 'dinner_screen.dart';
import 'lunch_screen.dart';
import 'snack_screen.dart';
import 'all-meals-sections/view_all_meals_totalday.dart';

// Helper class for local use within this file
class FoodItem {
  final String name;
  final String emoji;
  final int calories;

  FoodItem({required this.name, required this.emoji, required this.calories});
}

class AllMealsPage extends StatefulWidget {
  final DateTime initialDate;
  final List<CameraDescription> cameras;
  final YoloService? yolo;
  const AllMealsPage({
    super.key,
    required this.initialDate,
    this.cameras = const [],
    this.yolo,
  });

  @override
  State<AllMealsPage> createState() => _AllMealsPageState();
}

class _AllMealsPageState extends State<AllMealsPage> {
  late DateTime selectedDate;
  String selectedMealView = "All Meals";
  List<CameraDescription> cameras = [];
  late final YoloService _yolo = widget.yolo ?? YoloService();

  bool isDayLogCompleted = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _initCameras();
    _loadDayLogStatus();
  }

  Future<void> _loadDayLogStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'day_log_completed_${_dateKey(selectedDate)}';
    if (mounted) {
      setState(() {
        isDayLogCompleted = prefs.getBool(key) ?? false;
      });
    }
  }

  void _onToggleDayLog(bool val) async {
    setState(() => isDayLogCompleted = val);
    final prefs = await SharedPreferences.getInstance();
    final key = 'day_log_completed_${_dateKey(selectedDate)}';
    await prefs.setBool(key, val);
  }

  Future<void> _initCameras() async {
    final cams = await availableCameras();
    if (!mounted) return;
    setState(() {
      cameras = cams;
    });
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    _loadDayLogStatus();
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
    _loadDayLogStatus();
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

  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  FoodItem _docToFoodItem(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Food').toString();

    // Priority: Use 'estCalories' (calculated in ServingSizePage)
    // or 'calories' if estCalories is missing
    int calories = 0;
    if (data.containsKey('estCalories') && data['estCalories'] is num) {
      calories = (data['estCalories'] as num).toInt();
    } else if (data.containsKey('calories') && data['calories'] is num) {
      calories = (data['calories'] as num).toInt();
    } else {
      // Fallback to per100g logic if calculation is missing
      final caloriesPer100 = data['caloriesPer100g'];
      if (caloriesPer100 is num) {
        calories = caloriesPer100.toInt(); // Rough fallback
      }
    }

    return FoodItem(
      name: name,
      emoji: _emojiForLabel(name),
      calories: calories,
    );
  }

  String _emojiForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('bread')) return '🍞';
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('rice')) return '🍚';
    if (lower.contains('salad') || lower.contains('fruit')) return '🥗';
    if (lower.contains('chicken')) return '🍗';
    if (lower.contains('fish')) return '🍣';
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('burger')) return '🍔';
    if (lower.contains('coffee') || lower.contains('tea')) return '☕';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(selectedDate);
    final user = FirebaseAuth.instance.currentUser;

    // If no user is logged in, show a warning or empty state
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("All Meals".tr())),
        body: Center(child: Text("Please log in to view meals.".tr())),
      );
    }
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF09B84F),
        title: Row(
          children: [
            Text(selectedMealView.tr(), style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onSelected: (value) {
                if (value == "All Meals") {
                  setState(() => selectedMealView = value);
                } else if (value == "Breakfast") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BreakfastScreen(
                        selectedDate: selectedDate,
                        cameras: cameras.isNotEmpty ? cameras : widget.cameras,
                        yolo: _yolo,
                      ),
                    ),
                  );
                } else if (value == "Lunch") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LunchScreen(
                        selectedDate: selectedDate,
                        cameras: cameras.isNotEmpty ? cameras : widget.cameras,
                        yolo: _yolo,
                      ),
                    ),
                  );
                } else if (value == "Dinner") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DinnerScreen(
                        selectedDate: selectedDate,
                        cameras: cameras.isNotEmpty ? cameras : widget.cameras,
                        yolo: _yolo,
                      ),
                    ),
                  );
                } else if (value == "Snacks") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SnacksScreen(
                        selectedDate: selectedDate,
                        cameras: cameras.isNotEmpty ? cameras : widget.cameras,
                        yolo: _yolo,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: "All Meals", child: Text("All Meals".tr())),
                PopupMenuItem(value: "Breakfast", child: Text("Breakfast".tr())),
                PopupMenuItem(value: "Lunch", child: Text("Lunch".tr())),
                PopupMenuItem(value: "Dinner", child: Text("Dinner".tr())),
                PopupMenuItem(value: "Snacks", child: Text("Snacks".tr())),
              ],
            ),
          ],
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
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "Go Premium".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _goToPreviousDay,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF09B84F),
                  ),
                ),
                Text(
                  _dateLabel(selectedDate),
                  style: const TextStyle(
                    color: Color(0xFF09B84F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _goToNextDay,
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF09B84F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DayNutritionData>(
        stream: DayNutritionService.streamDayNutrition(uid, selectedDate),
        builder: (context, snapshot) {
          final dayData = snapshot.data ?? DayNutritionData.empty(selectedDate);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Meal Sections
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // ✅ PASS UID & Use Hierarchy: mealslog -> uid -> days -> date -> category
                    _buildDynamicMealSection(
                      uid,
                      dateKey,
                      "breakfast",
                      "Breakfast",
                      Icons.wb_sunny_outlined,
                    ),
                    const Divider(height: 1),
                    _buildDynamicMealSection(
                      uid,
                      dateKey,
                      "lunch",
                      "Lunch",
                      Icons.lunch_dining,
                    ),
                    const Divider(height: 1),
                    _buildDynamicMealSection(
                      uid,
                      dateKey,
                      "dinner",
                      "Dinner",
                      Icons.nightlight_round,
                    ),
                    const Divider(height: 1),
                    _buildDynamicMealSection(
                      uid,
                      dateKey,
                      "snack",
                      "Snacks",
                      Icons.cookie_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Toggle Switch & Day Totals
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: isDayLogCompleted,
                      activeThumbColor: const Color(0xFF37C97D),
                      onChanged: _onToggleDayLog,
                      title: Text(
                        "Complete Day Food Log".tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isDayLogCompleted) ...[
                      const Divider(height: 1),
                      DayTotalsSection(data: dayData),
                    ],
                  ],
                ),
              ),

              // 3. Nutrients Section & Insights
              if (isDayLogCompleted) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: NutrientsSection(data: dayData),
                ),
                const SizedBox(height: 16),
                NutrientInsightsSection(selectedDate: selectedDate),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF37C97D),
        onPressed: () {
          if (cameras.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BreakfastScreen(
                  selectedDate: selectedDate,
                  cameras: cameras.isNotEmpty ? cameras : widget.cameras,
                  yolo: _yolo,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  // --- ✅ UPDATED: Dynamic Meal Section (Hierarchical DB Path) ---
  Widget _buildDynamicMealSection(
    String uid,
    String dateKey,
    String category, // 'breakfast', 'lunch', etc.
    String title,
    IconData icon,
  ) {
    // Correct Path: mealslog -> uid -> days -> date -> category
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(dateKey)
          .collection(category)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListTile(title: Text("Error loading data".tr()));
        }

        final docs = snapshot.data?.docs ?? [];
        final items = docs
            .map((d) => _docToFoodItem(d.data() as Map<String, dynamic>))
            .toList();

        final totalCalories = items.fold<int>(
          0,
          (total, item) => total + item.calories,
        );
        final hasItems = items.isNotEmpty;

        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(icon, color: const Color(0xFF37C97D)),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                "$totalCalories ${"kcal".tr()}",
                style: const TextStyle(
                  color: Color(0xFF37C97D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          children: hasItems
              ? items
                    .map(
                      (food) => ListTile(
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        leading: Text(
                          food.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        trailing: Text(
                          "${food.calories} ${"kcal".tr()}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                    .toList()
              : [
                  ListTile(
                    title: Text(
                      "No items logged".tr(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
        );
      },
    );
  }
}
