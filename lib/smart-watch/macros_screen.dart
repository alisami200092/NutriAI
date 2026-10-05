import 'package:flutter/material.dart';
import 'dart:math' as math;

class MacrosScreen extends StatelessWidget {
  const MacrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final shortest = mq.size.shortestSide;

    // Sizes
    final headerSize = shortest * 0.08;
    final semiDiameter = shortest * 0.26;
    final semiStroke = semiDiameter * 0.10;

    final fullDiameter = shortest * 0.30;
    final fullStroke = fullDiameter * 0.12;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: shortest * 0.12, // adjusted from 0.17
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "NUTRITION TRACKER",
                style: TextStyle(
                  fontSize: headerSize * 0.85,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              SizedBox(height: shortest * 0.06),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SemiRing(
                    label: "CARBS",
                    actual: 250,
                    goal: 320,
                    diameter: semiDiameter,
                    stroke: semiStroke,
                    color: Colors.tealAccent,
                  ),
                  _SemiRing(
                    label: "PROTEIN",
                    actual: 120,
                    goal: 150,
                    diameter: semiDiameter,
                    stroke: semiStroke,
                    color: Colors.pinkAccent,
                  ),
                  _SemiRing(
                    label: "FAT",
                    actual: 60,
                    goal: 80,
                    diameter: semiDiameter,
                    stroke: semiStroke,
                    color: Colors.amberAccent,
                  ),
                ],
              ),

              SizedBox(height: shortest * 0.06),

              SizedBox(
                width: fullDiameter,
                height: fullDiameter,
                child: CustomPaint(
                  painter: _FullCircleArcPainter(
                    carbs: 250,
                    protein: 120,
                    fat: 60,
                    colors: [
                      Colors.tealAccent,
                      Colors.pinkAccent,
                      Colors.amberAccent,
                    ],
                    stroke: fullStroke,
                  ),
                ),
              ),

              SizedBox(height: shortest * 0.03), // adjusted from 0.03

              Text(
                "DAILY GOAL: 430g",
                style: TextStyle(
                  fontSize: shortest * 0.05, // adjusted from 0.06
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemiRing extends StatelessWidget {
  final String label;
  final int actual, goal;
  final double diameter, stroke;
  final Color color;

  const _SemiRing({
    required this.label,
    required this.actual,
    required this.goal,
    required this.diameter,
    required this.stroke,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal > 0 ? actual / goal : 0.0).clamp(0.0, 1.0);

    return SizedBox(
      width: diameter,
      height: diameter / 2,
      child: CustomPaint(
        painter: _SemiRingPainter(
          progress: progress,
          stroke: stroke,
          color: color,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: diameter * 0.12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(height: diameter * 0.01),
              Text(
                "$actual g",
                style: TextStyle(
                  fontSize: diameter * 0.18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemiRingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;

  _SemiRingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      -size.height * 0.2,
      size.width,
      size.height * 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.grey[800]!
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    paint.color = color;
    final sweepAngle = progress * math.pi;
    canvas.drawArc(rect, math.pi, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FullCircleArcPainter extends CustomPainter {
  final int carbs, protein, fat;
  final List<Color> colors;
  final double stroke;

  _FullCircleArcPainter({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.colors,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = carbs + protein + fat;
    if (total == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -90.0 * (math.pi / 180.0);

    final values = [carbs, protein, fat];
    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
