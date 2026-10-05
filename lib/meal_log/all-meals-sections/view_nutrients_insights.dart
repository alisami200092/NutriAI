import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/meal_log/all-meals-sections/full_day_food_report.dart';

class NutrientInsightsSection extends StatelessWidget {
  final DateTime selectedDate; // 1. Store the date

  const NutrientInsightsSection({
    super.key,
    required this.selectedDate, // 2. Require it in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Top Row: Icon + Text + Close Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bulb Icon in Circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Tap any nutrient to see insights".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),

              // Close Icon
              InkWell(
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.close, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Row: Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  // 3. Navigate to Day Food Report using the selected date
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DayFoodReportPage(selectedDate: selectedDate),
                    ),
                  );
                },
                child: Text(
                  "Day Food Report".tr(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () {
                  // Navigate to Targets (placeholder)
                },
                child: Text(
                  "Targets".tr(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
