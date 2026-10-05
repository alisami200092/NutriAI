import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/me/personal_info.dart';
import 'package:nutriapp/meal_log/view_all_meals.dart';

class WeightJourneyTab extends StatefulWidget {
  final DateTime? selectedDate;

  const WeightJourneyTab({super.key, this.selectedDate});

  @override
  State<WeightJourneyTab> createState() => _WeightJourneyTabState();
}

class _WeightJourneyTabState extends State<WeightJourneyTab> {
  // UI Colors
  final Color _tealColor = const Color(0xFF26C6DA);
  final Color _orangeColor = const Color(0xFFFF8A33);
  final Color _blueColor = const Color(0xFF29B6F6);
  final Color _cardColor = Colors.white;

  // Chart State
  String _selectedTimeFilter = "3 Months";

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Center(child: Text("Please login to view progress".tr()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("No goal data found.".tr()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // Extract Data safely with fallbacks
        final double currentWeight =
            (data['weight'] as num?)?.toDouble() ?? 75.0;
        final double targetWeight =
            (data['targetWeight'] as num?)?.toDouble() ?? currentWeight;
        final String goalType = (data['dietaryGoal'] ?? 'Loss').toString();
        final double weeklyRate =
            (data['weightChangePerWeek'] as num?)?.toDouble() ?? 0.5;

        // Determine Logic Mode
        final bool isLoss = goalType.toLowerCase().contains('loss') ||
            targetWeight < currentWeight;
        final bool isGain = goalType.toLowerCase().contains('gain') ||
            targetWeight > currentWeight;
        final bool isMaintain = !isLoss && !isGain;

        final Color activeColor = isGain
            ? _orangeColor
            : (isLoss ? _tealColor : _blueColor);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDailyFocusCard(
                currentWeight,
                targetWeight,
                weeklyRate,
                isLoss,
                isGain,
                isMaintain,
                activeColor,
              ),
              const SizedBox(height: 16),
              _buildGraphCard(
                currentWeight,
                targetWeight,
                isLoss,
                isGain,
                isMaintain,
                activeColor,
              ),
              const SizedBox(height: 16),
              _buildManageButton(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- 1. Top Card: Daily Focus ---
  Widget _buildDailyFocusCard(
    double current,
    double target,
    double rate,
    bool isLoss,
    bool isGain,
    bool isMaintain,
    Color activeColor,
  ) {
    final String titleText = "Daily Focus: Your Target Status".tr();
    String rateText;
    String motivationalText;
    String buttonText = "Log Meal Now".tr();

    final double diff = (target - current).abs();

    if (isLoss) {
      rateText = "Your estimated weight loss rate is currently {} kg/week.".tr(args: ["$rate"]);
      motivationalText =
          "To reach your goal of {} kg, stick to your calorie deficit! You're {} kg away.".tr(args: [target.toStringAsFixed(1), diff.toStringAsFixed(1)]);
    } else if (isGain) {
      rateText = "Your estimated weight gain rate is currently {} kg/week.".tr(args: ["$rate"]);
      motivationalText =
          "To reach your goal of {} kg, ensure you hit your calorie surplus! You need to gain {} kg.".tr(args: [target.toStringAsFixed(1), diff.toStringAsFixed(1)]);
    } else {
      rateText = "You are currently maintaining your weight.".tr();
      motivationalText =
          "Keep your calories balanced to stay at {} kg.".tr(args: [current.toStringAsFixed(1)]);
      buttonText = "Log Maintenance Meal".tr();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            titleText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            rateText,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            motivationalText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => AllMealsPage(
                      initialDate: widget.selectedDate ?? DateTime.now(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Middle Card: The Graph (Fixed Overflow for all 3 modes) ---
  Widget _buildGraphCard(
    double current,
    double target,
    bool isLoss,
    bool isGain,
    bool isMaintain,
    Color activeColor,
  ) {
    final double diff = (target - current).abs();

    String statusLabel;
    String diffText;
    String subtitleText;

    if (isLoss) {
      statusLabel = "Total Lost".tr();
      diffText = "-${diff.toStringAsFixed(1)} kg";
      subtitleText = "Weight Loss Journey".tr();
    } else if (isGain) {
      statusLabel = "Total Gained".tr();
      diffText = "+${diff.toStringAsFixed(1)} kg";
      subtitleText = "Weight Gain Journey".tr();
    } else {
      statusLabel = "Maintaining".tr();
      diffText = "${"Stable".tr()} (${current.toStringAsFixed(1)} kg)";
      subtitleText = "Target Maintained".tr();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
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
          Text(
            "Your Weight Journey".tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Top Row: wrapped in Expanded to prevent right overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$statusLabel: $diffText",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${"Current:".tr()} ${current.toStringAsFixed(1)} kg",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${"Target:".tr()} ${target.toStringAsFixed(1)} kg",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // THE CHART
          SizedBox(
            height: 200,
            child: _buildAreaChart(
              current,
              target,
              isLoss,
              isGain,
              isMaintain,
              activeColor,
            ),
          ),

          const SizedBox(height: 20),
          // Scrollable filter bar to prevent 67px overflow on any device
          _buildTimeFilters(activeColor),
        ],
      ),
    );
  }

  // --- Chart Logic: Tailored for Loss, Gain, and Maintain ---
  Widget _buildAreaChart(
    double currentWeight,
    double targetWeight,
    bool isLoss,
    bool isGain,
    bool isMaintain,
    Color chartColor,
  ) {
    int days = 30;
    switch (_selectedTimeFilter) {
      case "Weekly":
        days = 7;
        break;
      case "Monthly":
        days = 30;
        break;
      case "3 Months":
        days = 90;
        break;
      case "6 Months":
        days = 180;
        break;
      case "All":
        days = 365;
        break;
      default:
        days = 30;
    }

    final List<FlSpot> spots = [];

    if (isMaintain) {
      // Steady line with smooth curve
      for (int i = 0; i <= days; i++) {
        spots.add(FlSpot(i.toDouble(), currentWeight));
      }
    } else {
      // Cosine interpolation for organic trajectory
      for (int i = 0; i <= days; i++) {
        final double t = i / days;
        final double w = currentWeight +
            (targetWeight - currentWeight) * ((1 - math.cos(math.pi * t)) / 2);
        spots.add(FlSpot(i.toDouble(), w));
      }
    }

    // Dynamic Y-Axis Range
    final double minW = math.min(currentWeight, targetWeight);
    final double maxW = math.max(currentWeight, targetWeight);
    double padding = (maxW - minW) * 0.25;
    if (padding < 1.5) padding = 2.0;

    final double yMin = (minW - padding).floorToDouble();
    final double yMax = (maxW + padding).ceilToDouble();
    final double yInterval = ((yMax - yMin) / 4).clamp(1.0, 10.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yInterval,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  "${value.toInt()}kg",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (days / 2).clamp(1.0, 180.0),
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text(
                    "Today",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                if ((value - days / 2).abs() < 1) {
                  return Text(
                    "${(days ~/ 2)}d",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                if (value == days) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      isMaintain ? "Target" : "Goal",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: days.toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                return spot.x == 0 || spot.x == days;
              },
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4.5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: chartColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  chartColor.withValues(alpha: 0.35),
                  chartColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Scrollable Filter Bar (Fixes the 67px overflow error permanently) ---
  Widget _buildTimeFilters(Color activeColor) {
    final filters = ["Weekly", "Monthly", "3 Months", "6 Months", "All"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((filter) {
          final bool isSelected = _selectedTimeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: Text(
                  filter.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManageButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalInfoPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _orangeColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          "Manage Weight Goals".tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
