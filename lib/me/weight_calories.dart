import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutriapp/me/manage_goals_events.dart';
import 'package:nutriapp/me/personal_info.dart';

class WeightAndCaloriesTab extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const WeightAndCaloriesTab({super.key, this.userData});

  final Color _primaryGreen = const Color(0xFF37C97D);
  final Color _blueLink = const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    final double weight = ((userData?['weight'] ?? 75.0) as num).toDouble();
    final double targetWeight = ((userData?['targetWeight'] ?? weight) as num).toDouble();
    final double weightDiff = (targetWeight - weight).abs();
    final String goalType = userData?['dietaryGoal'] ?? "Healthy Living";
    final double dailyBudget = ((userData?['dailyCalorieTarget'] ?? 1800.0) as num).toDouble();
    final double weightChangePerWeek = ((userData?['weightChangePerWeek'] ?? 0.5) as num).toDouble();

    int daysLeft = 60;
    if (weightChangePerWeek > 0 && weightDiff > 0) {
      daysLeft = ((weightDiff / weightChangePerWeek) * 7).round();
      if (daysLeft < 7) daysLeft = 7;
    }

    // TDEE estimate (Mifflin-St Jeor)
    final double height = ((userData?['height'] ?? 170.0) as num).toDouble();
    final int age = ((userData?['age'] ?? 25) as num).toInt();
    final String gender = userData?['gender'] ?? "Male";
    final double bmr = (10 * weight) + (6.25 * height) - (5 * age) + (gender.toLowerCase() == 'male' ? 5 : -161);
    final double tdee = bmr * 1.35;
    final int calDiff = (dailyBudget - tdee).round();

    DateTime targetDate = DateTime.now().add(Duration(days: daysLeft));
    if (userData?['eventDate'] != null) {
      try {
        final dynamic rawDate = userData!['eventDate'];
        if (rawDate is Timestamp) {
          targetDate = rawDate.toDate();
        }
      } catch (_) {}
    }
    final String targetDateStr = DateFormat("d MMM").format(targetDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalCard(context, weight, targetWeight, weightDiff, daysLeft, dailyBudget, goalType, weightChangePerWeek),
          const SizedBox(height: 16),
          _buildWeightCards(context, weight, targetWeight, targetDateStr, weightChangePerWeek),
          const SizedBox(height: 16),
          _buildPriorityDropdown(),
          const SizedBox(height: 16),
          _buildDailyCaloriePlanningCard(dailyBudget, targetDateStr, weightChangePerWeek, tdee, calDiff),
          const SizedBox(height: 24),
          _buildPlanningToolsSection(context, gender, height, age),
          const SizedBox(height: 24),
          _buildWeightProgressSection(weight, targetWeight, weightDiff),
          const SizedBox(height: 24),
          _buildExampleFoodsSection(), // Updated with Images
          const SizedBox(height: 24),
          _buildAboutCaloriesSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- EXISTING CARDS ---

  Widget _buildGoalCard(
    BuildContext context,
    double weight,
    double targetWeight,
    double weightDiff,
    int daysLeft,
    double dailyBudget,
    String goalType,
    double weightChangePerWeek,
  ) {
    String action = "maintain weight";
    if (targetWeight < weight) {
      action = "lose ${weightDiff.toStringAsFixed(1)} kg in $daysLeft days";
    } else if (targetWeight > weight) {
      action = "gain ${weightDiff.toStringAsFixed(1)} kg in $daysLeft days";
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageWeightPage(
              currentWeight: weight,
              targetWeight: targetWeight,
              weightChangePerWeek: weightChangePerWeek,
              activityLevel: userData?['activityLevel'] ?? "Moderately Active",
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Goal",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.edit_outlined, size: 18, color: _primaryGreen),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "I plan to $action\nby eating around ${dailyBudget.toInt()} cals",
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.65,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCards(
    BuildContext context,
    double weight,
    double targetWeight,
    String targetDateStr,
    double weightChangePerWeek,
  ) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageWeightPage(
                    currentWeight: weight,
                    targetWeight: targetWeight,
                    weightChangePerWeek: weightChangePerWeek,
                    activityLevel: userData?['activityLevel'] ?? "Moderately Active",
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Current Weight:",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${weight.toStringAsFixed(1)} kg",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap to update",
                    style: TextStyle(color: Colors.blue.shade50, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageWeightPage(
                    currentWeight: weight,
                    targetWeight: targetWeight,
                    weightChangePerWeek: weightChangePerWeek,
                    activityLevel: userData?['activityLevel'] ?? "Moderately Active",
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Target Weight:",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${targetWeight.toStringAsFixed(1)} kg",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Target Date: $targetDateStr",
                    style: TextStyle(color: Colors.green.shade50, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _whiteCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                "My Priority: ",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                "Fixed Budget",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          Icon(Icons.keyboard_arrow_down, color: _primaryGreen),
        ],
      ),
    );
  }

  Widget _buildDailyCaloriePlanningCard(
    double dailyBudget,
    String targetDateStr,
    double weightChangePerWeek,
    double tdee,
    int calDiff,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daily Calorie Planning",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: _primaryGreen,
                      backgroundColor: Colors.grey.shade100,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${dailyBudget.toInt()}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "kcal",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletText("Target Date:\n$targetDateStr"),
                    const SizedBox(height: 12),
                    _buildBulletText("Current Weekly Rate:\n${weightChangePerWeek.toStringAsFixed(2)} kg/week"),
                    const SizedBox(height: 12),
                    _buildBulletText("Weight Maintenance:\n${tdee.toInt()} cals"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            calDiff < 0
                ? "Planned daily deficit ${calDiff.abs()} cals below weight maintenance (${tdee.toInt()} kcal)."
                : "Planned daily surplus ${calDiff.abs()} cals above weight maintenance (${tdee.toInt()} kcal).",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningToolsSection(
    BuildContext context,
    String gender,
    double height,
    int age,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12),
          child: Text(
            "Planning Tools",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: _whiteCardDecoration(),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.drive_eta, color: Colors.blue.shade300),
                ),
                title: const Text(
                  "Autopilot",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Automatically adjust your Food Calorie Budget and macro targets",
                ),
                trailing: Text(
                  "On",
                  style: TextStyle(
                    color: _primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 70,
                endIndent: 0,
                color: Colors.grey.shade200,
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoPage(),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.cyan.shade50,
                  child: Icon(Icons.person, color: Colors.cyan.shade300),
                ),
                title: const Text(
                  "Personal Info",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text("$gender, ${height.toStringAsFixed(0)} cm, $age years old"),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightProgressSection(
    double weight,
    double targetWeight,
    double weightDiff,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weight Progress",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            weight > targetWeight
                ? "Target: -${weightDiff.toStringAsFixed(1)} kg"
                : "Target: +${weightDiff.toStringAsFixed(1)} kg",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "From ${weight.toStringAsFixed(1)} kg to ${targetWeight.toStringAsFixed(1)} kg",
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton("Weight Chart", Icons.bar_chart),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildActionButton("Fresh Start", Icons.refresh)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: _primaryGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Fresh Start allows you to adjust starting values and recalibrate your targets.",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleFoodsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Calories in Example Foods",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Ensure you have these images in your assets folder
              _buildFoodItem(
                "assets/images/olive-oil.png",
                "Olive oil",
                "1 tbsp",
                "~119 cals",
              ),
              _buildFoodItem(
                "assets/images/orange-juice.png",
                "Orange juice",
                "8 fl oz",
                "~112 cals",
              ),
              _buildFoodItem(
                "assets/images/ice-cream.png",
                "Ice cream",
                "soft-serve cone",
                "~168 cals",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCaloriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12),
          child: Text(
            "About Calories",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          // Text directly on background, no card needed here per request/style
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "1,600 cals recommended according to your plan.",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Calories measure the amount of energy we consume from foods and beverages and the amount we burn from resting metabolism, digesting and processing food, and physical activity. To lose weight, calorie intake must be less than calories burned. To gain weight, calorie intake must be more than calories burned. To maintain weight, calorie intake needs to match calories burned.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "If you want to see food and exercise energy in kilojoules, change Energy Units settings.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Read Article",
                    style: TextStyle(
                      color: _blueLink,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.grain, size: 18, color: _blueLink),
                      const SizedBox(width: 4),
                      Text(
                        "Related Nutrients",
                        style: TextStyle(
                          color: _blueLink,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildBulletText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Updated to accept image asset path
  Widget _buildFoodItem(
    String assetPath,
    String name,
    String amount,
    String cals,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 60, // Adjust height as needed
          width: 60,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          cals,
          style: TextStyle(
            color: _primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
