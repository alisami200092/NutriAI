import 'package:flutter/material.dart';

class NutrientsTab extends StatelessWidget {
  const NutrientsTab({super.key});

  final Color _primaryGreen = const Color(0xFF37C97D);
  final Color _blueLink = const Color(0xFF1976D2);
  final Color _redText = const Color(0xFFD32F2F);
  final Color _purpleText = const Color(0xFF7B1FA2);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Popular Nutrients",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Nutrient Cards
          _buildNutrientCard(
            title: "Saturated Fat",
            subtitle:
                "A diet too high in saturated fats may increase risk of heart disease.",
            icon: Icons.health_and_safety,
            iconColor: Colors.purple,
            trailingWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Set Limit",
                  style: TextStyle(
                    color: _blueLink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text("log", style: TextStyle(color: _blueLink, fontSize: 13)),
              ],
            ),
          ),

          _buildNutrientCard(
            title: "Trans Fat",
            subtitle:
                "Trans fats (from partially hydrogenated oils) increase heart disease risk.",
            icon: Icons.water_drop,
            iconColor: const Color(0xFF1A237E), // Dark Blue
            trailingWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _redText,
                    ),
                    children: const [
                      TextSpan(text: "0"),
                      TextSpan(text: "g", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Text("log", style: TextStyle(color: _blueLink, fontSize: 13)),
              ],
            ),
          ),

          _buildNutrientCard(
            title: "Dietary Fiber",
            subtitle:
                "Provides multiple health benefits, only found in plant foods. 22g recommended.",
            // Visual tweak: The screenshot shows this text aligned left, possibly without an icon or a white one.
            // I'll leave the icon null to match the screenshot layout closely,
            // or you can add Icons.grass if you prefer.
            icon: null,
            iconColor: Colors.green,
            trailingWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _redText,
                    ),
                    children: const [
                      TextSpan(text: "0"),
                      TextSpan(text: "g", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Text("log", style: TextStyle(color: _blueLink, fontSize: 13)),
              ],
            ),
          ),

          _buildNutrientCard(
            title: "Salt",
            subtitle: "Too much may raise blood pressure. more than 5.8g",
            icon:
                Icons.medical_services_outlined, // Placeholder for 'bone' icon
            iconColor: const Color(0xFFD7CCC8), // Beige/Bone color
            trailingWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _purpleText,
                    ),
                    children: const [
                      TextSpan(text: "5.1"),
                      TextSpan(text: "g", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Text("log", style: TextStyle(color: _blueLink, fontSize: 13)),
              ],
            ),
          ),

          _buildNutrientCard(
            title: "Calcium",
            subtitle:
                "Essential for teeth, muscle function. No more than 2500mg.",
            icon: Icons.kitchen, // Placeholder for salt shaker/bottle
            iconColor: Colors.blue.shade300,
            trailingWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _purpleText,
                    ),
                    children: const [
                      TextSpan(text: "9950"),
                      TextSpan(text: "mg", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Text("log", style: TextStyle(color: _blueLink, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildPremiumCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNutrientCard({
    required String title,
    required String subtitle,
    IconData? icon,
    Color? iconColor,
    required Widget trailingWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Section
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 4),
              child: Icon(icon, color: iconColor, size: 28),
            ),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Trailing Values & Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              trailingWidget,
              const SizedBox(width: 4),
              const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Apple Icon Teaser
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  children: [
                    const Icon(Icons.apple, color: Colors.lightGreen, size: 42),
                    Positioned(
                      bottom: 5,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(2),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Select up to 104 nutrients for tracking and set custom targets with custorts with Premium membership.",
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                "Upgrade to Premium",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
