import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/me/exercise_plan_tab.dart';
import 'package:nutriapp/me/macros_tab.dart';
import 'package:nutriapp/me/nutrients_tab.dart';
import 'package:nutriapp/me/manage_goals_events.dart';
import 'package:nutriapp/me/weight_calories.dart';
import 'package:nutriapp/services/fat_calculator_service.dart';
import 'dart:math' as math;

class MyPlanPage extends StatefulWidget {
  const MyPlanPage({super.key});

  @override
  State<MyPlanPage> createState() => _MyPlanPageState();
}

class _MyPlanPageState extends State<MyPlanPage> with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF37C97D);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching plan data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Plan".tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(text: "Overview".tr()),
            Tab(text: "Weight & Calories".tr()),
            Tab(text: "Macros".tr()),
            Tab(text: "Nutrients".tr()),
            Tab(text: "Exercise Plan".tr()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context),
                WeightAndCaloriesTab(userData: _userData),
                MacrosTab(userData: _userData),
                const NutrientsTab(),
                const ExercisePlanTab(),
              ],
            ),
    );
  }

  // --- OVERVIEW TAB CONTENT ---
  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildJourneyCard(),
          const SizedBox(height: 16),
          _buildMacrosSnapshotCard(),
          const SizedBox(height: 16),
          _buildInsightsCard(),
          const SizedBox(height: 16),
          _buildHabitsAndDietCard(),
          const SizedBox(height: 16),
          _buildExerciseSettingsCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 1. Journey Card (Top Green Card)
  Widget _buildJourneyCard() {
    final double weight = ((_userData?['weight'] ?? 75.0) as num).toDouble();
    final double targetWeight = ((_userData?['targetWeight'] ?? weight) as num).toDouble();
    final double weightDiff = (targetWeight - weight).abs();
    final String goalType = _userData?['dietaryGoal'] ?? "Healthy Living";
    final double dailyBudget = ((_userData?['dailyCalorieTarget'] ?? 1800.0) as num).toDouble();
    final double weightChangePerWeek = ((_userData?['weightChangePerWeek'] ?? 0.5) as num).toDouble();

    // Days calculation based on goal
    int daysLeft = 60;
    if (weightChangePerWeek > 0 && weightDiff > 0) {
      daysLeft = ((weightDiff / weightChangePerWeek) * 7).round();
      if (daysLeft < 7) daysLeft = 7;
    }

    // TDEE estimate (Mifflin-St Jeor)
    final double height = ((_userData?['height'] ?? 170.0) as num).toDouble();
    final int age = ((_userData?['age'] ?? 25) as num).toInt();
    final String gender = _userData?['gender'] ?? "Male";
    final double bmr = (10 * weight) + (6.25 * height) - (5 * age) + (gender.toLowerCase() == 'male' ? 5 : -161);
    final double tdee = bmr * 1.35;
    final int calDiff = (dailyBudget - tdee).round();

    // Target Date
    DateTime targetDate = DateTime.now().add(Duration(days: daysLeft));
    if (_userData?['eventDate'] != null) {
      try {
        final dynamic rawDate = _userData!['eventDate'];
        if (rawDate is Timestamp) {
          targetDate = rawDate.toDate();
        }
      } catch (_) {}
    }
    final String targetDateStr = DateFormat("d MMM").format(targetDate);

    // Calculate achieved progress
    final double startWeight = ((_userData?['startingWeight'] ?? weight) as num).toDouble();
    double achievedKg = (startWeight - weight).abs();
    double progressRatio = weightDiff > 0 ? (achievedKg / (achievedKg + weightDiff)).clamp(0.05, 1.0) : 1.0;

    String journeyTitle = "Your Journey: $goalType";
    if (weightDiff > 0.1) {
      final String action = targetWeight < weight ? "Lose" : "Gain";
      journeyTitle = "Your Journey: $action ${weightDiff.toStringAsFixed(1)} kg in $daysLeft Days";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  journeyTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageWeightPage(
                        currentWeight: weight,
                        targetWeight: targetWeight,
                        weightChangePerWeek: weightChangePerWeek,
                        activityLevel: _userData?['activityLevel'] ?? "Moderately Active",
                      ),
                    ),
                  );
                  if (updated == true) {
                    _fetchUserData();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "Edit Goal",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progressRatio,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade300,
                      color: _primaryColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Target",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${targetWeight.toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Now: ${weight.toStringAsFixed(1)}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Right side text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${dailyBudget.toInt()} kcal",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${targetWeight.toStringAsFixed(0)} kg",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "Today's Budget",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      calDiff < 0
                          ? "This is ${calDiff.abs()} fewer cals than your Maintenance of ${tdee.toInt()} kcal"
                          : "This is ${calDiff.abs()} surplus cals above Maintenance of ${tdee.toInt()} kcal",
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Target Date: $targetDateStr",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Macros Snapshot Card
  Widget _buildMacrosSnapshotCard() {
    final double dailyBudget = ((_userData?['dailyCalorieTarget'] ?? 1800.0) as num).toDouble();
    final double weightKg = ((_userData?['weight'] ?? 70.0) as num).toDouble();
    final String goal = _userData?['dietaryGoal'] ?? "Healthy Living";
    final MacroTargets macros = FatCalculatorService.calculateMacroTargets(
      weightKg: weightKg,
      calorieBudget: dailyBudget.toInt(),
      goal: goal,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.pie_chart, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Macros Snapshot",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _tabController.animateTo(2),
                child: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              // Simple Custom Pie Chart Representation
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: SimplePieChartPainter(
                    carbPercent: macros.carbPercent / 100.0,
                    proteinPercent: macros.proteinPercent / 100.0,
                    fatPercent: macros.fatPercent / 100.0,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Carbs: ${macros.carbPercent.toStringAsFixed(0)}%"),
                  Text("Protein: ${macros.proteinPercent.toStringAsFixed(0)}%"),
                  Text("Fat: ${macros.fatPercent.toStringAsFixed(0)}%"),
                ],
              ),
              const Spacer(),
              // Right Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "T. Carbs  ${macros.carbGrams.toStringAsFixed(0)}g",
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text("Protein ${macros.proteinGrams.toStringAsFixed(0)}g"),
                  Text("Fat ${macros.fatGrams.toStringAsFixed(0)}g", style: const TextStyle(color: Colors.orange)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _tabController.animateTo(2),
                    child: Text(
                      "View & Adjust",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Insights Card
  Widget _buildInsightsCard() {
    final String dietType = _userData?['dietType'] ?? "Standard";
    final double weight = ((_userData?['weight'] ?? 75.0) as num).toDouble();
    final double targetWeight = ((_userData?['targetWeight'] ?? weight) as num).toDouble();

    String insight = "You're consistently tracking meals! Keep staying hydrated.";
    if (weight > targetWeight) {
      insight = "Tip for $dietType: prioritize lean protein and fiber to stay full while cutting calories.";
    } else if (weight < targetWeight) {
      insight = "Tip for $dietType: add healthy fats (nuts, seeds, oils) to hit your surplus comfortably.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Your Personalized Insights",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "View All Insights",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Habits & Diet List
  Widget _buildHabitsAndDietCard() {
    final String dietType = _userData?['dietPreference'] ?? _userData?['dietType'] ?? "Balanced";
    final dynamic rawRestrictions = _userData?['dietaryRestrictions'] ?? _userData?['restrictions'];
    String restrictionsStr = "None";
    if (rawRestrictions is List && rawRestrictions.isNotEmpty) {
      restrictionsStr = rawRestrictions.join(", ");
    } else if (rawRestrictions is String && rawRestrictions.trim().isNotEmpty) {
      restrictionsStr = rawRestrictions;
    }

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildListRow(
            Icons.eco_outlined,
            "My Habits & Strategies",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Habits & strategies aligned with your daily meal schedule.")),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListRow(
            Icons.restaurant_outlined,
            "My Diet: $dietType",
            onTap: () => _showChangeDietDialog(dietType),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListRow(
            Icons.no_food_outlined,
            "Dietary Restrictions: $restrictionsStr",
            onTap: () => _showChangeRestrictionsDialog(restrictionsStr),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.grey,
            ),
            title: const Text(
              "Nutrition Strategy",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              "Balanced",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _tabController.animateTo(2),
          ),
        ],
      ),
    );
  }

  void _showChangeDietDialog(String currentDiet) {
    final List<String> diets = [
      "Pakistani",
      "Indian",
      "High Protein",
      "Balanced",
      "Mediterranean",
      "Keto",
      "Vegetarian",
      "Vegan",
      "Low Carb",
      "Paleo",
    ];
    String selected = diets.contains(currentDiet) ? currentDiet : "Balanced";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Select Diet Type"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: diets
                  .map(
                    (d) => RadioListTile<String>(
                      title: Text(d),
                      value: d,
                      groupValue: selected,
                      activeColor: _primaryColor,
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selected = val);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('UserProfiles').doc(user.uid).update({
                    'dietPreference': selected,
                    'dietType': selected,
                  });
                  await _fetchUserData();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRestrictionsDialog(String currentRestrictions) {
    final List<String> available = [
      "Vegetarian",
      "Vegan",
      "Dairy-Free",
      "Gluten-Free",
      "Nut-Free",
      "Halal",
      "Kosher",
      "Low Sodium",
    ];

    List<String> selectedList = currentRestrictions
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Dietary Restrictions"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((item) {
                final bool isSelected = selectedList.contains(item);
                return CheckboxListTile(
                  title: Text(item),
                  value: isSelected,
                  activeColor: _primaryColor,
                  onChanged: (bool? val) {
                    setDlgState(() {
                      if (val == true) {
                        if (!selectedList.contains(item)) selectedList.add(item);
                      } else {
                        selectedList.remove(item);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final String joined = selectedList.isEmpty ? "None" : selectedList.join(", ");
                  await FirebaseFirestore.instance.collection('UserProfiles').doc(user.uid).update({
                    'dietaryRestrictions': selectedList,
                    'restrictions': joined,
                  });
                  await _fetchUserData();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Exercise Settings Card
  Widget _buildExerciseSettingsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.green,
                size: 20,
              ),
            ),
            title: const Text(
              "Exercise Calories:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: true,
            activeThumbColor: _primaryColor,
            onChanged: (val) {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 70.0, bottom: 12, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLinkText("Target Weight History"),
                const SizedBox(height: 4),
                _buildLinkText("Sources of Information"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildLinkText(String text) {
    return Row(
      children: [
        Text(text, style: TextStyle(color: Colors.blue.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildListRow(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// --- Custom Painter for that specific Pie Chart look ---
class SimplePieChartPainter extends CustomPainter {
  final double carbPercent;
  final double proteinPercent;
  final double fatPercent;

  SimplePieChartPainter({
    this.carbPercent = 0.50,
    this.proteinPercent = 0.25,
    this.fatPercent = 0.25,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Green Section (Carbs)
    paint.color = const Color(0xFF00C853);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * carbPercent, true, paint);

    // 2. Yellow Section (Fat)
    paint.color = const Color(0xFFFFC107);
    canvas.drawArc(
      rect,
      -math.pi / 2 + (2 * math.pi * carbPercent),
      2 * math.pi * fatPercent,
      true,
      paint,
    );

    // 3. Purple Section (Protein)
    paint.color = const Color(0xFF9575CD);
    canvas.drawArc(
      rect,
      -math.pi / 2 + (2 * math.pi * (carbPercent + fatPercent)),
      2 * math.pi * proteinPercent,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SimplePieChartPainter oldDelegate) =>
      oldDelegate.carbPercent != carbPercent ||
      oldDelegate.proteinPercent != proteinPercent ||
      oldDelegate.fatPercent != fatPercent;
}
