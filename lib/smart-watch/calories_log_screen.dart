import 'package:flutter/material.dart';

class CalorieRingScreen extends StatelessWidget {
  final int consumed;
  final int target; // Changed from 'left' to 'target'

  const CalorieRingScreen({
    super.key,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate how much is left safely
    int left = target - consumed;
    int displayLeft = left < 0 ? 0 : left; // If user overeats, show 0 left

    // 2. Calculate percentage for the ring
    double progress = target > 0 ? (consumed / target) : 0.0;

    // 3. Adaptive color logic
    Color progressColor;
    if (progress <= 1.0) {
      progressColor = const Color.fromARGB(255, 43, 186, 50); // Green
    } else if (progress <= 1.2) {
      progressColor = Colors.orangeAccent; // Warning Orange
    } else {
      progressColor = Colors.redAccent; // Over limit Red
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.8,
          heightFactor: 0.8,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final d = constraints.biggest.shortestSide;
              final stroke = d * 0.08;

              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: d,
                    height: d,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0), // Fills the ring
                      strokeWidth: stroke,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  SizedBox(
                    width: d - stroke * 2,
                    height: d - stroke * 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$consumed',
                            style: TextStyle(
                              fontSize: d * 0.22,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Left',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$displayLeft',
                            style: TextStyle(
                              fontSize: d * 0.16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
