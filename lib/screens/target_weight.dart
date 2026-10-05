import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nutriapp/screens/events_page.dart';

class TargetWeightPage extends StatefulWidget {
  final double currentWeight;
  final String dietaryGoal;
  final double heightCm;
  final int age;
  final String gender;

  const TargetWeightPage({
    super.key,
    required this.currentWeight,
    required this.dietaryGoal,
    required this.heightCm,
    required this.age,
    required this.gender,
  });

  @override
  State<TargetWeightPage> createState() => _TargetWeightPageState();
}

class _TargetWeightPageState extends State<TargetWeightPage> {
  // Config for the custom ruler
  final double _minWeight = 0.0;
  final double _maxWeight = 300.0; // In KG
  final double _pixelsPerUnit = 100.0; // Spacing between integer units

  double _targetWeight = 0.0; // Stored in KG
  bool _isKg = true;

  String get normalizedGoal => widget.dietaryGoal.toLowerCase();

  @override
  void initState() {
    super.initState();
    // Default logic: ±5kg based on goal
    if (normalizedGoal.contains("loss")) {
      _targetWeight = widget.currentWeight - 5;
    } else if (normalizedGoal.contains("gain")) {
      _targetWeight = widget.currentWeight + 5;
    } else {
      _targetWeight = widget.currentWeight;
    }
    _targetWeight = _targetWeight.clamp(_minWeight, _maxWeight);
  }

  // --- Logic for Ruler Dragging ---
  void _handleDrag(DragUpdateDetails details) {
    // details.primaryDelta: negative = left drag (increase value)
    double delta = -details.primaryDelta! / _pixelsPerUnit;

    setState(() {
      if (_isKg) {
        _targetWeight += delta;
      } else {
        // If displaying Lbs, 1 unit dragged = 1 Lb.
        // Convert that 1 Lb delta back to KG for storage.
        _targetWeight += delta / 2.20462;
      }
      _targetWeight = _targetWeight.clamp(_minWeight, _maxWeight);
    });
  }

  // Helper to get weight in selected unit
  double _getDisplayWeight(double weightInKg) {
    return _isKg ? weightInKg : weightInKg * 2.20462;
  }

  double _calculateBMI(double weight) {
    if (widget.heightCm <= 0) return 0;
    double heightM = widget.heightCm / 100;
    return weight / (heightM * heightM);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 24.9) return "Normal";
    if (bmi < 29.9) return "Overweight";
    if (bmi < 34.9) return "Obese";
    return "Extremely Obese";
  }

  Color _getDotColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24.9) return Colors.green;
    if (bmi < 29.9) return Colors.yellow;
    if (bmi < 34.9) return Colors.orange;
    return Colors.red;
  }

  double _calculateMarkerPosition(double bmi, double scaleWidth) {
    const double minBMI = 15.0;
    const double maxBMI = 40.0;
    double clamped = bmi.clamp(minBMI, maxBMI);
    return ((clamped - minBMI) / (maxBMI - minBMI)) * scaleWidth;
  }

  // --- UI COMPONENTS ---

  Widget _buildGoalResultBanner(double projectedBMI) {
    double weightDiff = 0.0;
    double percentage = 0.0;
    String mainText = "";
    String subText = "";

    if (normalizedGoal.contains("gain")) {
      if (_targetWeight > widget.currentWeight) {
        weightDiff = _targetWeight - widget.currentWeight;
        percentage = (weightDiff / widget.currentWeight) * 100;
        mainText = "${percentage.toStringAsFixed(0)}% Weight gain";
        subText =
            "You will gain ${weightDiff.toStringAsFixed(1)} kg to reach your target weight!\nYour BMI index will be ${projectedBMI.toStringAsFixed(1)} and you will be ${_bmiCategory(projectedBMI).toLowerCase()}.";
      } else {
        subText =
            "Please select a target weight above your current weight for weight gain.";
      }
    } else if (normalizedGoal.contains("loss")) {
      if (_targetWeight < widget.currentWeight) {
        weightDiff = widget.currentWeight - _targetWeight;
        percentage = (weightDiff / widget.currentWeight) * 100;
        mainText = "${percentage.toStringAsFixed(0)}% Weight loss";
        subText =
            "You will lose ${weightDiff.toStringAsFixed(1)} kg to reach your target weight!\nYour BMI index will be ${projectedBMI.toStringAsFixed(1)} and you will be ${_bmiCategory(projectedBMI).toLowerCase()}.";
      } else {
        subText =
            "Please select a target weight below your current weight for weight loss.";
      }
    } else {
      subText =
          "Maintain your current weight for a healthy life.\nYour BMI index will be ${projectedBMI.toStringAsFixed(1)} and you will be ${_bmiCategory(projectedBMI).toLowerCase()}.";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD0EFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/info-icon.png", width: 36, height: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mainText.isNotEmpty)
                  Text(
                    mainText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                if (mainText.isNotEmpty) const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade300,
                    height: 1.25,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggler() {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          _unitToggleButton("kg", true),
          _unitToggleButton("lbs", false),
        ],
      ),
    );
  }

  Widget _unitToggleButton(String label, bool isKg) {
    final selected = _isKg == isKg;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isKg = isKg;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.green : Colors.grey.shade300,
            borderRadius: isKg
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bmiLabel(String label, double bmiVal, double width) {
    double pos = _calculateMarkerPosition(bmiVal, width);
    return Positioned(
      left: pos - 10,
      top: 0,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _bmiColorBox(Color color) => Expanded(child: Container(color: color));

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleWidth = screenWidth - 60;
    final bmi = _calculateBMI(_targetWeight);

    final double displayTarget = _getDisplayWeight(_targetWeight);
    final double displayCurrent = _getDisplayWeight(widget.currentWeight);
    final double displayMin = _getDisplayWeight(_minWeight);
    final double displayMax = _getDisplayWeight(_maxWeight);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // 1. LayoutBuilder gives us the screen constraints
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 2. SingleChildScrollView allows scrolling on small screens
            return SingleChildScrollView(
              // 3. ConstrainedBox + IntrinsicHeight allows us to keep using Spacer() safely!
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Lottie.asset(
                        "assets/animations/robot-working.json",
                        width: 100, // Slightly reduced to save space
                        height: 100,
                      ),
                      const SizedBox(height: 10),
                      Image.asset(
                        "assets/images/target_weight.png",
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "What is your target weight?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUnitToggler(),
                      const SizedBox(height: 20),
                      _buildGoalResultBanner(bmi),
                      const SizedBox(height: 20),

                      // --- BMI SCALE ---
                      Column(
                        children: [
                          SizedBox(
                            width: scaleWidth,
                            height: 20,
                            child: Stack(
                              children: [
                                _bmiLabel("18.5", 18.5, scaleWidth),
                                _bmiLabel("25.0", 25.0, scaleWidth),
                                _bmiLabel("30.0", 30.0, scaleWidth),
                                _bmiLabel("35.0", 35.0, scaleWidth),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: scaleWidth,
                            height: 8,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Row(
                                    children: [
                                      _bmiColorBox(Colors.blue),
                                      _bmiColorBox(Colors.green),
                                      _bmiColorBox(Colors.yellow),
                                      _bmiColorBox(Colors.orange),
                                      _bmiColorBox(Colors.red),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: _calculateMarkerPosition(
                                    bmi,
                                    scaleWidth,
                                  ).clamp(0, scaleWidth - 14),
                                  top: -2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getDotColor(bmi),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Text(
                                "Underweight",
                                style: TextStyle(fontSize: 10),
                              ),
                              Text("Normal", style: TextStyle(fontSize: 10)),
                              Text(
                                "Overweight",
                                style: TextStyle(fontSize: 10),
                              ),
                              Text("Obese", style: TextStyle(fontSize: 10)),
                              Text(
                                "Ext. Obese",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // --- SPACER 1: Pushes content down on big screens ---
                      const Spacer(),

                      // --- LARGE WEIGHT TEXT DISPLAY ---
                      const SizedBox(height: 10),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: displayTarget.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF37C97D),
                              ),
                            ),
                            TextSpan(
                              text: _isKg ? ' kg' : ' lbs',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF37C97D),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- CUSTOM RULER ---
                      SizedBox(
                        height: 120, // Enough height for the CustomPainter
                        width: double.infinity,
                        child: GestureDetector(
                          onHorizontalDragUpdate: _handleDrag,
                          behavior: HitTestBehavior.opaque,
                          child: CustomPaint(
                            painter: RulerPainter(
                              targetValue: displayTarget,
                              currentValue: displayCurrent,
                              minValue: displayMin,
                              maxValue: displayMax,
                              pixelsPerUnit: _pixelsPerUnit,
                            ),
                          ),
                        ),
                      ),

                      // --- SPACER 2: Pushes the button down to the bottom ---
                      const Spacer(),

                      // --- CONTINUE BUTTON ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventsPage(
                                  widget.currentWeight,
                                  widget.heightCm,
                                  widget.age,
                                  widget.gender,
                                  _targetWeight,
                                  widget.dietaryGoal,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER ---
// --- CUSTOM PAINTER ---
class RulerPainter extends CustomPainter {
  final double targetValue;
  final double currentValue;
  final double minValue;
  final double maxValue;
  final double pixelsPerUnit;

  RulerPainter({
    required this.targetValue,
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.pixelsPerUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()..strokeCap = StrokeCap.round;

    // 1. Draw Blue Range Highlight
    double diff = currentValue - targetValue;
    double currentPixelOffset = diff * pixelsPerUnit;

    double left = centerX + math.min(0.0, currentPixelOffset);
    double width = currentPixelOffset.abs();

    if (width > 0) {
      // Light blue background behind ticks (Fills the big tick height perfectly)
      final rangePaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(left, 45, width, 40), rangePaint);

      // Darker blue top border (the "trail" line)
      final borderPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(left, 45), Offset(left + width, 45), borderPaint);
    }

    // 2. Draw Ticks & Numbers
    double visibleUnits = (size.width / pixelsPerUnit) / 2 + 1;
    int startIdx = (targetValue - visibleUnits).floor();
    int endIdx = (targetValue + visibleUnits).ceil();

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = startIdx; i <= endIdx; i++) {
      if (i < minValue || i > maxValue) continue;

      double offset = (i - targetValue) * pixelsPerUnit;
      double xPos = centerX + offset;

      // Draw Number (Placed at Y = 20)
      textPainter.text = TextSpan(
        text: "$i",
        style: TextStyle(
          color: (i == currentValue.round())
              ? Colors.black
              : Colors.grey.shade600,
          fontSize: 15,
          fontWeight: (i == currentValue.round())
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, 20));

      // Draw Big Tick (Aligns at bottom Y=85, stretches UP to Y=45)
      paint.color = Colors.grey.shade400;
      paint.strokeWidth = 2;
      canvas.drawLine(Offset(xPos, 45), Offset(xPos, 85), paint);

      // Draw Small Ticks
      paint.strokeWidth = 1;
      for (int j = 1; j < 10; j++) {
        double subOffset = offset + (j * (pixelsPerUnit / 10));
        double subX = centerX + subOffset;
        if (subX > -10 && subX < size.width + 10) {
          // Small ticks align at bottom Y=85, stretch UP to only Y=70
          canvas.drawLine(Offset(subX, 70), Offset(subX, 85), paint);
        }
      }
    }

    // 3. Draw "Current Weight" Marker (Black)
    double currentMarkX =
        centerX + (currentValue - targetValue) * pixelsPerUnit + 1;

    if (currentMarkX > -50 && currentMarkX < size.width + 50) {
      paint.color = Colors.black87;
      paint.strokeWidth = 3;

      // Black line perfectly matches big tick height
      canvas.drawLine(
        Offset(currentMarkX, 45),
        Offset(currentMarkX, 85),
        paint,
      );

      // Draw "Current" Text at the very top (Y = 0)
      textPainter.text = const TextSpan(
        text: "Current",
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(currentMarkX - textPainter.width / 2, 0),
      );
    }

    // 4. Draw "Target" Marker (Green Center Line)
    paint.color = Colors.green;
    paint.strokeWidth = 4;

    // Green line perfectly matches big tick height
    canvas.drawLine(Offset(centerX, 45), Offset(centerX, 85), paint);
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.targetValue != targetValue ||
        oldDelegate.currentValue != currentValue;
  }
}
