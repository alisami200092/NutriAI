import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ExerciseListPage extends StatelessWidget {
  const ExerciseListPage({super.key});

  // Sample Data
  final List<Map<String, dynamic>> exercises = const [
    {"emoji": "🏃‍♂️", "name": "Running", "calories": "600 kcal/hr"},
    {"emoji": "🚴‍♀️", "name": "Cycling", "calories": "450 kcal/hr"},
    {"emoji": "🏊‍♂️", "name": "Swimming", "calories": "500 kcal/hr"},
    {"emoji": "🧘‍♀️", "name": "Yoga", "calories": "180 kcal/hr"},
    {"emoji": "🏋️‍♂️", "name": "Weightlifting", "calories": "300 kcal/hr"},
    {"emoji": "🥊", "name": "Boxing", "calories": "700 kcal/hr"},
    {"emoji": "🤸‍♀️", "name": "Gymnastics", "calories": "250 kcal/hr"},
    {"emoji": "🚶‍♂️", "name": "Walking", "calories": "200 kcal/hr"},
    {"emoji": "🧗‍♂️", "name": "Rock Climbing", "calories": "550 kcal/hr"},
    {"emoji": "💃", "name": "Dancing", "calories": "350 kcal/hr"},
    {"emoji": "🏄‍♂️", "name": "Surfing", "calories": "250 kcal/hr"},
    {"emoji": "⛹️‍♂️", "name": "Basketball", "calories": "600 kcal/hr"},
    {"emoji": "🎾", "name": "Tennis", "calories": "400 kcal/hr"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: Column(
        children: [
          // 1. Reusable Header
          _buildHeader(context),

          // 2. List of Exercises
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final item = exercises[index];
                return _buildExerciseCard(
                  emoji: item['emoji'],
                  name: item['name'],
                  calories: item['calories'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      // SafeArea padding
      padding: const EdgeInsets.only(top: 50, bottom: 25, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF3B9E83),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Text(
            "BROWSE".tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          // Placeholder for symmetry or filter icon
          const Icon(Icons.filter_list, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required String emoji,
    required String name,
    required String calories,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji Container
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Very light green
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 15),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A33),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calories,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add Action Button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Color(0xFF3B9E83), size: 20),
          ),
        ],
      ),
    );
  }
}
