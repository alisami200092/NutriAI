import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeightLogScreen extends StatefulWidget {
  const WeightLogScreen({super.key});

  @override
  State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen> {
  double weightKg = 66.0; // Set default to 66 based on your screenshot
  bool isKg = true;
  bool _isLoading = false; // Added loading state

  void _increment() =>
      setState(() => weightKg = (weightKg + 0.1).clamp(0, 999));
  void _decrement() =>
      setState(() => weightKg = (weightKg - 0.1).clamp(0, 999));
  void _toggleUnit() => setState(() => isKg = !isKg);

  double get displayValue => isKg ? weightKg : kgToLb(weightKg);
  String get displayUnit => isKg ? 'KG' : 'LB';

  double kgToLb(double kg) => kg * 2.2046226218;

  Future<void> _saveWeightToFirebase() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get the currently logged-in user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("No user is currently logged in.");
      }

      final uid = user.uid; // This ensures both watch and phone use the same ID

      // 2. Format the weight to 1 decimal place before saving
      double weightToSave = double.parse(weightKg.toStringAsFixed(1));

      // 3. Save to UserProfiles -> {uid} -> WeightLogs
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(uid)
          .collection('WeightLogs')
          .add({
            'weight': weightToSave,
            // Use serverTimestamp to avoid watch/phone local time differences
            'date': FieldValue.serverTimestamp(),
          });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight logged successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving weight: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenMinSide = constraints.biggest.shortestSide;
            final arcDiameter = screenMinSide;
            final contentDiameter = screenMinSide * 0.88;

            final padH = contentDiameter * 0.06;
            final padTop = contentDiameter * 0.06;
            final padBottom = contentDiameter * 0.06;

            const neonStart = Color(0xFF2ECC71);
            const neonMid1 = Color(0xFF00BCD4);
            const neonMid2 = Color(0xFF3F51B5);
            const neonMid3 = Color(0xFF8E44AD);
            const neonEnd = Color(0xFF2ECC71);

            return Center(
              child: SizedBox(
                width: arcDiameter,
                height: arcDiameter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(arcDiameter, arcDiameter),
                      painter: _GaugeArcPainter(
                        strokeWidth: math.max(6, arcDiameter * 0.012),
                        startAngleDeg: 135,
                        sweepDeg: 270,
                        colors: const [
                          neonStart,
                          neonMid1,
                          neonMid2,
                          neonMid3,
                          neonEnd,
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(
                        left: padH,
                        right: padH,
                        top: padTop,
                        bottom: padBottom,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -12),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'WEIGHT LOG',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "Current Weight: ${weightKg.toStringAsFixed(1)} kg",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: contentDiameter * 0.02),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CircleButton(
                                icon: Icons.remove,
                                onTap: _decrement,
                                size: 26,
                                iconSize: 15,
                              ),
                              SizedBox(width: contentDiameter * 0.035),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: displayValue,
                                      end: displayValue,
                                    ),
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayUnit,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: contentDiameter * 0.035),
                              _CircleButton(
                                icon: Icons.add,
                                onTap: _increment,
                                size: 26,
                                iconSize: 15,
                              ),
                            ],
                          ),
                          SizedBox(height: contentDiameter * 0.08),
                          GestureDetector(
                            onTap: _toggleUnit,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'KG',
                                  style: TextStyle(
                                    color: isKg
                                        ? Colors.white
                                        : Colors.white.withAlpha(120),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  ' | ',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'LB',
                                  style: TextStyle(
                                    color: !isKg
                                        ? Colors.white
                                        : Colors.white.withAlpha(120),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: contentDiameter * 0.022),
                          _GradientSlider(
                            width: contentDiameter * 0.70,
                            value: weightKg,
                            min: 0,
                            max: 150,
                            onChanged: (val) => setState(() => weightKg = val),
                            gradient: const LinearGradient(
                              colors: [neonMid1, neonMid2, neonMid3],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- UPDATED SAVE BUTTON ---
                    Positioned(
                      bottom: contentDiameter * 0.06,
                      child: GestureDetector(
                        onTap: _saveWeightToFirebase, // Call the save function
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2ECC71),
                                Color(0xFF00BCD4),
                                Color(0xFF3F51B5),
                                Color(0xFF8E44AD),
                                Color(0xFF2ECC71),
                              ],
                            ),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: contentDiameter * 0.42,
                              minWidth:
                                  contentDiameter *
                                  0.25, // added minWidth for spinner
                              minHeight: contentDiameter * 0.055,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Log Weight',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Arc painter — touches borders with proportional stroke
class _GaugeArcPainter extends CustomPainter {
  final double strokeWidth;
  final double startAngleDeg;
  final double sweepDeg;
  final List<Color> colors;

  const _GaugeArcPainter({
    this.strokeWidth = 7,
    required this.startAngleDeg,
    required this.sweepDeg,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth * 0.5;

    final gradient = SweepGradient(
      colors: colors,
      startAngle: 0.0,
      endAngle: math.pi * 2,
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startRad = startAngleDeg * math.pi / 180.0;
    final sweepRad = sweepDeg * math.pi / 180.0;

    canvas.drawArc(rect, startRad, sweepRad, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Larger alpha-based circle button
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 26, // <-- default increased size
    this.iconSize = 15, // <-- default increased icon size
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFFFFF).withAlpha(40),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

// Gradient slider (unchanged behavior)
class _GradientSlider extends StatelessWidget {
  final double width;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Gradient gradient;

  const _GradientSlider({
    required this.width,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: gradient,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
