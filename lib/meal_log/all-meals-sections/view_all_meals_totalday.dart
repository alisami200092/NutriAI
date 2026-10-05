import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'day_nutrition_service.dart';

class DayTotalsSection extends StatelessWidget {
  final DayNutritionData data;

  const DayTotalsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double calProgress = data.targetCals > 0
        ? (data.totalCals / data.targetCals).clamp(0.0, 1.0)
        : 0.0;

    final double carbProgress = data.targetCarbs > 0
        ? (data.totalCarbs / data.targetCarbs).clamp(0.0, 1.0)
        : 0.0;

    final double proteinProgress = data.targetProtein > 0
        ? (data.totalProtein / data.targetProtein).clamp(0.0, 1.0)
        : 0.0;

    final double fatProgress = data.targetFat > 0
        ? (data.totalFat / data.targetFat).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Day Totals".tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // --- Calories Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cals".tr(), style: const TextStyle(fontSize: 16)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "${data.totalCals.round()} ${"cals".tr()}, ${data.calsPercent}%   ",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: data.isCalsOver
                          ? "${"over".tr()} ${data.calsOverDiff} ${"cals".tr()}"
                          : "${"left".tr()} ${data.calsLeftDiff} ${"cals".tr()}",
                      style: TextStyle(
                        color: data.isCalsOver
                            ? Colors.orange
                            : const Color(0xFF00C896),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Calories Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: calProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              color: data.isCalsOver ? Colors.orange : const Color(0xFF00C896),
            ),
          ),

          const SizedBox(height: 25),

          // --- Macros Bars (Carbs, Protein, Fat) ---
          Row(
            children: [
              // Carbs
              Expanded(
                child: _buildMacroColumn(
                  label: "${"T. Carbs".tr()} ${data.carbCalPercent.round()}% ${"cals".tr()}",
                  value: "${data.totalCarbs.round()}g",
                  subText: data.totalCarbs > data.targetCarbs
                      ? "${"over".tr()} ${data.carbsOver}g"
                      : "${"left".tr()} ${data.carbsLeft}g",
                  subTextColor: data.totalCarbs > data.targetCarbs
                      ? Colors.orange
                      : Colors.black87,
                  progress: carbProgress,
                  color: const Color(0xFF00C896),
                ),
              ),
              const SizedBox(width: 8),
              // Protein
              Expanded(
                child: _buildMacroColumn(
                  label: "Protein".tr(),
                  rightLabel: "${data.proteinCalPercent.round()}%",
                  value: "${data.totalProtein.round()}g",
                  subText: data.totalProtein > data.targetProtein
                      ? "${"over".tr()} ${data.proteinOver}g"
                      : "${"left".tr()} ${data.proteinLeft}g",
                  subTextColor: Colors.black87,
                  progress: proteinProgress,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(width: 8),
              // Fat
              Expanded(
                child: _buildMacroColumn(
                  label: "Fat".tr(),
                  rightLabel: "${data.fatCalPercent.round()}%",
                  value: "${data.totalFat.round()}g",
                  subText: data.totalFat > data.targetFat
                      ? "${"over".tr()} ${data.fatOver}g"
                      : "${"left".tr()} ${data.fatLeft}g",
                  subTextColor: data.totalFat > data.targetFat
                      ? Colors.orange
                      : Colors.black87,
                  progress: fatProgress,
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- Pie Chart & Legend ---
          Row(
            children: [
              // Chart
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: data.totalMacroCals > 0
                            ? [
                                PieChartSectionData(
                                  color: const Color(0xFF00C896), // Carbs
                                  value: data.carbCalPercent > 0
                                      ? data.carbCalPercent
                                      : 0.1,
                                  title: '',
                                  radius: 20,
                                ),
                                PieChartSectionData(
                                  color: Colors.amber, // Fat
                                  value: data.fatCalPercent > 0
                                      ? data.fatCalPercent
                                      : 0.1,
                                  title: '',
                                  radius: 20,
                                ),
                                PieChartSectionData(
                                  color: Colors.purpleAccent, // Protein
                                  value: data.proteinCalPercent > 0
                                      ? data.proteinCalPercent
                                      : 0.1,
                                  title: '',
                                  radius: 20,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  color: Colors.grey.shade300,
                                  value: 100,
                                  title: '',
                                  radius: 20,
                                ),
                              ],
                      ),
                    ),
                    Center(
                      child: Text(
                        data.totalMacroCals > 0
                            ? "${data.carbCalPercent.round()}%\n${"cals".tr()}"
                            : "0%\n${"cals".tr()}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00C896),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    "T. Carbs".tr(),
                    "${data.totalCarbs.round()}g",
                    const Color(0xFF00C896),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    "Protein".tr(),
                    "${data.totalProtein.round()}g",
                    Colors.purpleAccent,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    "Fat".tr(),
                    "${data.totalFat.round()}g",
                    Colors.amber,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),

          // --- Food Grade ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Average Food Grade".tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    Text(
                      data.foodGrade,
                      style: TextStyle(
                        color: data.foodGradeColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.more_vert, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroColumn({
    required String label,
    String? rightLabel,
    required String value,
    required String subText,
    required Color subTextColor,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (rightLabel != null)
              Text(
                rightLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF0F0F0),
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subText, style: TextStyle(fontSize: 11, color: subTextColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String val, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          val,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
