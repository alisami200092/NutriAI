import 'package:flutter/material.dart';

class NutrientSummaryScreen extends StatelessWidget {
  const NutrientSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: screenWidth,
          height: screenWidth, // Ensures circular bounds
          // 1. Wrap in SingleChildScrollView to prevent overflow
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20), // Top padding for round screen
                // --- TIME ---
                const Text(
                  "13:30",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 15), // Replaces Spacer()
                // --- NUTRIENTS LIST ---
                // Total Carbs
                const _NutrientBar(
                  label: "Total Carbs",
                  consumed: 78,
                  left: 158,
                  progress: 0.33,
                ),

                const SizedBox(
                  height: 8,
                ), // Reduced spacing slightly to fit better
                // Protein
                const _NutrientBar(
                  label: "Protein",
                  consumed: 81,
                  left: 24,
                  progress: 0.77,
                ),

                const SizedBox(height: 8),

                // Fat
                const _NutrientBar(
                  label: "Fat",
                  consumed: 45,
                  left: 20,
                  progress: 0.60,
                ),

                const SizedBox(height: 15), // Replaces Spacer()
                // --- PAGINATION DOTS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Dot(isActive: false),
                    const SizedBox(width: 4),
                    const _Dot(isActive: true),
                    const SizedBox(width: 4),
                    const _Dot(isActive: false),
                  ],
                ),

                const SizedBox(height: 30), // Bottom padding for round screen
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM WIDGETS
// ---------------------------------------------------------------------------

class _NutrientBar extends StatelessWidget {
  final String label;
  final int consumed;
  final int left;
  final double progress; // 0.0 to 1.0

  const _NutrientBar({
    required this.label,
    required this.consumed,
    required this.left,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2), // Tighter spacing
        // Progress Bar Stack
        SizedBox(
          width: 140, // Slightly narrower to ensure it fits width-wise
          height: 6,
          child: Stack(
            children: [
              // Background Bar (Grey)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Foreground Bar (Green)
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853), // Vivid Green
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 2), // Tighter spacing
        // Subtitle Text
        Text(
          "${consumed}g, left ${left}g",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isActive;
  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[700],
        shape: BoxShape.circle,
      ),
    );
  }
}
