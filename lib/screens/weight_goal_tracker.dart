import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'dietary_restrictions.dart';

class WeightGoalTracker extends StatefulWidget {
  final double currentWeight;
  final double targetWeight;
  final String dietaryGoal;
  final double heightCm;
  final int age;
  final String gender;
  final String eventName;
  final DateTime eventDate;
  final String activityLevel;

  const WeightGoalTracker({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.dietaryGoal,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.eventName,
    required this.eventDate,
    required this.activityLevel,
  });

  @override
  // ignore: library_private_types_in_public_api
  _WeightGoalTrackerState createState() => _WeightGoalTrackerState();
}

class _WeightGoalTrackerState extends State<WeightGoalTracker> {
  double progressSpeed = 0.50;
  final int numberOfWeeks = 10;

  @override
  void initState() {
    super.initState();
    if (widget.dietaryGoal.toLowerCase().contains("maintain")) {
      progressSpeed = 0.0;
    }
  }

  double get bmr {
    if (widget.gender.toLowerCase() == 'male') {
      return 10 * widget.currentWeight +
          6.25 * widget.heightCm -
          5 * widget.age +
          5;
    } else {
      return 10 * widget.currentWeight +
          6.25 * widget.heightCm -
          5 * widget.age -
          161;
    }
  }

  double get activityMultiplier {
    switch (widget.activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.200;
      case 'lightly active':
        return 1.375;
      case 'moderately active':
        return 1.550;
      case 'very active':
        return 1.725;
      default:
        return 1.550;
    }
  }

  double get tdee => bmr * activityMultiplier;

  double get calorieAdjustment {
    final goal = widget.dietaryGoal.toLowerCase();
    if (goal.contains("maintain")) return 0;
    return (progressSpeed * 7700) / 7;
  }

  double get calorieTarget {
    final goal = widget.dietaryGoal.toLowerCase();
    if (goal.contains("maintain")) return tdee;
    return goal.contains("loss")
        ? tdee - calorieAdjustment
        : tdee + calorieAdjustment;
  }

  List<FlSpot> generateGraphData() {
    return List.generate(numberOfWeeks + 1, (i) {
      final t = i / numberOfWeeks;
      final w =
          widget.currentWeight +
          (widget.targetWeight - widget.currentWeight) *
              ((1 - math.cos(math.pi * t)) / 2);
      return FlSpot(i.toDouble(), w);
    });
  }

  // Build the line chart data.
  // For weight loss mode, we restore the original graph look by using
  // the original scaling factors (minY * 0.95, maxY * 1.05).
  LineChartData buildLineChartData(List<FlSpot> spots) {
    final bool isWeightLossMode = widget.dietaryGoal.toLowerCase().contains(
      "loss",
    );
    final double minYOriginal = math.min(
      widget.currentWeight,
      widget.targetWeight,
    );
    final double maxYOriginal = math.max(
      widget.currentWeight,
      widget.targetWeight,
    );
    // For weight loss mode, we use the original factors:
    final double minYFactor = isWeightLossMode ? 0.95 : 0.95;
    final double maxYFactor = isWeightLossMode ? 1.05 : 1.05;
    final double minY = minYOriginal * minYFactor;
    final double maxY = maxYOriginal * maxYFactor;

    return LineChartData(
      minX: 0,
      maxX: numberOfWeeks.toDouble(),
      minY: minY,
      maxY: maxY,
      titlesData: FlTitlesData(show: false),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.deepOrange,
              Colors.orange,
              Colors.yellow,
              Colors.lightGreen,
              Colors.green,
            ],
          ),
          barWidth: 4,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  Offset chartToPixel(
    FlSpot spot,
    double w,
    double h,
    double minY,
    double maxY,
  ) {
    final x = (spot.x / numberOfWeeks) * w;
    final y = h - ((spot.y - minY) / (maxY - minY)) * h;
    return Offset(x, y);
  }

  Widget buildStatRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    String? prefixEmoji,
  }) {
    labelColor ??= Colors.black;
    valueColor ??= Colors.black;

    return Row(
      children: [
        if (prefixEmoji != null)
          Text(prefixEmoji, style: TextStyle(fontSize: 14, color: labelColor)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
        const SizedBox(width: 4),
        const Icon(Icons.info_outline, size: 14, color: Colors.black),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, color: valueColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = generateGraphData();
    final w = MediaQuery.of(context).size.width - 32;
    const h = 220.0;
    final bool isWeightMaintainMode = widget.dietaryGoal.toLowerCase().contains(
      "maintain",
    );
    final bool isWeightLossMode = widget.dietaryGoal.toLowerCase().contains(
      "loss",
    );
    // Use the same factors for weight loss as in the original graph:
    final double minYValue =
        math.min(widget.currentWeight, widget.targetWeight) * 0.95;
    final double maxYValue =
        math.max(widget.currentWeight, widget.targetWeight) * 1.05;

    const dotR = 8.0;
    final dotD = dotR * 2;

    // Calculate pixel positions from the graph data
    final rawToday = chartToPixel(spots.first, w, h, minYValue, maxYValue);
    final rawTarget = chartToPixel(spots.last, w, h, minYValue, maxYValue);

    // Base positions for the dots
    final double tx = (rawToday.dx + 25).clamp(dotR, w - dotR);
    final double gx = (rawTarget.dx - 25).clamp(dotR, w - dotR);
    final double ty = rawToday.dy.clamp(dotR, h - dotR);
    final double gy = rawTarget.dy.clamp(dotR, h - dotR);

    // Bubble and label dimensions
    const double bubbleW = 80.0;
    const double bubbleH = 30.0;
    const double labelH = 16.0;
    const double labelMargin = 4.0;
    const double todayH = 16.0;
    const double todayMargin = 4.0;

    final bool isWeightGainMode = widget.dietaryGoal.toLowerCase().contains(
      "gain",
    );

    double currentBubbleY, targetBubbleY;
    double todayYPos;
    double currentLabelY, targetLabelY;
    if (isWeightGainMode) {
      // Weight gain mode: use your previously perfected positions.
      currentBubbleY = ty - bubbleH - 20;
      targetBubbleY = gy + 10;
      todayYPos = ty + dotR + 4;
      currentLabelY = currentBubbleY - labelH - labelMargin;
      targetLabelY = targetBubbleY + bubbleH + labelMargin;
    } else {
      // Weight loss mode: use your adjusted positions.
      currentBubbleY = (ty + dotD + 16 - 20).clamp(0.0, h - bubbleH) + 5;
      targetBubbleY = (gy - bubbleH - 16 - 5).clamp(0.0, h - bubbleH) - 5;
      todayYPos = ty - dotR - todayH - todayMargin;
      // "Current You" label remains below the bubble with an extra offset.
      currentLabelY = currentBubbleY + bubbleH + labelMargin + 5;
      // "Target" label remains above the bubble with an extra offset.
      targetLabelY = targetBubbleY - labelH - labelMargin - 5;
    }

    final double todayX = (tx - 30).clamp(0.0, w - 60);
    final double currentBubbleX = (tx - bubbleW + 50);
    final double targetBubbleX = (gx - bubbleW + 50);

    final redText = "${widget.currentWeight.toStringAsFixed(1)} kg";
    final greenText = "${widget.targetWeight.toStringAsFixed(1)} kg";

    final titleText = isWeightMaintainMode
        ? "Maintain your current weight"
        : (isWeightLossMode
            ? "Choose a weight loss speed you want to follow"
            : "Choose a weight gain speed you want to follow");

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 24,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Flexible(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Lottie.asset(
                          "assets/animations/robot-working.json",
                          width: 130,
                          height: 130,
                        ),
                        const SizedBox(height: 6),
                        Image.asset(
                          "assets/images/weight-goal-track.png",
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.monitor_weight, size: 90),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titleText,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Graph + Thought Bubbles
                  SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        LineChart(buildLineChartData(spots)),
                        // Red dot
                        Positioned(
                          left: tx - dotR,
                          top: ty - dotR,
                          child: _buildDot(Colors.red, dotD),
                        ),
                        // "Today" label (relative to red dot)
                        Positioned(
                          left: todayX + 10,
                          top: todayYPos,
                          child: const Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        // Green dot
                        Positioned(
                          left: gx - dotR,
                          top: gy - dotR,
                          child: _buildDot(Colors.green, dotD),
                        ),
                        // Current You bubble
                        Positioned(
                          left: currentBubbleX,
                          top: currentBubbleY,
                          child: ThoughtBubble(
                            text: redText,
                            backgroundColor: Colors.white,
                            width: bubbleW,
                            reverse: isWeightGainMode ? false : true,
                            isCurrentWeight: true,
                          ),
                        ),
                        // "Current You" label:
                        // For weight gain, placed above the bubble; for weight loss, below the bubble.
                        Positioned(
                          left: currentBubbleX - 10,
                          top: currentLabelY,
                          child: SizedBox(
                            width: bubbleW,
                            child: const Center(
                              child: Text(
                                "Current You",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Target bubble
                        Positioned(
                          left: targetBubbleX,
                          top: targetBubbleY,
                          child: ThoughtBubble(
                            text: greenText,
                            backgroundColor: Colors.white,
                            width: bubbleW,
                            reverse: isWeightGainMode ? true : false,
                            isTargetWeight: true,
                          ),
                        ),
                        // "Target" label:
                        // For weight gain, placed below the bubble; for weight loss, above the bubble.
                        Positioned(
                          left: targetBubbleX - 10,
                          top: isWeightGainMode
                              ? targetLabelY + 10
                              : targetLabelY,
                          child: SizedBox(
                            width: bubbleW,
                            child: const Center(
                              child: Text(
                                "Target",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats, slider, and Continue button
                  Column(
                    children: [
                      buildStatRow("TDEE", "${tdee.toStringAsFixed(0)} kcal"),
                      const SizedBox(height: 4),
                      buildStatRow(
                        isWeightMaintainMode
                            ? "Energy Balance"
                            : (isWeightLossMode
                                ? "Calorie Deficit"
                                : "Calorie Surplus"),
                        isWeightMaintainMode
                            ? "0 kcal"
                            : "${calorieAdjustment.toStringAsFixed(0)} kcal",
                      ),
                      const SizedBox(height: 4),
                      buildStatRow(
                        "Calorie Target",
                        "${calorieTarget.toStringAsFixed(0)} kcal",
                        labelColor: Colors.orange,
                        prefixEmoji: "🔥",
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isWeightMaintainMode
                            ? "0.0 kg/week (Maintenance)"
                            : "${progressSpeed.toStringAsFixed(1)} kg/week",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ⚕️ Medical Safety Warnings for Calorie Deficits
                      if (isWeightLossMode &&
                          ((widget.gender.toLowerCase().contains('female') &&
                                  calorieTarget < 1200) ||
                              (!widget.gender.toLowerCase().contains('female') &&
                                  calorieTarget < 1500)))
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.gender.toLowerCase().contains('female')
                                      ? "⚠️ Health Warning: Medical guidelines recommend at least 1,200 kcal/day for women to prevent nutrient deficiency and metabolic slowdown."
                                      : "⚠️ Health Warning: Medical guidelines recommend at least 1,500 kcal/day for men to support essential hormone production and organs.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Slider(
                        value: isWeightMaintainMode ? 0.0 : progressSpeed,
                        min: isWeightMaintainMode ? 0.0 : 0.1,
                        max: 1.0,
                        divisions: isWeightMaintainMode ? null : 9,
                        label: isWeightMaintainMode
                            ? "0.0 kg/week"
                            : "${progressSpeed.toStringAsFixed(1)} kg/week",
                        activeColor: isWeightMaintainMode ? Colors.grey : Colors.green,
                        inactiveColor: isWeightMaintainMode ? Colors.grey.shade300 : null,
                        onChanged: isWeightMaintainMode
                            ? null
                            : (v) => setState(() {
                                  // Round to 1 decimal place to ensure exact 0.1 increments
                                  progressSpeed = double.parse(v.toStringAsFixed(1));
                                }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWeightMaintainMode
                            ? "Weight maintenance mode is active. Calorie intake matches your daily energy expenditure (TDEE)."
                            : (isWeightLossMode
                                ? "Safe guideline: 0.5 - 1.0 kg/week is recommended by dietitians for sustainable weight loss."
                                : "Safe guideline: 0.25 - 0.5 kg/week is ideal for lean muscle gain without excess fat."),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DietaryRestrictionsPage(
                              age: widget.age,
                              heightCm: widget.heightCm, // ← added
                              gender: widget.gender, // ← added
                              weightKg: widget.currentWeight,
                              targetWeight: widget.targetWeight,
                              dietaryGoal: widget.dietaryGoal,
                              eventName: widget.eventName,
                              eventDate: widget.eventDate,
                              activityLevel: widget.activityLevel,
                              weightChangePerWeek:
                                  isWeightMaintainMode ? 0.0 : progressSpeed,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class ThoughtBubble extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final double width;
  final double tailHeight;
  final bool reverse;
  final bool isCurrentWeight; // Flag to check if it's "Current You"
  final bool isTargetWeight; // Flag to check if it's "Target"

  const ThoughtBubble({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.width,
    this.tailHeight = 8,
    this.reverse = false,
    this.isCurrentWeight = false,
    this.isTargetWeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ThoughtBubblePainter(backgroundColor, tailHeight, reverse),
      child: Container(
        width: width * 0.75,
        height: 40,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isCurrentWeight
                ? Colors.red
                : isTargetWeight
                ? Colors.green
                : Colors.black,
          ),
        ),
      ),
    );
  }
}

class ThoughtBubblePainter extends CustomPainter {
  final Color color;
  final double tailHeight;
  final bool reverse;

  ThoughtBubblePainter(this.color, this.tailHeight, this.reverse);

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 10.0;
    final paint = Paint()..color = color;
    final path = Path();

    // Draw shadow
    canvas.drawShadow(path, Colors.black45, 4.0, true);

    if (!reverse) {
      // Bubble body with tail at bottom
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
          const Radius.circular(radius),
        ),
      );
      final double tailW = 16.0;
      final double midX = size.width / 2;
      path.moveTo(midX - tailW / 2, size.height - tailHeight);
      path.lineTo(midX, size.height);
      path.lineTo(midX + tailW / 2, size.height - tailHeight);
      path.close();
    } else {
      // Bubble body with tail at top
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, tailHeight, size.width, size.height - tailHeight),
          const Radius.circular(radius),
        ),
      );
      final double tailW = 16.0;
      final double midX = size.width / 2;
      path.moveTo(midX - tailW / 2, tailHeight);
      path.lineTo(midX, 0);
      path.lineTo(midX + tailW / 2, tailHeight);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
