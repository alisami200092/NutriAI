import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntakeScreen extends StatefulWidget {
  final String uid; // 🔥 Accept UID from main.dart
  const WaterIntakeScreen({super.key, required this.uid});

  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  // Real-time Firebase State
  int todayTotalGlasses = 0;
  StreamSubscription? _waterSub;
  bool isLogging = false;

  // Local UI State for selecting glasses to log
  int selectedGlasses = 1;
  final int flOzPerGlass = 8;

  @override
  void initState() {
    super.initState();
    _listenToWaterIntake();
  }

  void _listenToWaterIntake() {
    final now = DateTime.now();

    // Listen to the user's water logs
    _waterSub = FirebaseFirestore.instance
        .collection('WaterIntake')
        .where('uid', isEqualTo: widget.uid)
        .snapshots()
        .listen((snap) {
          int tempTotal = 0;

          for (var doc in snap.docs) {
            final data = doc.data();
            if (data['timestamp'] != null) {
              // Convert Firebase Timestamp to DateTime
              DateTime dt = (data['timestamp'] as Timestamp).toDate();

              // Only sum the water if it was logged TODAY
              if (dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day) {
                tempTotal += (data['amount'] ?? 0) as int;
              }
            }
          }

          if (mounted) {
            setState(() => todayTotalGlasses = tempTotal);
          }
        });
  }

  @override
  void dispose() {
    _waterSub?.cancel();
    super.dispose();
  }

  void _increment() => setState(() => selectedGlasses++);
  void _decrement() =>
      setState(() => selectedGlasses = (selectedGlasses - 1).clamp(1, 99));

  // 🔥 Function to Save Water to Firebase
  Future<void> _logWaterToFirebase() async {
    if (selectedGlasses == 0 || isLogging) return;

    setState(() => isLogging = true);

    try {
      await FirebaseFirestore.instance.collection('WaterIntake').add({
        'amount': selectedGlasses,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': widget.uid,
      });

      // Show tiny success message and reset selector to 1
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Water logged!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => selectedGlasses = 1);
      }
    } catch (e) {
      debugPrint("Error logging water: $e");
    } finally {
      if (mounted) setState(() => isLogging = false);
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
            final ringDiameter = screenMinSide;
            final contentDiameter = screenMinSide * 0.92;

            final padH = contentDiameter * 0.06;

            // 🔥 TWEAKED PADDINGS: Reduced top padding slightly to make room
            final padTop = contentDiameter * 0.08;
            final padBottom = contentDiameter * 0.04;

            const neonCyan = Color(0xFF3EC7FF);

            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  NeonRing(diameter: ringDiameter),

                  SizedBox(
                    width: contentDiameter,
                    height: contentDiameter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: padH,
                        right: padH,
                        top: padTop,
                        bottom: padBottom,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. TOP HEADER SECTION
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'WATER INTAKE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Today: $todayTotalGlasses Glasses',
                                  style: const TextStyle(
                                    color: neonCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 2. MIDDLE SECTION (Wrapped in Expanded to fix overflow!)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Centers it in remaining space
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '+$selectedGlasses Glasses',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // 🔥 TWEAKED SPACING
                                SizedBox(height: contentDiameter * 0.01),

                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: contentDiameter * 0.74,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _CircleButton(
                                        icon: Icons.remove,
                                        onTap: _decrement,
                                      ),
                                      Flexible(
                                        fit: FlexFit.tight,
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/water-glass.png',
                                            // 🔥 Reduced image size slightly to prevent cramming
                                            width: contentDiameter * 0.22,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      _CircleButton(
                                        icon: Icons.add,
                                        onTap: _increment,
                                      ),
                                    ],
                                  ),
                                ),

                                // 🔥 TWEAKED SPACING
                                SizedBox(height: contentDiameter * 0.01),

                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${selectedGlasses * flOzPerGlass} fl oz',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15, // Reduced from 16
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. BOTTOM BUTTON SECTION
                          GestureDetector(
                            onTap: _logWaterToFirebase,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: contentDiameter * 0.42,
                                minHeight: contentDiameter * 0.055,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: neonCyan, width: 1),
                              ),
                              child: isLogging
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: neonCyan,
                                      ),
                                    )
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'LOG WATER',
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NeonRing extends StatelessWidget {
  final double diameter;
  const NeonRing({super.key, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(painter: _NeonPainter()),
    );
  }
}

class _NeonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
      ..color = const Color(0xFF3EC7FF).withAlpha(130);

    canvas.drawCircle(center, radius * 0.995, glowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.020
      ..color = const Color(0xFF7FDBFF);

    canvas.drawCircle(center, radius * 0.97, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFFFFF).withAlpha(40),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
