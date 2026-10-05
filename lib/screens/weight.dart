import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_unit_ruler/flutter_unit_ruler.dart';
import 'package:nutriapp/screens/dietary_goals.dart';

class WeightPage extends StatefulWidget {
  final String dietaryGoal;
  final int selectedAge;
  final String selectedGender;
  final double heightCm;

  const WeightPage({
    super.key,
    required this.dietaryGoal,
    required this.selectedAge,
    required this.selectedGender,
    required this.heightCm,
  });

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  // Set default weight
  double _weightKg = 60.0;
  bool _isKg = true;
  late ScaleController _rulerController;
  late ScaleUnit _rulerUnit;

  // Scale limits (Increased to 500kg so it never runs out)
  final double _minWeight = 0.0;
  final double _maxWeight = 1500.0;

  // Sensitivity: 0.10 gives a very calm, slow, and precise 1:1 ruler feel
  final double _dragSensitivity = 0.1;

  double get _heightCm => widget.heightCm;

  final List<String> bmiCategories = [
    "Underweight",
    "Normal",
    "Overweight",
    "Obese",
    "Ext. Obese",
  ];

  @override
  void initState() {
    super.initState();
    _initRuler();
    // Initialize controller (value * 10 because scale has 10 subdivisions)
    _rulerController = ScaleController(value: _weightKg * 10);
  }

  void _initRuler() {
    // Generate scale for KG (0 to 500)
    _rulerUnit = ScaleUnit(
      name: 'kg',
      symbol: 'kg',
      subDivisionCount: 10,
      scaleIntervals: List.generate(
        (_maxWeight - _minWeight).toInt() + 1,
        (i) => ScaleIntervals(begin: i, end: i + 1, scale: 1),
      ),
    );
  }

  void _toggleUnit(bool useKg) {
    if (_isKg == useKg) return;
    setState(() {
      _isKg = useKg;
      double currentValue = _rulerController.value.toDouble();

      if (_isKg) {
        // Switch to KG
        _rulerUnit = ScaleUnit(
          name: 'kg',
          symbol: 'kg',
          subDivisionCount: 10,
          scaleIntervals: List.generate((_maxWeight - _minWeight + 1).toInt(), (
            i,
          ) {
            return ScaleIntervals(begin: i, end: i + 1, scale: 1);
          }),
        );
        // Convert Lbs -> Kg
        double newKgVal = (currentValue / 10) / 2.20462;
        _weightKg = newKgVal;
        _rulerController.value = newKgVal * 10;
      } else {
        // Switch to Lbs
        // Ensure we generate enough intervals for Lbs (500kg ~= 1100lbs)
        double maxLbs = _maxWeight * 2.20462;
        _rulerUnit = ScaleUnit(
          name: 'lb',
          symbol: 'lb',
          subDivisionCount: 10,
          scaleIntervals: List.generate(
            maxLbs.toInt() + 100, // Add buffer
            (i) => ScaleIntervals(begin: i, end: i + 1, scale: 1),
          ),
        );
        // Convert Kg -> Lbs
        double newLbsVal = (_weightKg * 2.20462);
        _rulerController.value = newLbsVal * 10;
      }
    });
  }

  // --- Logic to Handle Screen Swiping ---
  void _handleScreenDrag(DragUpdateDetails details) {
    // details.primaryDelta: negative = left drag, positive = right drag
    double delta = details.primaryDelta ?? 0;

    // Invert delta: dragging left should increase weight (move ruler right)
    double valueChange = -delta * _dragSensitivity;

    double currentValue = _rulerController.value.toDouble();
    double newValue = currentValue + valueChange;

    // Clamp values so it doesn't go below 0 or above Max
    double maxVal = _isKg ? (_maxWeight * 10) : (_maxWeight * 2.20462 * 10);
    newValue = newValue.clamp(0.0, maxVal);

    // Update Controller
    _rulerController.value = newValue;

    // Update State
    setState(() {
      if (_isKg) {
        _weightKg = newValue / 10;
      } else {
        _weightKg = (newValue / 10) / 2.20462;
      }
    });
  }

  double _calculateBMI() {
    if (_heightCm <= 0 || _weightKg <= 0) return 0.0;
    double heightM = _heightCm / 100;
    return _weightKg / (heightM * heightM);
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
    double clampedBMI = bmi.clamp(minBMI, maxBMI).toDouble();
    return ((clampedBMI - minBMI) / (maxBMI - minBMI)) * scaleWidth;
  }

  Widget _bmiLabel(String text, double bmiValue, double scaleWidth) {
    const double minBMI = 15.0;
    const double maxBMI = 40.0;
    double clampedBMI = bmiValue.clamp(minBMI, maxBMI).toDouble();
    double pos = ((clampedBMI - minBMI) / (maxBMI - minBMI)) * scaleWidth;
    if (bmiValue == 18.5) pos += 8;
    return Positioned(
      left: pos - 10,
      top: 0,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bmiValue = _calculateBMI();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dynamicScaleWidth = screenWidth - 60;
    String bmiStatus = _bmiCategory(bmiValue);
    final double rulerWidth = screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // GestureDetector handles horizontal swipes across the whole screen
        child: GestureDetector(
          onHorizontalDragUpdate: _handleScreenDrag,
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Lottie.asset(
                "assets/animations/robot-working.json",
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              Image.asset(
                "assets/images/weight.png",
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.error, size: 80, color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text(
                "What is your weight?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Unit Toggler
              Container(
                width: 140,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleUnit(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _isKg ? Colors.green : Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "kg",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isKg ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleUnit(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isKg ? Colors.green : Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "lbs",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: !_isKg ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BMI Text Display
              Column(
                children: [
                  const Text(
                    "Your Body Mass Index (BMI) is:",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bmiValue.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      children: [
                        const TextSpan(text: "Your BMI shows that you are: "),
                        TextSpan(
                          text: bmiStatus,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // BMI Scale Visual
              Column(
                children: [
                  // Labels
                  SizedBox(
                    width: dynamicScaleWidth,
                    height: 20,
                    child: Stack(
                      children: [
                        _bmiLabel("18.5", 18.5, dynamicScaleWidth),
                        _bmiLabel("25.0", 25.0, dynamicScaleWidth),
                        _bmiLabel("30.0", 30.0, dynamicScaleWidth),
                        _bmiLabel("35.0", 35.0, dynamicScaleWidth),
                      ],
                    ),
                  ),
                  // Colored Bar & Marker
                  SizedBox(
                    width: dynamicScaleWidth,
                    height: 8,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(child: Container(color: Colors.green)),
                            Expanded(child: Container(color: Colors.yellow)),
                            Expanded(child: Container(color: Colors.orange)),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: _calculateMarkerPosition(
                            bmiValue,
                            dynamicScaleWidth,
                          ).clamp(0, dynamicScaleWidth - 14),
                          top: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getDotColor(bmiValue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category Names
                  SizedBox(
                    width: dynamicScaleWidth,
                    child: Row(
                      children: bmiCategories.map((cat) {
                        return Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                cat,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const Spacer(), // Pushes the ruler and button down
              // Weight Unit Ruler
              SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    Positioned(
                      top: 30,
                      left: 0,
                      child: IgnorePointer(
                        // ✅ ignoring: true -> Disables direct touch on ruler, preventing conflicts.
                        // The user must slide on the screen (handled by GestureDetector above).
                        ignoring: true,
                        child: UnitRuler(
                          height: 50,
                          width: rulerWidth,
                          controller: _rulerController,
                          scrollDirection: Axis.horizontal,
                          scaleUnit: _rulerUnit,
                          scalePadding: EdgeInsets.symmetric(
                            horizontal: rulerWidth / 2,
                          ),
                          scaleMargin: 0,
                          scaleAlignment: Alignment.bottomCenter,
                          scaleIntervalText: (index, value) {
                            return (value / 10).toStringAsFixed(0);
                          },
                          scaleIntervalTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          scaleIntervalTextPosition: 30,
                          scaleMarker: Container(
                            height: 80,
                            width: 3,
                            color: Colors.transparent,
                          ),
                          scaleMarkerPositionTop: 0,
                          scaleMarkerPositionLeft: 0,
                          onValueChanged: (val) {},
                        ),
                      ),
                    ),
                    // Center Marker
                    Positioned(
                      top: 30,
                      left: (rulerWidth / 2) + 2.5,
                      child: Container(
                        height: 50,
                        width: 3,
                        color: Colors.green,
                      ),
                    ),
                    // Weight Value
                    Positioned(
                      top: 0,
                      left: (rulerWidth / 2) - 50,
                      child: Container(
                        width: 100,
                        alignment: Alignment.center,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: (_isKg
                                    ? _weightKg.toStringAsFixed(1)
                                    : (_weightKg * 2.20462).toStringAsFixed(1)),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              TextSpan(
                                text: _isKg ? ' kg' : ' lbs',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
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

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton.icon(
                  onPressed: () {
                    log("Selected Weight: $_weightKg kg, BMI: $bmiValue");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DietaryGoalsPage(
                          age: widget.selectedAge,
                          gender: widget.selectedGender,
                          heightCm: _heightCm,
                          currentWeight: _weightKg,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
