import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// ---------- Circular calorie widget ----------
class CircularCalorieWidget extends StatelessWidget {
  final int consumed;
  final int budget;
  final double size;
  final double strokeWidth;
  final Color arcColor;
  final Color backgroundArcColor;
  final Widget Function(BuildContext, int budget, int consumed)? buildCenter;

  const CircularCalorieWidget({
    super.key,
    required this.consumed,
    required this.budget,
    this.size = 160,
    this.strokeWidth = 10,
    this.arcColor = const Color(0xFF37C97D),
    this.backgroundArcColor = const Color(0xFFE7ECEF),
    this.buildCenter,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget == 0 ? 0.0 : (consumed / budget).clamp(0.0, 1.0);

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _ArcPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  arcColor: arcColor,
                  backgroundArcColor: backgroundArcColor,
                ),
              );
            },
          ),
          if (buildCenter != null) buildCenter!(context, budget, consumed),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double strokeWidth;
  final Color arcColor;
  final Color backgroundArcColor;

  _ArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.arcColor,
    required this.backgroundArcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define the arc's bounding box
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = Rect.fromLTWH(
      rect.left + inset,
      rect.top + inset,
      rect.width - strokeWidth,
      rect.height - strokeWidth,
    );

    // Paint for the background circle
    final bgPaint = Paint()
      ..color = backgroundArcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw the background circle (full 360°)
    canvas.drawArc(arcRect, -pi / 2, 2 * pi, false, bgPaint);

    // Paint for the progress arc
    final fgPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Draw the progress arc based on the progress value
    canvas.drawArc(arcRect, -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.backgroundArcColor != backgroundArcColor;
  }
}

// ---------- Simple label/value pair (customizable) ----------
class StatLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final double labelSize;
  final double valueSize;
  final FontWeight labelWeight;
  final FontWeight valueWeight;
  final TextAlign align;

  const StatLabelValue({
    super.key,
    required this.label,
    required this.value,
    this.labelColor = Colors.grey,
    this.valueColor = Colors.black,
    this.labelSize = 13,
    this.valueSize = 16,
    this.labelWeight = FontWeight.w600,
    this.valueWeight = FontWeight.w800,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: align,
          style: TextStyle(
            color: labelColor,
            fontSize: labelSize,
            fontWeight: labelWeight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: align,
          style: TextStyle(
            color: valueColor,
            fontSize: valueSize,
            fontWeight: valueWeight,
          ),
        ),
      ],
    );
  }
}

// ---------- Fixed Bar Graph ----------
// ---------- Animated Weekly Bar Graph ----------
Widget weeklyCalorieChart({
  required List<double> values, // calories for each day (Mon-Sun)
  required double budget, // calorie budget
}) {
  // 1. Find Max Value for Scaling
  double maxDataValue = 0;
  if (values.isNotEmpty) {
    maxDataValue = values.reduce((a, b) => a > b ? a : b);
  }

  // Prevent division by zero if everything is 0
  if (maxDataValue == 0 && budget == 0) maxDataValue = 2000;

  // 2. Determine Scale (add 20% breathing room above the highest point)
  final double maxScale = (maxDataValue > budget ? maxDataValue : budget) * 1.2;

  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Calculate current day index (0=Mon, 6=Sun) to highlight it
  final int currentDayIndex = DateTime.now().weekday - 1;

  return LayoutBuilder(
    builder: (context, constraints) {
      final double totalHeight = constraints.maxHeight;

      // 3. Calculate position of the budget line from the TOP
      final double budgetY = totalHeight - ((budget / maxScale) * totalHeight);

      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Dashed Line (Budget)
          Positioned(
            top: budgetY.isNaN || budgetY.isInfinite ? 0 : budgetY,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(child: CustomPaint(painter: _DashedLinePainter(y: 0))),
              ],
            ),
          ),

          // Bars + labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(values.length, (i) {
              final val = values[i];
              // Calculate Bar Height relative to scale
              double barHeight = (val / maxScale) * totalHeight;

              // Color Logic:
              Color barColor;
              if (val == 0) {
                barColor = Colors.grey.shade300; // Empty/Zero state
                barHeight = 4; // Tiny height just to show "nothing here"
              } else if (val > budget * 1.15) {
                barColor = const Color(0xFFEF5350); // Red (Way over)
              } else if (val > budget) {
                barColor = Colors.orangeAccent; // Orange (Slightly over)
              } else {
                barColor = const Color(0xFF37C97D); // Green (Good)
              }

              // Is this today?
              final isToday = i == currentDayIndex;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // ANIMATED BAR
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: barHeight),
                      duration: Duration(
                        milliseconds: 600 + (i * 100),
                      ), // Staggered effect
                      curve: Curves.easeOutBack,
                      builder: (context, animatedHeight, child) {
                        return Container(
                          height: animatedHeight,
                          width: 12,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    // Day label
                    Text(
                      days[i % days.length],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      );
    },
  );
}

class _DashedLinePainter extends CustomPainter {
  final double y;
  _DashedLinePainter({required this.y});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- Macro Circle (Untouched) ----------
class MacroCircle extends StatefulWidget {
  final String label;
  final double percentage; // 0.0 to 1.0
  final String consumedText;
  final String leftText;
  final Color color;

  const MacroCircle({
    super.key,
    required this.label,
    required this.percentage,
    required this.consumedText,
    required this.leftText,
    required this.color,
  });

  @override
  State<MacroCircle> createState() => _MacroCircleState();
}

class _MacroCircleState extends State<MacroCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Initial setup
    _animation = Tween<double>(
      begin: 0,
      end: widget.percentage,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  // ✅ THIS IS THE FIX: It forces the green line to update when data changes
  @override
  void didUpdateWidget(MacroCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      // Animate from the current position to the new percentage
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label + percentage above
        Text(
          '${widget.label} ${(widget.percentage * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),

        // Circle with text inside
        SizedBox(
          height: 50,
          width: 50,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // This is the widget that paints the green line
                  SegmentedCircle(
                    percentage: _animation.value, // ✅ Now this value updates!
                    color: widget.color,
                    segments: 3,
                    strokeWidth: 6,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.consumedText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${'left'.tr()} ${widget.leftText}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class SegmentedCircle extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final Color color;
  final int segments;
  final double strokeWidth;

  const SegmentedCircle({
    super.key,
    required this.percentage,
    required this.color,
    this.segments = 3,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(50, 50),
      painter: _SegmentedCirclePainter(
        percentage: percentage,
        color: color,
        segments: segments,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SegmentedCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final int segments;
  final double strokeWidth;

  _SegmentedCirclePainter({
    required this.percentage,
    required this.color,
    required this.segments,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = -math.pi / 2; // start at top
    final sweepPerSegment = (2 * math.pi) / segments;
    final gap = 0.40; // (increase for bigger segmented gap)

    final bgPaint = Paint()
      ..color = const Color(0xFFE7ECEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1️⃣ Draw background arcs (with gaps)
    for (int i = 0; i < segments; i++) {
      final segStart = startAngle + i * sweepPerSegment;
      canvas.drawArc(rect, segStart, sweepPerSegment - gap, false, bgPaint);
    }

    // 2️⃣ Draw filled arcs according to percentage
    double totalSweep = (2 * math.pi) * percentage;
    for (int i = 0; i < segments && totalSweep > 0; i++) {
      final segStart = startAngle + i * sweepPerSegment;
      final maxSweepForSegment = sweepPerSegment - gap;
      final fillSweep = totalSweep > maxSweepForSegment
          ? maxSweepForSegment
          : totalSweep;

      canvas.drawArc(rect, segStart, fillSweep, false, fgPaint);

      totalSweep -= maxSweepForSegment;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

const double kHeaderHeight = 44; // fixed height for the top row
const double kCardHeight = 300; // fixed height for the card body
const double kBlockSpacing = 8; // space between header and card

Widget mealSummaryCard({
  required String mealLabel,
  required String emoji,
  required String foodTitle,
  required List<String> healthBenefits,
  required Map<String, String> nutrition,
  required String timeSuggestion,
  required List<String> nutrientHighlights,
  VoidCallback? onReplace,
}) {
  return SizedBox(
    width: double.infinity,
    height: kHeaderHeight + kCardHeight + kBlockSpacing,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        SizedBox(
          height: kHeaderHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$emoji $mealLabel",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        Text(
                          "🔥 ${nutrition["Calories"] ?? ""}  ",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "🍗 ${nutrition["Protein"] ?? ""}  ",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "🥑 ${nutrition["Fat"] ?? ""}  ",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "🌾 ${nutrition["Carbs"] ?? ""}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: kBlockSpacing),

        // Card body
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: SizedBox(
            width: double.infinity,
            height: kCardHeight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food title
                  Text(
                    foodTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF37C97D),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Health benefits
                  Text(
                    "💪 ${'Health Benefits:'.tr()}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...healthBenefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text("• $b", style: const TextStyle(fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Time suggestion
                  Text(
                    "🕒 ${'Time Suggestion:'.tr()}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      "• $timeSuggestion",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nutrient highlights
                  Text(
                    "🎯 ${'Nutrient Highlights:'.tr()}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...nutrientHighlights.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        "• $tag",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onReplace,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Colors.lightBlue.withValues(alpha: 0.2),
                        ),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        shape: WidgetStateProperty.all(const StadiumBorder()),
                        elevation: WidgetStateProperty.all(0),
                      ),
                      icon: const Icon(
                        Icons.autorenew,
                        size: 18,
                        color: Colors.lightBlue,
                      ),
                      label: Text(
                        "AI Replace".tr(),
                        style: const TextStyle(color: Colors.lightBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
