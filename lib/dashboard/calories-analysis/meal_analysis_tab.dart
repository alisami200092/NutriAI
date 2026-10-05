import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/meal_log/all-meals-sections/day_nutrition_service.dart';
import 'package:nutriapp/meal_log/all-meals-sections/full_day_food_report.dart';

class MealAnalysisTab extends StatefulWidget {
  final DateTime selectedDate;
  final DayNutritionData? data;

  const MealAnalysisTab({
    super.key,
    required this.selectedDate,
    this.data,
  });

  @override
  State<MealAnalysisTab> createState() => _MealAnalysisTabState();
}

class _MealAnalysisTabState extends State<MealAnalysisTab> {
  final Color _tealColor = const Color(0xFF1ABC9C);
  final Color _orangeColor = const Color(0xFFFF8A33);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  String _selectedFilter = "Daily";

  @override
  Widget build(BuildContext context) {
    final d = widget.data ?? DayNutritionData.empty(widget.selectedDate);

    return Container(
      color: _backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateNavigator(),
            const SizedBox(height: 16),
            _buildFilterToggle(),
            const SizedBox(height: 20),
            _buildRecentHighCalorieCard(d),
            const SizedBox(height: 16),
            _buildCalorieBreakdownCard(d),
            const SizedBox(height: 24),
            _buildDetailedButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. Date Navigator ---
  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('EEEE, d MMM yyyy').format(widget.selectedDate),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // --- 2. Filter Toggle ---
  Widget _buildFilterToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterOption("Daily"),
          _buildFilterOption("Weekly"),
          _buildFilterOption("Monthly"),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _tealColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.tr(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // --- 3. Recent High-Calorie Meals Card ---
  Widget _buildRecentHighCalorieCard(DayNutritionData d) {
    // Collect calories per meal category
    final Map<String, double> catCals = {};
    for (String cat in ['breakfast', 'lunch', 'dinner', 'snack']) {
      final items = d.itemsByCategory[cat] ?? [];
      double total = 0;
      for (var item in items) {
        if (item.containsKey('estCalories') && item['estCalories'] is num) {
          total += (item['estCalories'] as num).toDouble();
        } else if (item.containsKey('calories') && item['calories'] is num) {
          total += (item['calories'] as num).toDouble();
        } else {
          total += DayNutritionService.calculateMacroValue(item, 'caloriesPer100g');
        }
      }
      catCals[cat] = total;
    }

    final activeMeals = catCals.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dateStr = DateFormat('d MMM').format(widget.selectedDate);

    return Container(
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Highest Calorie Meals Today".tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (activeMeals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  "No meals logged yet today".tr(),
                  style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...activeMeals.map((meal) {
              final cat = meal.key;
              final cals = meal.value.round();
              IconData icon = Icons.wb_sunny_outlined;
              String title = "Breakfast".tr();
              if (cat == 'lunch') {
                icon = Icons.restaurant;
                title = "Lunch".tr();
              } else if (cat == 'dinner') {
                icon = Icons.bedtime;
                title = "Dinner".tr();
              } else if (cat == 'snack') {
                icon = Icons.cookie_outlined;
                title = "Snacks".tr();
              }

              return Column(
                children: [
                  _buildHighCalorieItem(
                    icon: icon,
                    title: title,
                    date: "${"on".tr()} $dateStr",
                    calories: cals.toString(),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200, indent: 60),
                ],
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHighCalorieItem({
    required IconData icon,
    required String title,
    required String date,
    required String calories,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF1A237E), size: 28),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: " $date",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
      trailing: Text(
        "$calories ${"cals".tr()}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  // --- 4. Calorie Breakdown Card ---
  Widget _buildCalorieBreakdownCard(DayNutritionData d) {
    double bCals = 0;
    double lCals = 0;
    double dCals = 0;
    double sCals = 0;

    for (var i in (d.itemsByCategory['breakfast'] ?? [])) {
      bCals += (i['estCalories'] ?? i['calories'] ?? 0) as num;
    }
    for (var i in (d.itemsByCategory['lunch'] ?? [])) {
      lCals += (i['estCalories'] ?? i['calories'] ?? 0) as num;
    }
    for (var i in (d.itemsByCategory['dinner'] ?? [])) {
      dCals += (i['estCalories'] ?? i['calories'] ?? 0) as num;
    }
    for (var i in (d.itemsByCategory['snack'] ?? [])) {
      sCals += (i['estCalories'] ?? i['calories'] ?? 0) as num;
    }

    final double total = d.totalCals > 0 ? d.totalCals : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calorie Breakdown by Type".tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem(
            icon: Icons.wb_sunny_outlined,
            iconColor: Colors.orange,
            title: "Breakfast".tr(),
            calsLogged: bCals.round(),
            percent: bCals / total,
            barColor: Colors.green.shade300,
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem(
            icon: Icons.restaurant,
            iconColor: Colors.orange,
            title: "Lunch".tr(),
            calsLogged: lCals.round(),
            percent: lCals / total,
            barColor: Colors.lightGreen,
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem(
            icon: Icons.bedtime,
            iconColor: Colors.indigo,
            title: "Dinner".tr(),
            calsLogged: dCals.round(),
            percent: dCals / total,
            barColor: Colors.teal,
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem(
            icon: Icons.cookie_outlined,
            iconColor: Colors.brown,
            title: "Snacks".tr(),
            calsLogged: sCals.round(),
            percent: sCals / total,
            barColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int calsLogged,
    required double percent,
    required Color barColor,
  }) {
    final int pct = (percent * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            Text(
              "$calsLogged ${"cals".tr()} ($pct%)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            color: barColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayFoodReportPage(selectedDate: widget.selectedDate),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _orangeColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 2,
        ),
        child: Text(
          "Open Day Food Report".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
