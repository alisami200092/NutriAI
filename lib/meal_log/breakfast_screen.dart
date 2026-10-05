import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Auth
import 'package:intl/intl.dart';
import 'package:nutriapp/meal_log/nutrient_summary.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/meal_log/camera_screen.dart';
import 'package:nutriapp/meal_log/manual-meal-log/manual_search_page.dart';

class FoodItem {
  final String name;
  final String emoji;
  final int calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double satFat;
  final double salt;
  final double calcium;

  FoodItem({
    required this.name,
    required this.emoji,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.satFat,
    required this.salt,
    required this.calcium,
  });
}

class BreakfastScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const BreakfastScreen({
    super.key,
    required this.selectedDate,
    required this.cameras,
    required this.yolo,
  });

  @override
  State<BreakfastScreen> createState() => _BreakfastScreenState();
}

class _BreakfastScreenState extends State<BreakfastScreen> {
  late DateTime date;

  @override
  void initState() {
    super.initState();
    date = widget.selectedDate;
  }

  void _goToPreviousDay() {
    setState(() => date = date.subtract(const Duration(days: 1)));
  }

  void _goToNextDay() {
    setState(() => date = date.add(const Duration(days: 1)));
  }

  void _goToManualSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualMealSearchPage(
          mealCategory: 'breakfast',
          logDate: date,
          cameras: widget.cameras,
          yolo: widget.yolo,
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    if (widget.cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No camera found on device")),
      );
      return;
    }

    // Await the result from the camera screen
    final scannedFood = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CameraScreen(cameras: widget.cameras, yolo: widget.yolo),
        fullscreenDialog: true,
      ),
    );

    // If data is returned, save it
    if (scannedFood != null && scannedFood is Map<String, dynamic>) {
      // ✅ FIX: Give the Android Camera 500 milliseconds to completely
      // shut down its background native processes before we hit the database.
      // This prevents the "Broken pipe" crash!
      await Future.delayed(const Duration(milliseconds: 500));

      await _saveDetectedFood(scannedFood);
    }
  }

  // NEW METHOD TO SAVE TO FIRESTORE
  Future<void> _saveDetectedFood(Map<String, dynamic> foodData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save meals.")),
      );
      return;
    }

    final uid = user.uid;
    final dateKey = _dateKey(date);
    const category = 'breakfast'; // SPECIFIC TO THIS SCREEN

    double getVal(String key) =>
        (foodData[key] is num) ? (foodData[key] as num).toDouble() : 0.0;

    double calPer100 = getVal('caloriesPer100g');
    if (calPer100 == 0.0) calPer100 = getVal('calories');

    double carbsPer100 = getVal('carbsPer100g');
    if (carbsPer100 == 0.0) carbsPer100 = getVal('carbs');

    double proteinPer100 = getVal('proteinPer100g');
    if (proteinPer100 == 0.0) proteinPer100 = getVal('protein');

    double fatPer100 = getVal('fatPer100g');
    if (fatPer100 == 0.0) fatPer100 = getVal('fat');

    double grams = 100.0;
    if (foodData['servingSizes'] is List &&
        (foodData['servingSizes'] as List).isNotEmpty) {
      final firstServing = (foodData['servingSizes'] as List).first;
      if (firstServing is Map && firstServing['grams'] is num) {
        grams = (firstServing['grams'] as num).toDouble();
      }
    }

    double totalCalories = (calPer100 / 100.0) * grams;
    double totalCarbs = (carbsPer100 / 100.0) * grams;
    double totalProtein = (proteinPer100 / 100.0) * grams;
    double totalFat = (fatPer100 / 100.0) * grams;
    double totalFiber = (getVal('fiber') / 100.0) * grams;
    double totalSatFat = (getVal('satFat') / 100.0) * grams;
    double totalSalt = (getVal('salt') / 100.0) * grams;
    double totalCalcium = (getVal('calcium') / 100.0) * grams;

    final docData = {
      'name': foodData['name'] ?? 'Unknown',
      'category': category,
      'date': dateKey,
      'timestamp': FieldValue.serverTimestamp(),
      'calories': totalCalories.round(),
      'estCalories': totalCalories.round(),
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
      'fiber': totalFiber,
      'satFat': totalSatFat,
      'salt': totalSalt,
      'calcium': totalCalcium,
      'caloriesPer100g': calPer100,
      'carbsPer100g': carbsPer100,
      'proteinPer100g': proteinPer100,
      'fatPer100g': fatPer100,
      'loggedServing': {
        'name': foodData['name'] ?? 'Unknown',
        'amount': grams,
        'calculatedGrams': grams,
        'unit': "g",
        'protein': totalProtein,
        'proteinPer100g': proteinPer100,
      },
    };

    try {
      await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(dateKey)
          .collection(category)
          .add(docData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${foodData['name']} logged to $category!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save meal: $e")));
      }
    }
  }

  FoodItem _docToFoodItem(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Food').toString();

    double getVal(String key) {
      if (data[key] is num) return (data[key] as num).toDouble();
      return 0.0;
    }

    int calories = 0;
    double carbs = getVal('carbs');
    double protein = getVal('protein');
    double fat = getVal('fat');
    double fiber = getVal('fiber');
    double satFat = getVal('satFat');
    double salt = getVal('salt');
    double calcium = getVal('calcium');

    if (data.containsKey('estCalories') && data['estCalories'] is num) {
      calories = (data['estCalories'] as num).toInt();
    } else {
      calories = getVal('calories').toInt();
    }

    return FoodItem(
      name: name,
      emoji: _emojiForLabel(name),
      calories: calories,
      carbs: carbs,
      protein: protein,
      fat: fat,
      fiber: fiber,
      satFat: satFat,
      salt: salt,
      calcium: calcium,
    );
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
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

    if (diffDays == 0) return "Today";
    if (diffDays == 1) return "Tomorrow, ${d.day} ${months[d.month - 1]}";
    if (diffDays == -1) return "Yesterday, ${d.day} ${months[d.month - 1]}";
    return "${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}";
  }

  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _copyFromYesterday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final yesterday = date.subtract(const Duration(days: 1));
    final yesterdayKey = _dateKey(yesterday);
    final todayKey = _dateKey(date);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(yesterdayKey)
          .collection('breakfast')
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No breakfast meals found on yesterday (${DateFormat('d MMM').format(yesterday)}) to copy.",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final targetCollection = FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(todayKey)
          .collection('breakfast');

      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['date'] = todayKey;
        data['timestamp'] = FieldValue.serverTimestamp();
        final newDocRef = targetCollection.doc();
        batch.set(newDocRef, data);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Copied ${snap.docs.length} breakfast food(s) from yesterday!",
            ),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to copy meals: $e")),
        );
      }
    }
  }

  Future<void> _copyFromCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date.subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final fromDateKey = _dateKey(picked);
    final todayKey = _dateKey(date);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(fromDateKey)
          .collection('breakfast')
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No breakfast foods logged on ${DateFormat('d MMM yyyy').format(picked)}.",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final targetCollection = FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(todayKey)
          .collection('breakfast');

      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['date'] = todayKey;
        data['timestamp'] = FieldValue.serverTimestamp();
        final newDocRef = targetCollection.doc();
        batch.set(newDocRef, data);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Copied ${snap.docs.length} food(s) from ${DateFormat('d MMM').format(picked)}!",
            ),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to copy meals: $e")),
        );
      }
    }
  }

  Future<void> _clearAllMealFoods() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Breakfast Foods?"),
        content: const Text(
          "Are you sure you want to remove all logged breakfast items for this day?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final todayKey = _dateKey(date);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(todayKey)
          .collection('breakfast')
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No meals to clear.")),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cleared all breakfast foods for this day."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to clear meals: $e")),
        );
      }
    }
  }

  void _showNutritionTipsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Color(0xFF37C97D)),
            SizedBox(width: 8),
            Text(
              "Breakfast AI Guide",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🍳 High Protein Start:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              "Aim for 20-30g protein (boiled eggs, omelette, or daal) to stabilize blood sugar and prevent midday cravings.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              "🌾 Sustained Energy:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              "Pair with whole wheat roti, oatmeal, or fresh fruit for rich prebiotic fiber and gut health.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              "💧 Morning Hydration:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              "Drink a glass of water before tea or chai to awaken metabolism and improve digestion.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37C97D),
            ),
            child: const Text("Got it!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(date);

    // ✅ 1. Get UID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Breakfast")),
        body: const Center(child: Text("Please log in to view meals.")),
      );
    }
    final uid = user.uid;

    // ✅ 2. NEW PATH: mealslog -> uid -> days -> dateKey -> breakfast
    final Stream<QuerySnapshot> breakfastStream = FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(dateKey)
        .collection('breakfast')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF37C97D),
        title: const Text(
          "Breakfast",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 22),
            onPressed: _goToManualSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'copy_yesterday') {
                _copyFromYesterday();
              } else if (val == 'copy_previous') {
                _copyFromCustomDate();
              } else if (val == 'clear_all') {
                _clearAllMealFoods();
              } else if (val == 'tips') {
                _showNutritionTipsDialog();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'copy_yesterday',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text("Copy From Yesterday"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_previous',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text("Copy From Specific Date..."),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("Clear All Breakfast Foods"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'tips',
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text("Breakfast AI Tips"),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: _goToPreviousDay,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dateLabel(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: _goToNextDay,
                ),
              ],
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: breakfastStream,
        builder: (context, snapshot) {
          final hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          final docs = snapshot.data?.docs ?? [];
          final items = docs
              .map((d) => _docToFoodItem(d.data() as Map<String, dynamic>))
              .toList();

          final totalCalories = items.fold<int>(0, (s, it) => s + it.calories);
          final totalCarbs = items.fold<double>(0, (s, it) => s + it.carbs);
          final totalProtein = items.fold<double>(0, (s, it) => s + it.protein);
          final totalFat = items.fold<double>(0, (s, it) => s + it.fat);
          final totalFiber = items.fold<double>(0, (s, it) => s + it.fiber);
          final totalSatFat = items.fold<double>(0, (s, it) => s + it.satFat);
          final totalSalt = items.fold<double>(0, (s, it) => s + it.salt);
          final totalCalcium = items.fold<double>(0, (s, it) => s + it.calcium);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: _goToManualSearch,
                                child: _actionText("Find and Log Food"),
                              ),
                              const SizedBox(height: 12),
                              if (!hasData) ...[
                                GestureDetector(
                                  onTap: _copyFromYesterday,
                                  child: _actionText(
                                    "Copy From Yesterday’s Breakfast",
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              GestureDetector(
                                onTap: _openCamera,
                                child: _actionText("AI Meal Scan"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasData)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final food = items[i];
                            return ListTile(
                              leading: Text(
                                food.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                food.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "Carbs: ${food.carbs.toInt()}g, Prot: ${food.protein.toInt()}g, Fat: ${food.fat.toInt()}g",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Text(
                                "${food.calories} kcal",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: Text("No items logged yet")),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                if (hasData)
                  NutrientSummarySection(
                    totalCalories: totalCalories,
                    totalCarbs: totalCarbs,
                    totalProtein: totalProtein,
                    totalFat: totalFat,
                    totalFiber: totalFiber,
                    totalSatFat: totalSatFat,
                    totalSalt: totalSalt,
                    totalCalcium: totalCalcium,
                  ),
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      TextButton(onPressed: null, child: Text("Help")),
                      TextButton(onPressed: null, child: Text("My Foods")),
                      TextButton(onPressed: null, child: Text("Custom")),
                      TextButton(onPressed: null, child: Text("Quick")),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 45,
            width: 45,
            child: FloatingActionButton(
              heroTag: "aiScan",
              backgroundColor: Colors.blue,
              onPressed: _openCamera,
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: "addMeal",
            backgroundColor: Colors.blue,
            onPressed: _goToManualSearch,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _actionText(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      textAlign: TextAlign.right,
    );
  }

  String _emojiForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('bread')) return '🍞';
    return '🍽️';
  }
}
