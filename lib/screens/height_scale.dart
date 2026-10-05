import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_unit_ruler/flutter_unit_ruler.dart';
import 'age.dart';

class HeightScalePage extends StatefulWidget {
  final String selectedGender;
  const HeightScalePage({super.key, required this.selectedGender});

  @override
  State<HeightScalePage> createState() => _HeightScalePageState();
}

class _HeightScalePageState extends State<HeightScalePage> {
  double _heightCm = 178.0;
  bool _isCm = true;
  late final ScaleController _rulerController;
  late ScaleUnit _rulerUnit;
  late String avatarImage;

  @override
  void initState() {
    super.initState();
    _rulerUnit = UnitType.length.centimeter;
    _rulerController = ScaleController(value: _heightCm);

    //Assign avatar image based on selected gender
    avatarImage = widget.selectedGender == "Male"
        ? "assets/images/male.jpg"
        : "assets/images/female.jpg";
  }

  void _toggleUnit(bool useCm) {
    if (_isCm == useCm) return;

    setState(() {
      if (useCm) {
        _heightCm = _rulerController.value * 2.54;
        _rulerUnit = UnitType.length.centimeter;
        _rulerController.value = _heightCm;
      } else {
        double inches = _heightCm / 2.54;
        _rulerUnit = UnitType.length.inch;
        _rulerController.value = inches;
      }
      _isCm = useCm;
    });
  }

  String _displayValue() {
    if (_isCm) {
      return "${_heightCm.toInt()} cm";
    } else {
      double inches = _heightCm / 2.54;
      int feet = inches ~/ 12;
      int remInches = (inches % 12).round();
      return "$feet ft $remInches in";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Lottie.asset(
              "assets/animations/robot-working.json",
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 10),
            Image.asset(
              "assets/images/height_symbol.jpg",
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.error, size: 80, color: Colors.red),
            ),
            const SizedBox(height: 10),
            const Text(
              "What is your height?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Unit toggle
            Container(
              width: 140,
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggleUnit(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCm ? Colors.green : Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "cm",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isCm ? Colors.white : Colors.black,
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
                          color: !_isCm ? Colors.green : Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "ft",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: !_isCm ? Colors.white : Colors.black,
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
            Expanded(
              child: SizedBox(
                height: screenH * 0.6,
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      top: 0,
                      bottom: 0,
                      child: UnitRuler(
                        height: screenH * 0.6,
                        width: screenW,
                        controller: _rulerController,
                        scrollDirection: Axis.vertical,
                        backgroundColor: Colors.white,
                        scaleUnit: _rulerUnit,
                        scalePadding: const EdgeInsets.only(
                          left: 0,
                          right: 0,
                          top: 50,
                        ),
                        scaleMargin: 120,
                        scaleAlignment: Alignment.topRight,
                        scaleIntervalText: (index, value) {
                          if (_isCm) {
                            return "${value.toInt()}";
                          } else {
                            if (value % 12 == 0) {
                              int feet = (value / 12).toInt();
                              return "$feet ft";
                            }
                            return "";
                          }
                        },
                        scaleIntervalTextStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        scaleIntervalTextPosition: 245,
                        scaleIntervalStyles: const [
                          ScaleIntervalStyle(
                            color: Colors.yellow,
                            width: 35,
                            height: 2,
                            scale: -1,
                          ),
                          ScaleIntervalStyle(
                            color: Colors.blue,
                            width: 50,
                            height: 2.5,
                            scale: 0,
                          ),
                          ScaleIntervalStyle(
                            color: Colors.redAccent,
                            width: 40,
                            height: 2,
                            scale: 5,
                          ),
                        ],
                        scaleMarker: Container(
                          height: 2,
                          width: 240,
                          color: const Color(0xFF3EB48C),
                        ),

                        scaleMarkerPositionTop: 50,
                        scaleMarkerPositionLeft: 150,
                        onValueChanged: (val) {
                          setState(() {
                            _heightCm = _isCm
                                ? val.toDouble()
                                : val.toDouble() * 2.54;
                          });
                        },
                      ),
                    ),

                    // Value above the marker
                    Positioned(
                      bottom: 220,
                      left: 130,
                      child: Text(
                        _displayValue(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),

                    // Avatar
                    Positioned(
                      top: (screenH * 0.6) * 0.11,
                      left: ((screenW - 200) / 2) + 10,
                      child: Image.asset(
                        avatarImage,
                        height: (screenH * 0.6) * 0.8,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgeSelectionPage(
                        selectedGender: widget.selectedGender,
                        heightCm: _heightCm,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
