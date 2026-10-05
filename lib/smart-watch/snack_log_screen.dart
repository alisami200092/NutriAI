import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutriapp/smart-watch/search_food_screen.dart';
import 'nutrient_summary_screen.dart';

class SnackScreen extends StatelessWidget {
  const SnackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(children: const [_SnackContent(), NutrientSummaryScreen()]);
  }
}

class _SnackContent extends StatelessWidget {
  const _SnackContent();

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
              const SizedBox(height: 35),
              const Text(
                "SNACK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Logged Items",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 10),

              // DYNAMIC FIRESTORE LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('mealslog')
                      .doc(uid)
                      .collection('days')
                      .doc(today)
                      .collection('snack') // <-- Listens to snack
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

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apple,
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
                child: Column(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FoodSearchScreen(mealType: "Snack"),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "ADD FOOD",
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$calories",
                style: const TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const Text(
                "Kcal",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(height: 20, width: 1, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(unit, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
