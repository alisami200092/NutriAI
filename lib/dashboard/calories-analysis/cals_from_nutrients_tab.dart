import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/meal_log/all-meals-sections/day_nutrition_service.dart';

class CalsFromNutrientsTab extends StatefulWidget {
  final DateTime selectedDate;
  final DayNutritionData? data;

  const CalsFromNutrientsTab({
    super.key,
    required this.selectedDate,
    this.data,
  });

  @override
  State<CalsFromNutrientsTab> createState() => _CalsFromNutrientsTabState();
}

class _CalsFromNutrientsTabState extends State<CalsFromNutrientsTab> {
  final Color _tealColor = const Color(0xFF1ABC9C);
  final Color _orangeColor = const Color(0xFFFF8A33);
  final Color _redColor = const Color(0xFFFF7043);
  final Color _purpleColor = const Color(0xFFAB47BC);
  final Color _yellowColor = const Color(0xFFFFCA28);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  String _selectedFilter = "Daily";

  @override
  Widget build(BuildContext context) {
    final d = widget.data ?? DayNutritionData.empty(widget.selectedDate);

    final carbProgress = d.targetCarbs > 0
        ? (d.totalCarbs / d.targetCarbs).clamp(0.0, 1.2)
        : 0.0;
    final protProgress = d.targetProtein > 0
        ? (d.totalProtein / d.targetProtein).clamp(0.0, 1.2)
        : 0.0;
    final fatProgress = d.targetFat > 0
        ? (d.totalFat / d.targetFat).clamp(0.0, 1.2)
        : 0.0;

    return Container(
      color: _backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Header & Toggles
            Text(
              "Macro Insights Dashboard".tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterToggle(),
            const SizedBox(height: 12),
            _buildDateNavigator(),
            const SizedBox(height: 20),

            // 2. The Pie Chart Card (Calorie Breakdown)
            _buildCalorieBreakdownCard(d),
            const SizedBox(height: 24),

            // 3. Gram Intake Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Gram Intake by Macros".tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Gram Intake Cards
            _buildGramIntakeCard(
              label: "T. Carbs".tr(),
              avgValue: "${d.totalCarbs.round()}g ${"consumed".tr()}",
              statusText: d.totalCarbs > d.targetCarbs
                  ? "${d.carbsOver}g ${"over".tr()}"
                  : "${d.carbsLeft}g ${"left".tr()}",
              statusColor: d.totalCarbs > d.targetCarbs ? _redColor : _tealColor,
              subText: "${"daily target".tr()} ${d.targetCarbs.round()}g",
              progress: carbProgress,
              progressColor: d.totalCarbs > d.targetCarbs ? _redColor : _tealColor,
            ),
            const SizedBox(height: 12),
            _buildGramIntakeCard(
              label: "Protein".tr(),
              avgValue: "${d.totalProtein.round()}g ${"consumed".tr()}",
              statusText: d.totalProtein > d.targetProtein
                  ? "${d.proteinOver}g ${"over".tr()}"
                  : "${d.proteinLeft}g ${"left".tr()}",
              statusColor: _tealColor,
              subText: "${"daily target".tr()} ${d.targetProtein.round()}g",
              progress: protProgress,
              progressColor: _purpleColor,
            ),
            const SizedBox(height: 12),
            _buildGramIntakeCard(
              label: "Fat".tr(),
              avgValue: "${d.totalFat.round()}g ${"consumed".tr()}",
              statusText: d.totalFat > d.targetFat
                  ? "${d.fatOver}g ${"over".tr()}"
                  : "${d.fatLeft}g ${"left".tr()}",
              statusColor: d.totalFat > d.targetFat ? _redColor : _tealColor,
              subText: "${"daily target".tr()} ${d.targetFat.round()}g",
              progress: fatProgress,
              progressColor: _yellowColor,
            ),

            const SizedBox(height: 30),

            // 5. Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("To adjust macro targets, edit your profile in the Me tab.".tr()),
                      backgroundColor: const Color(0xFF09B84F),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orangeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Adjust Macro Targets".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillOption("Daily"),
          _buildPillOption("Weekly"),
          _buildPillOption("Monthly"),
        ],
      ),
    );
  }

  Widget _buildPillOption(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _tealColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
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

  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('EEEE, d MMM yyyy').format(widget.selectedDate),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- Section 1: The Pie Chart Card ---
  Widget _buildCalorieBreakdownCard(DayNutritionData d) {
    final bool hasData = d.totalMacroCals > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calorie Breakdown by Macros".tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pie Chart
              SizedBox(
                height: 100,
                width: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    sections: hasData
                        ? [
                            PieChartSectionData(
                              color: _tealColor,
                              value: d.carbCalPercent > 0 ? d.carbCalPercent : 0.1,
                              title: "${d.carbCalPercent.round()}%",
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              titlePositionPercentageOffset: 0.6,
                            ),
                            PieChartSectionData(
                              color: _yellowColor,
                              value: d.fatCalPercent > 0 ? d.fatCalPercent : 0.1,
                              title: "${d.fatCalPercent.round()}%",
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              titlePositionPercentageOffset: 0.6,
                            ),
                            PieChartSectionData(
                              color: _purpleColor,
                              value: d.proteinCalPercent > 0 ? d.proteinCalPercent : 0.1,
                              title: "${d.proteinCalPercent.round()}%",
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              titlePositionPercentageOffset: 0.6,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              color: Colors.grey.shade300,
                              value: 100,
                              title: "0%",
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem("T. Carbs".tr(), "${d.totalCarbs.round()}g", _tealColor),
                  const SizedBox(height: 6),
                  _buildLegendItem("Protein".tr(), "${d.totalProtein.round()}g", _purpleColor),
                  const SizedBox(height: 6),
                  _buildLegendItem("Fat".tr(), "${d.totalFat.round()}g", _yellowColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Progress Rows
          _buildMacroProgressRow(
            label: "T. Carbs".tr(),
            percentage: "${d.carbCalPercent.round()}% ${"cals".tr()}",
            status: d.totalCarbs > d.targetCarbs ? "${d.carbsOver}g ${"over".tr()}" : "${d.carbsLeft}g ${"left".tr()}",
            statusColor: d.totalCarbs > d.targetCarbs ? _redColor : _tealColor,
            targetText: "${"target:".tr()} ${d.targetCarbs.round()}g",
            progress: d.targetCarbs > 0 ? (d.totalCarbs / d.targetCarbs).clamp(0.0, 1.0) : 0.0,
            progressColor: d.totalCarbs > d.targetCarbs ? _redColor : _tealColor,
            barColor: _tealColor,
          ),
          const SizedBox(height: 16),
          _buildMacroProgressRow(
            label: "Protein".tr(),
            percentage: "${d.proteinCalPercent.round()}% ${"cals".tr()}",
            status: d.totalProtein > d.targetProtein ? "${d.proteinOver}g ${"over".tr()}" : "${d.proteinLeft}g ${"left".tr()}",
            statusColor: _tealColor,
            targetText: "${"target:".tr()} ${d.targetProtein.round()}g",
            progress: d.targetProtein > 0 ? (d.totalProtein / d.targetProtein).clamp(0.0, 1.0) : 0.0,
            progressColor: _purpleColor,
            barColor: _purpleColor,
          ),
          const SizedBox(height: 16),
          _buildMacroProgressRow(
            label: "Fat".tr(),
            percentage: "${d.fatCalPercent.round()}% ${"cals".tr()}",
            status: d.totalFat > d.targetFat ? "${d.fatOver}g ${"over".tr()}" : "${d.fatLeft}g ${"left".tr()}",
            statusColor: d.totalFat > d.targetFat ? _redColor : _tealColor,
            targetText: "${"target:".tr()} ${d.targetFat.round()}g",
            progress: d.targetFat > 0 ? (d.totalFat / d.targetFat).clamp(0.0, 1.0) : 0.0,
            progressColor: d.totalFat > d.targetFat ? _redColor : _yellowColor,
            barColor: _yellowColor,
          ),
        ],
      ),
    );
  }

  // --- Section 2: Gram Intake Cards ---
  Widget _buildGramIntakeCard({
    required String label,
    required String avgValue,
    required String statusText,
    required Color statusColor,
    required String subText,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                avgValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F0F0),
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroProgressRow({
    required String label,
    required String percentage,
    required String status,
    required Color statusColor,
    required String targetText,
    required double progress,
    required Color progressColor,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentage,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          targetText,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF0F0F0),
            color: progressColor,
          ),
        ),
      ],
    );
  }
}
