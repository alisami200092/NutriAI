import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with SingleTickerProviderStateMixin {
  bool _isSummer = false;
  double get _dailyGoal => _isSummer ? 16.0 : 8.0;
  double _consumed = 0.0;
  bool _isLoading = true;

  late AnimationController _waveController;

  final CollectionReference _waterCollection = FirebaseFirestore.instance
      .collection('WaterIntake');

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _subscribeToDailyIntake();
  }

  // --- 1. LISTENER WITH UID FILTER ---
  void _subscribeToDailyIntake() {
    final user = FirebaseAuth.instance.currentUser;

    // Safety Check: If no user is logged in, stop loading.
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _waterCollection
        .where('uid', isEqualTo: user.uid) // <--- CRITICAL: ONLY MY DATA
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snapshot) {
          double totalToday = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('amount')) {
              totalToday += (data['amount'] as num).toDouble();
            }
          }

          if (mounted) {
            setState(() {
              _consumed = totalToday;
              _isLoading = false;
            });
          }
        });
  }

  // --- 2. SAVE WITH UID ---
  Future<void> _logWater(double amount) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be logged in to save data!".tr())),
      );
      return;
    }

    await _waterCollection.add({
      'uid': user.uid, // <--- SAVING WHO DRANK IT
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // ... (Keep the exact same build(), _showWaterEntryDialog, and Painters as before) ...
  // Paste the rest of the UI code here from the previous response.

  // --- The Popup Dialog ---
  void _showWaterEntryDialog() {
    double tempValue = 1.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Center(child: Text("Log Water".tr())),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "How much did you drink?".tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${tempValue.toStringAsFixed(1)} ${tempValue == 1.0 ? "Glass".tr() : "Glasses".tr()}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09B84F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempValue,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    activeColor: const Color(0xFF09B84F),
                    onChanged: (val) {
                      setDialogState(() {
                        tempValue = val;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- MINUS BUTTON ---
                      IconButton(
                        onPressed: () {
                          if (tempValue > 0.1) {
                            setDialogState(() {
                              tempValue -= 0.1;
                              // FIX: Round to 1 decimal place to prevent 0.099999 errors
                              tempValue = double.parse(
                                tempValue.toStringAsFixed(1),
                              );
                              // Safety clamp
                              if (tempValue < 0.1) tempValue = 0.1;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // --- PLUS BUTTON ---
                      IconButton(
                        onPressed: () {
                          if (tempValue < 2.0) {
                            setDialogState(() {
                              tempValue += 0.1;
                              // FIX: Round to 1 decimal place to prevent 2.000001 errors
                              tempValue = double.parse(
                                tempValue.toStringAsFixed(1),
                              );
                              // Safety clamp
                              if (tempValue > 2.0) tempValue = 2.0;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 30,
                          color: Color(0xFF09B84F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel".tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _logWater(tempValue);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09B84F),
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Add Water".tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage for the big glass
    // Cap at the goal for visual purposes (even if DB has more)
    double displayConsumed = _consumed > _dailyGoal ? _dailyGoal : _consumed;
    double fillPercentage = (displayConsumed / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Water Tracker".tr(),
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      // Show Loading indicator while connecting to DB
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0F7FA), Colors.white],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // --- TOGGLE BUTTONS ---
                    Container(
                      width: 280,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          // Winter Option
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSummer = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isSummer
                                      ? const Color(0xFF09B84F)
                                      : Colors.grey.shade300,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    bottomLeft: Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.ac_unit_rounded,
                                      size: 18,
                                      color: !_isSummer
                                          ? Colors.lightBlueAccent
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Winter (8)".tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: !_isSummer
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Summer Option
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSummer = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _isSummer
                                      ? const Color(0xFF09B84F)
                                      : Colors.grey.shade300,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wb_sunny_rounded,
                                      size: 18,
                                      color: _isSummer
                                          ? Colors.yellow
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Summer (16)".tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _isSummer
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- BIG ANIMATED GLASS ---
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          height: 320,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // 1. Background
                              CustomPaint(
                                size: const Size(200, 320),
                                painter: GlassShapePainter(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  strokeWidth: 0,
                                ),
                              ),

                              // 2. Animated Water
                              ClipPath(
                                clipper: GlassShapeClipper(),
                                child: AnimatedBuilder(
                                  animation: _waveController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: WavePainter(
                                        animationValue: _waveController.value,
                                        fillPercentage: fillPercentage,
                                        waterColor: const Color(
                                          0xFF4FC3F7,
                                        ).withValues(alpha: 0.6),
                                      ),
                                      size: const Size(200, 320),
                                    );
                                  },
                                ),
                              ),

                              // 3. Outline & Highlight
                              CustomPaint(
                                size: const Size(200, 320),
                                painter: GlassShapePainter(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  strokeWidth: 3,
                                  drawHighlight: true,
                                ),
                              ),

                              // 4. Text Overlay
                              Positioned(
                                top: 100,
                                child: Column(
                                  children: [
                                    Text(
                                      "${_consumed.toStringAsFixed(1)} / ${_dailyGoal.toInt()}",
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "Glasses Logged".tr(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- SMALL GLASSES HISTORY (Dynamic Layout) ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      height: 140,
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(_dailyGoal.toInt(), (index) {
                            bool isFilled = index < _consumed;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFilled
                                      ? Icons.local_drink_rounded
                                      : Icons.local_drink_outlined,
                                  color: isFilled
                                      ? const Color(0xFF29B6F6)
                                      : Colors.grey.shade300,
                                  size: 24,
                                ),
                                if (index == 0 ||
                                    index == _dailyGoal.toInt() - 1)
                                  Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),

                    // --- DRINK BUTTON ---
                    GestureDetector(
                      onTap: _showWaterEntryDialog,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF09B84F), Color(0xFF37C97D)],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF09B84F,
                              ).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          "Log Water Intake".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// --- HELPER: DEFINES THE SHAPE OF THE GLASS ---
Path _getGlassPath(Size size) {
  final path = Path();
  final double topWidth = size.width;
  final double bottomWidth = size.width * 0.75;
  final double height = size.height;
  final double inset = (topWidth - bottomWidth) / 2;

  path.moveTo(0, 0);
  path.lineTo(inset, height - 20);
  path.quadraticBezierTo(inset, height, inset + 20, height);
  path.lineTo(size.width - inset - 20, height);
  path.quadraticBezierTo(
    size.width - inset,
    height,
    size.width - inset,
    height - 20,
  );
  path.lineTo(size.width, 0);
  path.close();

  return path;
}

// --- CLIPPER ---
class GlassShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _getGlassPath(size);

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// --- PAINTER FOR GLASS BORDER ---
class GlassShapePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool drawHighlight;

  GlassShapePainter({
    required this.color,
    required this.strokeWidth,
    this.drawHighlight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getGlassPath(size);

    if (strokeWidth > 0) {
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, borderPaint);
    } else {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    if (drawHighlight) {
      final highlightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.transparent,
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, highlightPaint);

      final rimPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, 0),
          width: size.width,
          height: 20,
        ),
        rimPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GlassShapePainter oldDelegate) => false;
}

// --- PAINTER FOR WAVE ---
class WavePainter extends CustomPainter {
  final double animationValue;
  final double fillPercentage;
  final Color waterColor;

  WavePainter({
    required this.animationValue,
    required this.fillPercentage,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage == 0) return;

    final paint = Paint()
      ..color = waterColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final waterHeight = size.height * fillPercentage;
    final baseHeight = size.height - waterHeight;

    path.moveTo(0, baseHeight);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            math.sin(
                  (i / size.width * 2 * math.pi) +
                      (animationValue * 2 * math.pi),
                ) *
                8,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}
