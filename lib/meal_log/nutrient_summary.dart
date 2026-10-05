import 'package:flutter/material.dart';
import 'dart:math' as math;

class NutrientSummarySection extends StatelessWidget {
  final int totalCalories;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;
  final double totalFiber;
  final double totalSatFat;
  final double totalSalt;
  final double totalCalcium; // in mg

  const NutrientSummarySection({
    super.key,
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSatFat,
    required this.totalSalt,
    required this.totalCalcium,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate Percentages for Pie Chart
    final double totalMacros = totalCarbs + totalProtein + totalFat;
    final double carbPct = totalMacros > 0 ? (totalCarbs / totalMacros) : 0;
    final double proteinPct = totalMacros > 0
        ? (totalProtein / totalMacros)
        : 0;
    final double fatPct = totalMacros > 0 ? (totalFat / totalMacros) : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Meal Totals",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // --- CALORIE BAR ---
          _buildProgressBarRow(
            label: "Cals",
            valueText: "${totalCalories}cals",
            percentage:
                0.19, // You can make this dynamic based on daily budget later
            color: const Color(0xFF00C853), // Green
          ),
          const SizedBox(height: 15),

          // --- MACRO BARS ---
          Row(
            children: [
              Expanded(
                child: _buildSmallMacroBar(
                  "T. Carbs",
                  "${totalCarbs.toInt()}g",
                  carbPct,
                  const Color(0xFF00C853),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallMacroBar(
                  "Protein",
                  "${totalProtein.toInt()}g",
                  proteinPct,
                  const Color(0xFF9575CD),
                ), // Purple
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallMacroBar(
                  "Fat",
                  "${totalFat.toInt()}g",
                  fatPct,
                  const Color(0xFFFFC107),
                ), // Yellow
              ),
            ],
          ),
          const SizedBox(height: 25),

          // --- PIE CHART SECTION ---
          Row(
            children: [
              // Custom Pie Chart
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _MacroPiePainter(carbPct, proteinPct, fatPct),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    "T. Carbs",
                    "${totalCarbs.toInt()}g",
                    const Color(0xFF00C853),
                  ),
                  _buildLegendItem(
                    "Protein",
                    "${totalProtein.toInt()}g",
                    const Color(0xFF9575CD),
                  ),
                  _buildLegendItem(
                    "Fat",
                    "${totalFat.toInt()}g",
                    const Color(0xFFFFC107),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // --- DETAILED NUTRIENTS (Fiber, Sat Fat, etc.) ---
          // Using your screenshots style (Grouped headers)

          // 1. Fat Related
          const Text(
            "Fat-related",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            "Sat Fat",
            "${totalSatFat.toStringAsFixed(1)}g",
            Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          // Example of red bar for "Tr. Fat" or high Sat Fat
          _buildDetailRow("Tr. Fat", "0g", Colors.redAccent),

          const SizedBox(height: 20),

          // 2. Carbs Related
          const Text(
            "Carbs-related",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            "Fiber",
            "${totalFiber.toInt()}g",
            Colors.purpleAccent,
          ),

          const SizedBox(height: 20),

          // 3. Minerals
          const Text(
            "Minerals",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            "Salt",
            "${totalSalt.toStringAsFixed(1)}g",
            Colors.deepPurple.shade200,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            "Calcium",
            "${totalCalcium.toInt()}mg",
            Colors.deepPurple.shade200,
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildProgressBarRow({
    required String label,
    required String valueText,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              valueText,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildSmallMacroBar(
    String label,
    String value,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value:
                    0.4, // Static for demo, make dynamic if you have daily goals
                backgroundColor: Colors.grey.shade100,
                color: barColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- PAINTER FOR PIE CHART ---
class _MacroPiePainter extends CustomPainter {
  final double carbPct;
  final double proteinPct;
  final double fatPct;

  _MacroPiePainter(this.carbPct, this.proteinPct, this.fatPct);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    // Start angle (12 o'clock) is -pi/2
    double startAngle = -math.pi / 2;

    // 1. Carbs (Green)
    paint.color = const Color(0xFF00C853);
    final carbSweep = 2 * math.pi * carbPct;
    canvas.drawArc(rect, startAngle, carbSweep, true, paint);
    startAngle += carbSweep;

    // 2. Fat (Yellow)
    paint.color = const Color(0xFFFFC107);
    final fatSweep = 2 * math.pi * fatPct;
    canvas.drawArc(rect, startAngle, fatSweep, true, paint);
    startAngle += fatSweep;

    // 3. Protein (Purple)
    paint.color = const Color(0xFF9575CD);
    final _ = 2 * math.pi * proteinPct;
    // Fill the rest to avoid gaps due to rounding
    canvas.drawArc(
      rect,
      startAngle,
      (2 * math.pi) - (startAngle + math.pi / 2),
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
