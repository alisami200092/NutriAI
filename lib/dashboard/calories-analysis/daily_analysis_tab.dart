import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/dashboard/calories-analysis/volumetric_flask.dart';
import 'package:nutriapp/meal_log/all-meals-sections/day_nutrition_service.dart';
import 'package:nutriapp/meal_log/all-meals-sections/full_day_food_report.dart';

class DailyAnalysisPage extends StatelessWidget {
  final DateTime selectedDate;
  final DayNutritionData? data;

  const DailyAnalysisPage({
    super.key,
    required this.selectedDate,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _buildContent(
        context,
        maintenance: 2200.0,
        consumed: data?.totalCals ?? 0.0,
        dailyBudget: data?.targetCals ?? 2000.0,
        weight: 75.0,
        targetWeight: 70.0,
        rate: 0.5,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        double weight = 75.0;
        double targetWeight = 70.0;
        double height = 170.0;
        int age = 25;
        String gender = 'Male';
        double weeklyRate = 0.5;
        double dailyBudget = data?.targetCals ?? 2000.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final uData = snapshot.data!.data() as Map<String, dynamic>;
          weight = (uData['weight'] as num?)?.toDouble() ?? 75.0;
          targetWeight = (uData['targetWeight'] as num?)?.toDouble() ?? weight;
          height = (uData['height'] as num?)?.toDouble() ?? 170.0;
          age = (uData['age'] as num?)?.toInt() ?? 25;
          gender = (uData['gender'] as String?) ?? 'Male';
          weeklyRate = (uData['weightChangePerWeek'] as num?)?.toDouble() ?? 0.5;
          if (dailyBudget <= 0) {
            dailyBudget = (uData['dailyCalorieTarget'] as num?)?.toDouble() ?? 2000.0;
          }
        }

        // TDEE estimate (Mifflin-St Jeor formula)
        final double bmr = (10 * weight) +
            (6.25 * height) -
            (5 * age) +
            (gender.toLowerCase() == 'male' ? 5 : -161);
        final double maintenance = bmr * 1.35;
        final double consumed = data?.totalCals ?? 0.0;

        return _buildContent(
          context,
          maintenance: maintenance > 500 ? maintenance : 2200.0,
          consumed: consumed,
          dailyBudget: dailyBudget > 0 ? dailyBudget : 2000.0,
          weight: weight,
          targetWeight: targetWeight,
          rate: weeklyRate > 0 ? weeklyRate : 0.5,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required double maintenance,
    required double consumed,
    required double dailyBudget,
    required double weight,
    required double targetWeight,
    required double rate,
  }) {
    final double deficit = maintenance - consumed;
    final double requiredDeficit = (maintenance - dailyBudget).clamp(0.0, 1500.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. FLASK SECTION
            _buildFlaskSection(
              context,
              maintenance: maintenance,
              consumed: consumed,
              deficit: deficit,
              requiredDeficit: requiredDeficit,
              dailyBudget: dailyBudget,
            ),

            const SizedBox(height: 20),

            // 2. FORECAST GRAPH
            _buildForecastSection(
              weight: weight,
              targetWeight: targetWeight,
              rate: rate,
            ),

            const SizedBox(height: 20),

            // 3. INSIGHTS
            _buildInsightsSection(context, consumed: consumed, dailyBudget: dailyBudget),
          ],
        ),
      ),
    );
  }

  // --- SECTION 1: FLASK ---
  Widget _buildFlaskSection(
    BuildContext context, {
    required double maintenance,
    required double consumed,
    required double deficit,
    required double requiredDeficit,
    required double dailyBudget,
  }) {
    final double fillPercentage =
        maintenance > 0 ? (consumed / maintenance).clamp(0.0, 1.1) : 0.0;
    final bool isOverflow = consumed > maintenance;
    final double diffFromRequired = deficit - requiredDeficit;
    final bool isOnTarget = deficit >= requiredDeficit && deficit > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Am I on Target?".tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOnTarget
                            ? Colors.green.shade100
                            : (deficit > 0 ? Colors.blue.shade100 : Colors.red.shade100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOnTarget
                            ? "On target:".tr()
                            : (deficit > 0 ? "In Progress:".tr() : "Over Budget:".tr()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isOnTarget
                              ? Colors.green.shade900
                              : (deficit > 0 ? Colors.blue.shade900 : Colors.red.shade900),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: isOnTarget
                        ? " ${"You achieved the recommended calorie deficit! You have exceeded the required deficit by".tr()} "
                        : (deficit > 0
                            ? " ${"You are in deficit! You are".tr()} "
                            : " ${"Your intake is above maintenance by".tr()} "),
                  ),
                  TextSpan(
                    text: isOnTarget
                        ? "${diffFromRequired.toInt().abs()} ${"calories".tr()}"
                        : (deficit > 0
                            ? "${(-diffFromRequired).toInt().abs()} ${"calories".tr()}"
                            : "${(-deficit).toInt()} ${"calories".tr()}"),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOnTarget ? const Color(0xFF37C97D) : const Color(0xFFFF8A33),
                    ),
                  ),
                  TextSpan(
                    text: isOnTarget
                        ? ". ${"High five!".tr()}"
                        : (deficit > 0 ? " ${"away from your target deficit.".tr()}" : " ${"today.".tr()}"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Weight Maintenance Calories".tr(),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${maintenance.toInt()} kcal",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // --- THE FLASK ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Left Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      deficit >= 0 ? "Actual Deficit".tr() : "Actual Surplus".tr(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: deficit >= 0 ? const Color(0xFF37C97D) : Colors.red,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${deficit.toInt().abs()}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: deficit >= 0 ? const Color(0xFF37C97D) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 2. Left Bracket
              SizedBox(
                height: 150,
                width: 25,
                child: CustomPaint(
                  painter: BracketPainter(
                    isLeft: true,
                    color: const Color(0xFF37C97D),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Flask
              VolumetricFlask(
                fillPercentage: fillPercentage,
                height: 190,
                width: 80,
                isOverflow: isOverflow,
              ),

              const SizedBox(width: 8),

              // 4. Right Bracket
              SizedBox(
                height: 150,
                width: 25,
                child: CustomPaint(
                  painter: BracketPainter(
                    isLeft: false,
                    color: Colors.blueGrey,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 5. Right Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Required Deficit".tr(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${requiredDeficit.toInt()}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            "Food Calories".tr(),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            "${consumed.toInt()} kcal",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.rice_bowl, color: Colors.orangeAccent, size: 24),
              SizedBox(width: 12),
              Icon(Icons.bakery_dining, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Icon(Icons.local_florist, color: Colors.pinkAccent, size: 24),
              SizedBox(width: 12),
              Icon(Icons.set_meal, color: Colors.blueAccent, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Calorie & Deficit Breakdown".tr(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _detailRow("Maintenance (TDEE)".tr(), "${maintenance.toInt()} kcal"),
                          _detailRow("Daily Calorie Budget".tr(), "${dailyBudget.toInt()} kcal"),
                          _detailRow("Food Consumed".tr(), "${consumed.toInt()} kcal"),
                          _detailRow("Required Deficit".tr(), "${requiredDeficit.toInt()} kcal"),
                          _detailRow(
                            "Current Deficit".tr(),
                            "${deficit.toInt()} kcal",
                            color: deficit >= 0 ? const Color(0xFF37C97D) : Colors.red,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
                child: Text("Show Deficit Details".tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DayFoodReportPage(selectedDate: selectedDate),
                    ),
                  );
                },
                child: Text("Day Food Report".tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 2: FORECAST GRAPH ---
  Widget _buildForecastSection({
    required double weight,
    required double targetWeight,
    required double rate,
  }) {
    final Color graphColor = const Color(0xFF26C6DA);
    final double weightDiff = (targetWeight - weight).abs();
    int daysToGoal = 60;
    if (rate > 0 && weightDiff > 0) {
      daysToGoal = ((weightDiff / rate) * 7).round();
      if (daysToGoal < 7) daysToGoal = 7;
      if (daysToGoal > 365) daysToGoal = 365;
    }

    final DateTime targetDate = selectedDate.add(Duration(days: daysToGoal));
    final String selectedDateStr = DateFormat("d MMM").format(selectedDate);
    final String targetDateStr = DateFormat("d MMM").format(targetDate);
    final String targetDateLongStr = DateFormat("MMMM d").format(targetDate);

    // Compute dynamic min/max
    final double minW = math.min(weight, targetWeight);
    final double maxW = math.max(weight, targetWeight);
    final double padding = (maxW - minW) * 0.25;
    final double yMin = (minW - (padding > 1 ? padding : 2)).floorToDouble();
    final double yMax = (maxW + (padding > 1 ? padding : 2)).ceilToDouble();

    // 10 spots from start to target
    final List<FlSpot> forecastSpots = [];
    for (int i = 0; i <= 10; i++) {
      final double t = i / 10.0;
      final double currentY = weight + (targetWeight - weight) * t;
      forecastSpots.add(FlSpot(i.toDouble(), currentY));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            "Weight Journey Forecast".tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "Based on {} Calories, your estimated rate is {} kg weekly ({} kg monthly), potentially reaching approximately {} kg by {}.".tr(args: [
              selectedDateStr,
              "$rate",
              (rate * 4.3).toStringAsFixed(1),
              targetWeight.toStringAsFixed(1),
              targetDateLongStr,
            ]),
            style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 40),

          SizedBox(
            height: 220,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return Text(
                                selectedDateStr,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              );
                            }
                            if (value == 10) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Text(
                                  targetDateStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: graphColor, width: 1),
                      ),
                    ),
                    minX: 0,
                    maxX: 11,
                    minY: yMin,
                    maxY: yMax,
                    lineBarsData: [
                      // Forecast Line (Dashed)
                      LineChartBarData(
                        spots: forecastSpots,
                        isCurved: true,
                        color: graphColor,
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) =>
                              spot.x == 0 || spot.x == 10,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: graphColor,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              graphColor.withValues(alpha: 0.2),
                              graphColor.withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Label: Current weight
                Positioned(
                  left: 0,
                  bottom: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${weight.toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Label: Target weight estimate
                Positioned(
                  right: 8,
                  top: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${targetWeight.toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "estimate".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 3: INSIGHTS ---
  Widget _buildInsightsSection(
    BuildContext context, {
    required double consumed,
    required double dailyBudget,
  }) {
    final bool hasMeals = consumed > 0;
    final int itemsCount = data?.totalFoodsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Coach Insights".tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          hasMeals
              ? "You have logged {} food items today. Intake is {} kcal out of your {} kcal target.".tr(args: [
                  "$itemsCount",
                  "${consumed.toInt()}",
                  "${dailyBudget.toInt()}",
                ])
              : "No meals recorded for this date yet. Log breakfast, lunch, or dinner to see daily forecast and calorie deficit.".tr(),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => DayFoodReportPage(selectedDate: selectedDate),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: hasMeals ? const Color(0xFFF37841) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasMeals ? Icons.check : Icons.edit_calendar,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          hasMeals
                              ? "${"Food Log:".tr()} $itemsCount ${"Items Tracked".tr()}"
                              : "Food Log: No Meals Recorded".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

