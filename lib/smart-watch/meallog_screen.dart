import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nutriapp/smart-watch/breakfast_log_screen.dart';
import 'package:nutriapp/smart-watch/dinner_log_screen.dart';
import 'package:nutriapp/smart-watch/lunch_log_screen.dart';
import 'package:nutriapp/smart-watch/snack_log_screen.dart';

class MealLogScreen extends StatelessWidget {
  const MealLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diameter = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.black, Color(0xFF1A1A40)],
              center: Alignment.center,
              radius: 0.9,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: diameter * 0.8,
              height: diameter * 0.8,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(diameter * 0.8, diameter * 0.8),
                    painter: _MealRingPainter(),
                  ),
                  _MealLabels(),
                  const _CenterText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterText extends StatelessWidget {
  const _CenterText();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Text(
        "LOG\nMEAL",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _MealLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.8;
    final radius = size / 2;
    final center = Offset(radius, radius);

    // Base distance from center
    final double iconDistance = radius * 0.68;
    final double buttonSize = 80.0;

    final List<_MealInfo> meals = [
      _MealInfo(
        "BREAKFAST",
        Icons.wb_sunny,
        -135 * math.pi / 180,
        dx: -19, // Moves it MORE LEFT
        dy: 0,
      ),
      _MealInfo(
        "LUNCH",
        Icons.restaurant,
        -45 * math.pi / 180,
        dx: 15, // Moves it MORE RIGHT
        dy: 0,
      ),
      _MealInfo(
        "DINNER",
        Icons.nightlight_round,
        45 * math.pi / 180,
        dx: 2, // Slightly right
        dy: 0,
      ),
      _MealInfo(
        "SNACK",
        Icons.apple,
        135 * math.pi / 180,
        dx: -5, // Slightly left
        dy: 0,
      ),
    ];

    return Stack(
      children: meals.map((meal) {
        // 1. Calculate base mathematical position
        final cx = center.dx + iconDistance * math.cos(meal.angle);
        final cy = center.dy + iconDistance * math.sin(meal.angle);

        // 2. Apply manual offsets (dx, dy) and center the button box
        final left = cx - (buttonSize / 2) + meal.dx;
        final top = cy - (buttonSize / 2) + meal.dy;

        return Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTap: () {
              if (meal.label == "BREAKFAST") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BreakfastScreen(),
                  ),
                );
              } else if (meal.label == "LUNCH") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LunchScreen()),
                );
              } else if (meal.label == "DINNER") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DinnerScreen()),
                );
              } else if (meal.label == "SNACK") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SnackScreen()),
                );
              }
            },
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(meal.icon, color: Colors.white, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    meal.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MealInfo {
  final String label;
  final IconData icon;
  final double angle;
  final double dx; // Manual horizontal adjustment
  final double dy; // Manual vertical adjustment

  _MealInfo(this.label, this.icon, this.angle, {this.dx = 0, this.dy = 0});
}

class _MealRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    final ringThickness = size.width * 0.31;
    final heightGapPx = 4.0;
    final innerRadius = outerRadius - ringThickness + heightGapPx;

    final sweep = math.pi / 2;

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius - 1);
    final innerRect = Rect.fromCircle(
      center: center,
      radius: innerRadius + 0.5,
    );

    final List<double> axes = [
      3 * math.pi / 4, // snack
      math.pi / 4, // dinner
      7 * math.pi / 4, // lunch
      5 * math.pi / 4, // breakfast
    ];

    final List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];

    final radialSeparationPx = 6.0;

    for (int i = 0; i < axes.length; i++) {
      final axis = axes[i];
      final start = axis - (sweep / 2);

      final path = Path()
        ..moveTo(
          center.dx + innerRadius * math.cos(start),
          center.dy + innerRadius * math.sin(start),
        )
        ..arcTo(outerRect, start, sweep, false)
        ..lineTo(
          center.dx + innerRadius * math.cos(start + sweep),
          center.dy + innerRadius * math.sin(start + sweep),
        )
        ..arcTo(innerRect, start + sweep, -sweep, false)
        ..close();

      final dxRadial = radialSeparationPx * math.cos(axis);
      final dyRadial = radialSeparationPx * math.sin(axis);

      final matrix = Matrix4.identity()
        ..translateByDouble(dxRadial, dyRadial, 0.0, 1.0);
      final transformed = path.transform(matrix.storage);

      // Faded fill -> Updated to use .withValues
      final fill = Paint()
        ..color = colors[i].withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;

      // Neon glow stroke -> Updated to use .withValues
      final glow = Paint()
        ..color = colors[i].withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      // Crisp edge stroke
      final stroke = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(transformed, fill);
      canvas.drawPath(transformed, glow);
      canvas.drawPath(transformed, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
