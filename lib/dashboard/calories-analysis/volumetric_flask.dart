import 'package:flutter/material.dart';
import 'dart:math' as math;

class VolumetricFlask extends StatelessWidget {
  final double fillPercentage; // 0.0 to 1.0
  final double height;
  final double width;
  final bool isOverflow;

  const VolumetricFlask({
    super.key,
    required this.fillPercentage,
    this.height = 200,
    this.width = 80,
    this.isOverflow = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. The Liquid (Animated)
          ClipPath(
            clipper: FlaskShapeClipper(),
            child: Container(
              height: height,
              width: width,
              color: Colors.white, // Empty glass background
              alignment: Alignment.bottomCenter, // Important: Start from bottom
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: fillPercentage),
                duration: const Duration(seconds: 2),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    heightFactor: value.clamp(
                      0.0,
                      1.0,
                    ), // Limits height to container
                    widthFactor: 1.0,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isOverflow
                              ? [Colors.redAccent, Colors.orange]
                              : [
                                  const Color(0xFF37C97D),
                                  const Color(0xFF2E7D32),
                                ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. The Glass Outline
          CustomPaint(
            size: Size(width, height),
            painter: FlaskOutlinePainter(),
          ),

          // 3. Shine Effect
          Positioned(
            bottom: width * 0.3,
            right: width * 0.2,
            child: Container(
              width: width * 0.1,
              height: width * 0.1,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- GEOMETRY LOGIC ---

// Shared function to ensure Clipper and Painter match perfectly
Path _getFlaskPath(Size size) {
  final path = Path();
  final w = size.width;
  final h = size.height;

  // Geometry Config
  final bulbRadius = w / 2;
  final neckWidth = w * 0.35;

  final cx = w / 2;
  final cyBulb = h - bulbRadius; // Center Y of the bulb circle

  // 1. Start top-left of neck
  path.moveTo(cx - neckWidth / 2, 0);

  // 2. Line down neck
  path.lineTo(cx - neckWidth / 2, cyBulb - (bulbRadius * 0.8));

  // 3. Left Shoulder (flare out)
  path.quadraticBezierTo(
    cx - neckWidth / 2,
    cyBulb - (bulbRadius * 0.4), // Control point
    0,
    cyBulb, // End point (leftmost part of bulb)
  );

  // 4. The Bulb Bottom (A perfect arc)
  // We draw from left (0) to right (w) going under
  path.arcTo(
    Rect.fromCircle(center: Offset(cx, cyBulb), radius: bulbRadius),
    math.pi, // Start angle (180 deg, left)
    -math.pi, // Sweep angle (-180 deg, counter-clockwise to right)
    false,
  );

  // 5. Right Shoulder (flare in)
  path.quadraticBezierTo(
    cx + neckWidth / 2,
    cyBulb - (bulbRadius * 0.4), // Control point
    cx + neckWidth / 2,
    cyBulb - (bulbRadius * 0.8), // Back to neck
  );

  // 6. Up neck
  path.lineTo(cx + neckWidth / 2, 0);

  // path.close(); // Keep top open for the "liquid" look, painter draws cap manually
  return path;
}

class FlaskShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _getFlaskPath(size);
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class FlaskOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = _getFlaskPath(size);
    canvas.drawPath(path, paint);

    // Draw the "cap" line slightly inset
    final w = size.width;
    final neckWidth = w * 0.35;
    canvas.drawLine(
      Offset((w / 2) - (neckWidth / 2), 0),
      Offset((w / 2) + (neckWidth / 2), 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- FINAL FIXED BRACKET PAINTER (Typography Style) ---
class BracketPainter extends CustomPainter {
  final bool isLeft;
  final Color color;

  BracketPainter({required this.isLeft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          2.5 // Slightly thicker to be visible
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // We define the "Spine" (vertical part) in the center of the width
    // Left Brace {: Spine is at w/2, Tip is at 0, Arms at w
    // Right Brace }: Spine is at w/2, Tip is at w, Arms at 0

    final double centerX = w / 2;

    if (isLeft) {
      // LEFT BRACE: {

      // 1. Top Arm (Starts Top-Right)
      path.moveTo(w, 0);

      // Curve into the vertical spine
      path.cubicTo(centerX, 0, centerX, 0, centerX, 20);

      // 2. Top Vertical Line
      path.lineTo(centerX, (h / 2) - 15);

      // 3. The Beak (Middle Point pointing LEFT)
      // Curve OUT to the left
      path.cubicTo(centerX, (h / 2) - 5, 0, (h / 2) - 5, 0, h / 2);
      // Curve IN back to the spine
      path.cubicTo(0, (h / 2) + 5, centerX, (h / 2) + 5, centerX, (h / 2) + 15);

      // 4. Bottom Vertical Line
      path.lineTo(centerX, h - 20);

      // 5. Bottom Arm (Curve to Bottom-Right)
      path.cubicTo(centerX, h, centerX, h, w, h);
    } else {
      // RIGHT BRACE: }

      // 1. Top Arm (Starts Top-Left)
      path.moveTo(0, 0);

      // Curve into the vertical spine
      path.cubicTo(centerX, 0, centerX, 0, centerX, 20);

      // 2. Top Vertical Line
      path.lineTo(centerX, (h / 2) - 15);

      // 3. The Beak (Middle Point pointing RIGHT)
      // Curve OUT to the right
      path.cubicTo(centerX, (h / 2) - 5, w, (h / 2) - 5, w, h / 2);
      // Curve IN back to the spine
      path.cubicTo(w, (h / 2) + 5, centerX, (h / 2) + 5, centerX, (h / 2) + 15);

      // 4. Bottom Vertical Line
      path.lineTo(centerX, h - 20);

      // 5. Bottom Arm (Curve to Bottom-Left)
      path.cubicTo(centerX, h, centerX, h, 0, h);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
