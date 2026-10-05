import 'package:flutter/material.dart';
import 'package:nutriapp/meal_log/all-meals-sections/full_day_food_report.dart';
import 'package:nutriapp/services/fat_calculator_service.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';
import 'dart:math' as math;

class MacrosTab extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const MacrosTab({super.key, this.userData});

  final Color _blueLink = const Color(0xFF1976D2);
  final Color _blueButton = const Color(0xFF64B5F6);

  @override
  Widget build(BuildContext context) {
    final double calories = ((userData?['dailyCalorieTarget'] ?? 1800.0) as num).toDouble();
    final double weight = ((userData?['weight'] ?? 70.0) as num).toDouble();
    final String dietaryGoal = userData?['dietaryGoal'] ?? "Healthy Living";
    final MacroTargets macros = FatCalculatorService.calculateMacroTargets(
      weightKg: weight,
      calorieBudget: calories.toInt(),
      goal: dietaryGoal,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. New Custom Pie Chart Section
          _buildMacroPieChartCard(calories, macros),

          const SizedBox(height: 24),
          _buildCustomizingSection(),
          const SizedBox(height: 24),
          _buildInfoTextSection(),
          const SizedBox(height: 24),
          _buildAnalyzeButton(context),
          const SizedBox(height: 24),
          _buildBottomLinks(),
          const SizedBox(height: 32),
          _buildPremiumTeaser(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- 1. NEW PIE CHART CARD ---
  Widget _buildMacroPieChartCard(double calories, MacroTargets macros) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          const Text(
            "Macronutrient Breakdown Today",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Custom Pie Chart
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: MacroDonutPainter(
                carbPercent: macros.carbPercent / 100.0,
                proteinPercent: macros.proteinPercent / 100.0,
                fatPercent: macros.fatPercent / 100.0,
                carbGrams: "${macros.carbGrams.toStringAsFixed(0)}g",
                proteinGrams: "${macros.proteinGrams.toStringAsFixed(0)}g",
                fatGrams: "${macros.fatGrams.toStringAsFixed(0)}g",
              ),
              child: Center(
                child: Text(
                  "${calories.toInt()} kcal",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bottom Legend Icons (Wrapped to prevent any horizontal overflow)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                Icons.eco,
                "Carbs (${macros.carbPercent.toStringAsFixed(0)}%)",
                const Color(0xFF66BB6A),
              ),
              _buildLegendItem(
                Icons.fitness_center,
                "Protein (${macros.proteinPercent.toStringAsFixed(0)}%)",
                const Color(0xFF1976D2),
              ),
              _buildLegendItem(
                Icons.water_drop,
                "Fats (${macros.fatPercent.toStringAsFixed(0)}%)",
                const Color(0xFFFFA726),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // --- 2. EXISTING SECTIONS (Unchanged styling) ---

  Widget _buildCustomizingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Customizing Macros Targets",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Icon(Icons.lock, size: 16, color: Colors.amber.shade700),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Not customizing macros - using the distribution of calories selected above.",
          style: TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Set Custom Macros",
            style: TextStyle(
              color: _blueLink,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTextSection() {
    return const Text(
      "Calories are coming from macronutrients. A gram of carbs or protein provides 4 calories. A gram of fat provides 9 calories. The calorie budget you've set for yourself is distributed between macronutrients. If you increase one macronutrient, then another macronutrient has to decrease to keep your calorie budget the same.",
      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
    );
  }

  Widget _buildAnalyzeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayFoodReportPage(selectedDate: DateTime.now()),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _blueButton,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          "Analyze Nutrients & Calories",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {},
          child: Text(
            "About Macronutrients",
            style: TextStyle(
              color: _blueLink,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Text(
            "Read Planning Article",
            style: TextStyle(
              color: _blueLink,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTeaser(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _whiteCardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.apple, color: Colors.lightGreen, size: 40),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Icon(
                      Icons.star,
                      color: Colors.amber.shade400,
                      size: 12,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 8,
                    child: Icon(
                      Icons.star,
                      color: Colors.amber.shade400,
                      size: 10,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 0,
                    left: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) =>
                              Container(width: 1, color: Colors.green.shade200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Get Premium Planning",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Balance calories from Carbs, Protein and Fat. Enter grams or macronutrient ratio percentages - your nutrients will always match your calories.",
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// --- CUSTOM PAINTER CLASS ---
// This draws the specific Donut chart with lines pointing out
class MacroDonutPainter extends CustomPainter {
  final double carbPercent;
  final double proteinPercent;
  final double fatPercent;
  final String carbGrams;
  final String proteinGrams;
  final String fatGrams;

  MacroDonutPainter({
    this.carbPercent = 0.50,
    this.proteinPercent = 0.30,
    this.fatPercent = 0.20,
    this.carbGrams = "225g",
    this.proteinGrams = "135g",
    this.fatGrams = "40g",
  });

  // Colors based on the first image
  final Color proteinColor = const Color(0xFF1976D2); // Blue
  final Color fatsColor = const Color(0xFFFFA726); // Orange/Yellow
  final Color carbsColor = const Color(0xFF66BB6A); // Green

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius of the donut - scaled cleanly to leave ample room for indicator labels
    final radius = size.height * 0.28;
    final strokeWidth = size.height * 0.13;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // 1. Draw Arcs
    // The chart starts from top (-pi/2)
    // Protein (Blue)
    paint.color = proteinColor;
    const double startAngleProtein = -math.pi / 2;
    final double sweepAngleProtein = 2 * math.pi * proteinPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngleProtein,
      sweepAngleProtein,
      false,
      paint,
    );

    // Fats (Orange) - Starts where Protein ends
    paint.color = fatsColor;
    final double startAngleFats = startAngleProtein + sweepAngleProtein;
    final double sweepAngleFats = 2 * math.pi * fatPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngleFats,
      sweepAngleFats,
      false,
      paint,
    );

    // Carbs (Green) - Starts where Fats ends
    paint.color = carbsColor;
    final double startAngleCarbs = startAngleFats + sweepAngleFats;
    final double sweepAngleCarbs = 2 * math.pi * carbPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngleCarbs,
      sweepAngleCarbs,
      false,
      paint,
    );

    // 2. Draw Indicators (Lines + Text)
    void drawIndicator({
      required double angle,
      required String title,
      required String pct,
      required Color color,
      required bool isRightSide,
    }) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final outerRadius = radius + (strokeWidth / 2);
      final dx = center.dx + outerRadius * math.cos(angle);
      final dy = center.dy + outerRadius * math.sin(angle);
      final startPoint = Offset(dx, dy);

      final extension = 8.0;
      final kx = center.dx + (outerRadius + extension) * math.cos(angle);
      final ky = center.dy + (outerRadius + extension) * math.sin(angle);
      final kinkPoint = Offset(kx, ky);

      final lineLength = 12.0;
      final endX = isRightSide ? kx + lineLength : kx - lineLength;
      final endPoint = Offset(endX, ky);

      canvas.drawLine(startPoint, kinkPoint, linePaint);
      canvas.drawLine(kinkPoint, endPoint, linePaint);

      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: "$title\n",
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: pct,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: isRightSide ? TextAlign.left : TextAlign.right,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      double targetX = isRightSide ? endPoint.dx + 4 : endPoint.dx - textPainter.width - 4;
      // Clamp text position so it never overflows left or right screen edges
      if (isRightSide && targetX + textPainter.width > size.width - 4) {
        targetX = size.width - textPainter.width - 4;
      }
      if (!isRightSide && targetX < 4) {
        targetX = 4;
      }

      final textOffset = Offset(targetX, endPoint.dy - textPainter.height / 2);

      textPainter.paint(canvas, textOffset);
    }

    // Protein Label
    drawIndicator(
      angle: startAngleProtein + (sweepAngleProtein / 2),
      title: "Protein ($proteinGrams)",
      pct: "(${(proteinPercent * 100).toStringAsFixed(0)}%)",
      color: proteinColor,
      isRightSide: true,
    );

    // Fats Label
    drawIndicator(
      angle: startAngleFats + (sweepAngleFats / 2),
      title: "Fats ($fatGrams)",
      pct: "(${(fatPercent * 100).toStringAsFixed(0)}%)",
      color: fatsColor,
      isRightSide: true,
    );

    // Carbs Label
    drawIndicator(
      angle: startAngleCarbs + (sweepAngleCarbs / 2),
      title: "Carbs ($carbGrams)",
      pct: "(${(carbPercent * 100).toStringAsFixed(0)}%)",
      color: carbsColor,
      isRightSide: false,
    );
  }

  @override
  bool shouldRepaint(covariant MacroDonutPainter oldDelegate) =>
      oldDelegate.carbPercent != carbPercent ||
      oldDelegate.proteinPercent != proteinPercent ||
      oldDelegate.fatPercent != fatPercent;
}
