import 'package:flutter/material.dart';

class ExercisePlanTab extends StatelessWidget {
  const ExercisePlanTab({super.key});

  final Color _primaryGreen = const Color(0xFF37C97D);
  final Color _blueLink = const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Goal Header (Kept from previous request)
          _buildGoalHeaderCard(),
          const SizedBox(height: 24),

          // 2. New Exercise Settings Card
          _buildExerciseSettingsCard(),
          const SizedBox(height: 24),

          // 3. New Premium Promo Card (Green Button Style)
          _buildPremiumPromoCard(),
          const SizedBox(height: 32),

          // 4. Bottom Links (Left Aligned)
          _buildBottomLinks(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- 1. Top Goal Header ---
  Widget _buildGoalHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.rowing,
              size: 32,
              color: Colors.blueGrey.shade400,
            ),
          ),
          Expanded(
            child: const Text(
              "I plan to lose 5.5 kg in 65 days by eating less than 1,600 cals",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(Icons.keyboard_arrow_down, color: _blueLink, size: 28),
          ),
        ],
      ),
    );
  }

  // --- 2. Exercise Settings Card ---
  Widget _buildExerciseSettingsCard() {
    return Container(
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          // Top Padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Exercise Settings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "off",
                      style: TextStyle(
                        color: _blueLink,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Switch Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add Exercise to Calorie Budget",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: true,
                        onChanged: (val) {},
                        activeThumbColor: Colors.white,
                        activeTrackColor: _primaryGreen,
                      ),
                    ),
                  ],
                ),

                // Description
                const SizedBox(height: 8),
                Text(
                  "Automatically adds calories burned during exercise to your daily budget.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Activity Level Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Activity Level",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _blueLink,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Moderate",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Premium Promo Card ---
  Widget _buildPremiumPromoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green Icon Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Smarter Your Full Potential!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Access weekly exercise to create more accurate different targets and included.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // "Get Results" Link
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Get Results",
              style: TextStyle(
                color: _blueLink,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Center Text
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
              children: [
                const TextSpan(
                  text:
                      "Access weekly exercise planners, custom advanced workout routine calorie tracking and exclusive workout tips with ",
                ),
                TextSpan(
                  text: "Premium",
                  style: TextStyle(
                    color: _blueLink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Green Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Go Premium",
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

  // --- 4. Bottom Links ---
  Widget _buildBottomLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {},
          child: Text(
            "Help & Tips",
            style: TextStyle(
              color: _blueLink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Text(
            "App Settings",
            style: TextStyle(
              color: _blueLink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Decoration
  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
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
