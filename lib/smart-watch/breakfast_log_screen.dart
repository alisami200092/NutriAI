import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutriapp/smart-watch/search_food_screen.dart';
import 'nutrient_summary_screen.dart';

class BreakfastScreen extends StatelessWidget {
  const BreakfastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: const [_BreakfastContent(), NutrientSummaryScreen()],
    );
  }
}

class _BreakfastContent extends StatelessWidget {
  const _BreakfastContent();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: screenWidth,
          height: screenWidth,
          child: Column(
            children: [
              const SizedBox(height: 25),
              const Text(
                "BREAKFAST",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // READ DIRECTLY FROM 'breakfast' SUBCOLLECTION
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('mealslog')
                      .doc(uid)
                      .collection('days')
                      .doc(today)
                      .collection('breakfast')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.cyanAccent,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    // === IF EMPTY NO MEALS LOGGED STATE ===
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: Colors.grey[700],
                              size: 24,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "No meals logged\nby user",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // === IF USER LOGGED MEALS ===
                    var meals = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        var data = meals[index].data() as Map<String, dynamic>;
                        return _FoodItemCard(
                          icon: "🍽️",
                          name: data['name'] ?? 'Food',
                          calories: (data['calories'] ?? 0).toInt(),
                          unit: data['unit'] ?? '',
                        );
                      },
                    );
                  },
                ),
              ),

              // ADD BUTTON
              Padding(
                padding: const EdgeInsets.only(bottom: 25, top: 5),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FoodSearchScreen(mealType: "Breakfast"),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final String icon;
  final String name;
  final int calories;
  final String unit;

  const _FoodItemCard({
    required this.icon,
    required this.name,
    required this.calories,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$calories",
                style: const TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Kcal",
                style: TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
