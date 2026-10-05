import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/dashboard/calories-analysis/cals_from_nutrients_tab.dart';
import 'package:nutriapp/dashboard/calories-analysis/daily_analysis_tab.dart';
import 'package:nutriapp/dashboard/calories-analysis/meal_analysis_tab.dart';
import 'package:nutriapp/dashboard/calories-analysis/target_weight_analysis.dart';
import 'package:nutriapp/dashboard/dashboard_service.dart';
import 'package:nutriapp/me/personal_info.dart';
import 'package:nutriapp/meal_log/all-meals-sections/day_nutrition_service.dart';
import 'package:nutriapp/meal_log/all-meals-sections/full_day_food_report.dart';

class SummaryFoodAnalysis extends StatefulWidget {
  final DateTime selectedDate;

  const SummaryFoodAnalysis({super.key, required this.selectedDate});

  @override
  State<SummaryFoodAnalysis> createState() => _SummaryFoodAnalysisState();
}

class _SummaryFoodAnalysisState extends State<SummaryFoodAnalysis> {
  final Color _primaryGreen = const Color(0xFF37C97D);
  final Color _orangeColor = const Color(0xFFFF8A33);
  final Color _blueLink = const Color(0xFF1976D2);

  String _getAppBarTitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) {
      return "${"Calories".tr()}, ${"Today".tr()}";
    } else if (diffDays == -1) {
      return "${"Calories".tr()}, ${"Yesterday".tr()}";
    } else if (diffDays == 1) {
      return "${"Calories".tr()}, ${"Tomorrow".tr()}";
    } else {
      return "${"Calories".tr()}, ${DateFormat('d MMM').format(target)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF09B84F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: _orangeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Calorie".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    "Analysis".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.2,
              ),
              tabs: [
                Tab(
                  child: Text("Summary & Foods".tr(), textAlign: TextAlign.center),
                ),
                Tab(child: Text("Weight Goal".tr(), textAlign: TextAlign.center)),
                Tab(
                  child: Text("Daily Analysis".tr(), textAlign: TextAlign.center),
                ),
                Tab(child: Text("Meal Analysis".tr(), textAlign: TextAlign.center)),
                Tab(
                  child: Text(
                    "Cals From Nutrients".tr(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: StreamBuilder<DayNutritionData>(
          stream: DayNutritionService.streamDayNutrition(uid, widget.selectedDate),
          builder: (context, snapshot) {
            final dayData = snapshot.data ?? DayNutritionData.empty(widget.selectedDate);

            return TabBarView(
              children: [
                _buildSummaryTab(dayData, uid), // 1. Summary
                WeightJourneyTab(selectedDate: widget.selectedDate), // 2. Weight Goal
                DailyAnalysisPage(
                  selectedDate: widget.selectedDate,
                  data: dayData,
                ), // 3. Daily Analysis (Flask & Forecast)
                MealAnalysisTab(
                  selectedDate: widget.selectedDate,
                  data: dayData,
                ), // 4. Meal Analysis
                CalsFromNutrientsTab(
                  selectedDate: widget.selectedDate,
                  data: dayData,
                ), // 5. Nutrients
              ],
            );
          },
        ),
      ),
    );
  }

  // --- SUMMARY TAB CONTENT ---
  Widget _buildSummaryTab(DayNutritionData data, String uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDailyOverviewCard(data),
          const SizedBox(height: 16),
          _buildTopContributorCard(data),
          const SizedBox(height: 16),
          _build7DayActivityChart(uid, widget.selectedDate, data.targetCals.toInt()),
          const SizedBox(height: 16),
          _buildRecentFoodsList(data),
          const SizedBox(height: 24),
          _buildAboutCaloriesSection(data.targetCals.toInt()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 1. Daily Overview Card
  Widget _buildDailyOverviewCard(DayNutritionData data) {
    final int consumed = data.totalCals.toInt();
    final int budget = data.targetCals.toInt() > 0 ? data.targetCals.toInt() : 2000;
    final int diff = budget - consumed;
    final double progress = budget > 0 ? (consumed / budget).clamp(0.0, 1.0) : 0.0;
    final int pct = budget > 0 ? ((consumed / budget) * 100).toInt() : 0;
    final bool isOver = diff < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Overview".tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.insights, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Text(
                "$consumed kcal",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$pct% ${"of budget".tr()} ${NumberFormat('#,###').format(budget)} ${"cals".tr()}",
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOver ? "${(-diff)} ${"over".tr()}" : "$diff ${"left".tr()}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOver ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: isOver ? _orangeColor : _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Top Contributor Card
  Widget _buildTopContributorCard(DayNutritionData data) {
    Map<String, dynamic>? topFood;
    double maxCals = 0;
    final int budget = data.targetCals.toInt() > 0 ? data.targetCals.toInt() : 2000;

    data.itemsByCategory.forEach((cat, items) {
      for (final item in items) {
        final cals = (item['calories'] as num?)?.toDouble() ??
            (item['estCalories'] as num?)?.toDouble() ??
            0.0;
        if (cals > maxCals) {
          maxCals = cals;
          topFood = item;
        }
      }
    });

    final String foodName = topFood != null
        ? (topFood!['name'] ?? "Logged Food".tr())
        : "No foods logged yet".tr();
    final int calsInt = maxCals.toInt();
    final int budgetPct = budget > 0 ? ((maxCals / budget) * 100).toInt() : 0;
    final double contributorProgress =
        budget > 0 ? (maxCals / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Contributor".tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: _orangeColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topFood != null
                          ? "$calsInt ${"cals".tr()}, $budgetPct% ${"of budget".tr()}"
                          : "Log a meal to see top calorie sources".tr(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: contributorProgress,
                        backgroundColor: Colors.grey.shade200,
                        color: _orangeColor,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (innerContext) {
                    return OutlinedButton(
                      onPressed: () {
                        // Switch to Meal Analysis Tab (Index 3)
                        DefaultTabController.of(innerContext).animateTo(3);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Food by Calories".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => DayFoodReportPage(
                          selectedDate: widget.selectedDate,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Day Food Report".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. 7-Day Activity Chart
  Widget _build7DayActivityChart(String uid, DateTime selectedDate, int budget) {
    final int calorieBudget = budget > 0 ? budget : 2000;
    final DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    final String weekRangeStr =
        "${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM').format(endOfWeek)}";

    return FutureBuilder<List<double>>(
      future: DashboardService().getWeeklyCalories(uid, selectedDate),
      builder: (context, snapshot) {
        final List<double> weeklyCals = snapshot.data ?? List.filled(7, 0.0);
        final double totalWeek = weeklyCals.fold(0.0, (sum, val) => sum + val);
        final int activeDays = weeklyCals.where((c) => c > 0).length;
        final double avgCals = activeDays > 0 ? totalWeek / activeDays : 0.0;
        final int avgPct =
            calorieBudget > 0 ? ((avgCals / calorieBudget) * 100).toInt() : 0;
        final int diffAvg = (avgCals - calorieBudget).round();
        final String avgStatus =
            diffAvg > 0 ? "$diffAvg ${"over".tr()}" : "${(-diffAvg)} ${"left".tr()}";

        final List<String> dayNames = [
          "Mo",
          "Tu",
          "We",
          "Th",
          "Fr",
          "Sa",
          "Su",
        ];
        final double maxC = [
          ...weeklyCals,
          calorieBudget.toDouble(),
        ].reduce(math.max);
        final double scaleMax = maxC > 0 ? maxC * 1.15 : calorieBudget.toDouble();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _whiteCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "7-Day Activity".tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    weekRangeStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Week".tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "${NumberFormat('#,###').format(avgCals.toInt())} kcal",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: diffAvg > 0 ? _orangeColor : _primaryGreen,
                ),
              ),
              Text(
                "${"average".tr()} $avgPct% ${"of budget".tr()}, $avgStatus",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 130,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final double val = weeklyCals[i];
                          final double factor =
                              scaleMax > 0 ? (val / scaleMax).clamp(0.04, 1.0) : 0.04;
                          final Color barColor = val > calorieBudget
                              ? _orangeColor
                              : (val > 0 ? _primaryGreen : Colors.grey.shade300);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (val > 0)
                                Text(
                                  "${val.toInt()}",
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                width: 22,
                                height: 80 * factor,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (i) {
                        final dayDate = startOfWeek.add(Duration(days: i));
                        final bool isCurrentSelected =
                            dayDate.day == selectedDate.day &&
                            dayDate.month == selectedDate.month &&
                            dayDate.year == selectedDate.year;

                        return SizedBox(
                          width: 30,
                          child: Column(
                            children: [
                              Text(
                                "${dayNames[i]} ${dayDate.day}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isCurrentSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrentSelected
                                      ? _primaryGreen
                                      : Colors.grey,
                                ),
                                maxLines: 1,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCurrentSelected
                                      ? _primaryGreen
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Recent Foods
  Widget _buildRecentFoodsList(DayNutritionData data) {
    final List<Map<String, dynamic>> allFoods = [];
    data.itemsByCategory.forEach((cat, items) {
      for (final item in items) {
        allFoods.add({
          ...item,
          'mealCategory': cat,
        });
      }
    });

    // Sort descending by calories
    allFoods.sort((a, b) {
      final num cA = (a['calories'] as num?) ?? (a['estCalories'] as num?) ?? 0;
      final num cB = (b['calories'] as num?) ?? (b['estCalories'] as num?) ?? 0;
      return cB.compareTo(cA);
    });

    final displayFoods = allFoods.take(5).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "High-Calorie Foods Today".tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${allFoods.length} ${"items".tr()}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (displayFoods.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No foods logged for this date.".tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...displayFoods.map((food) {
              final String title = food['name'] ?? "Food item".tr();
              final num cals =
                  (food['calories'] as num?) ?? (food['estCalories'] as num?) ?? 0;
              final String cat = (food['mealCategory'] ?? 'Meal').toString().toUpperCase();

              return Column(
                children: [
                  _buildFoodListItem(
                    icon: _getFoodIcon(cat),
                    color: Colors.green.shade50,
                    iconColor: _primaryGreen,
                    title: title,
                    calories: "${cals.toInt()}",
                    subtitle: "${"Logged in".tr()} $cat",
                  ),
                  const Divider(height: 1, indent: 70),
                ],
              );
            }),
        ],
      ),
    );
  }

  IconData _getFoodIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('break')) return Icons.bakery_dining;
    if (lower.contains('lunch')) return Icons.rice_bowl;
    if (lower.contains('din')) return Icons.dinner_dining;
    return Icons.eco;
  }

  Widget _buildFoodListItem({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String calories,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: " ${"provided".tr()} "),
            TextSpan(
              text: "$calories ${"cals".tr()}",
              style: TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  // 5. About Calories
  Widget _buildAboutCaloriesSection(int budget) {
    final int calTarget = budget > 0 ? budget : 2000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About Calories".tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          "${NumberFormat('#,###').format(calTarget)} ${"cals recommended according to your plan.".tr()}",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Calories measure the energy consumed from foods and beverages and the energy burned through metabolism and activity. To manage weight effectively, align your food log with your target deficit.".tr(),
          style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => DayFoodReportPage(
                      selectedDate: widget.selectedDate,
                    ),
                  ),
                );
              },
              child: Text(
                "Day Food Report".tr(),
                style: TextStyle(
                  color: _blueLink,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const PersonalInfoPage(),
                  ),
                );
              },
              child: Text(
                "Plan Calories & Weight".tr(),
                style: TextStyle(
                  color: _blueLink,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _whiteCardDecoration() {
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
