import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

// Helper function to handle Firestore varying data types (Map vs List) safely
Map<String, dynamic> _extractServingInfo(dynamic rawServingData) {
  if (rawServingData == null) return {'grams': 100, 'label': '100g'};
  if (rawServingData is Map) return Map<String, dynamic>.from(rawServingData);
  if (rawServingData is List && rawServingData.isNotEmpty) {
    var firstItem = rawServingData.first;
    if (firstItem is Map) return Map<String, dynamic>.from(firstItem);
  }
  return {'grams': 100, 'label': '100g'};
}

class FoodSearchScreen extends StatefulWidget {
  final String mealType;

  const FoodSearchScreen({super.key, required this.mealType});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: screenWidth,
          height: screenWidth,
          child: Column(
            children: [
              const SizedBox(height: 25),
              Text(
                "SEARCH ${widget.mealType.toUpperCase()}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "Search db...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('meals')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.cyanAccent,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Database empty",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    var foods = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();

                    if (foods.isEmpty) {
                      return const Center(
                        child: Text(
                          "No results",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: foods.length,
                      itemBuilder: (context, index) {
                        var foodData =
                            foods[index].data() as Map<String, dynamic>;
                        String name = foodData['name'] ?? 'Unknown';
                        num calPer100 = foodData['caloriesPer100g'] ?? 0;

                        Map<String, dynamic> servingSizes = _extractServingInfo(
                          foodData['servingSizes'],
                        );
                        String label = servingSizes['label'] ?? '100g';

                        return _SearchItemCard(
                          name: name,
                          calories: calPer100.toInt(),
                          unit: label,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodPortionScreen(
                                  mealType: widget.mealType,
                                  foodData: foodData,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchItemCard extends StatelessWidget {
  final String name;
  final int calories;
  final String unit;
  final VoidCallback onTap;

  const _SearchItemCard({
    required this.name,
    required this.calories,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text("🍽️", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    unit,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),
            Column(
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
                  "/100g",
                  style: TextStyle(color: Colors.grey, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REDESIGNED PORTION SCREEN (NO OVERFLOW, MULTIPLE UNITS)
// ============================================================================

class FoodPortionScreen extends StatefulWidget {
  final String mealType;
  final Map<String, dynamic> foodData;

  const FoodPortionScreen({
    super.key,
    required this.mealType,
    required this.foodData,
  });

  @override
  State<FoodPortionScreen> createState() => _FoodPortionScreenState();
}

class _FoodPortionScreenState extends State<FoodPortionScreen> {
  final Logger _logger = Logger();

  double quantity = 1.0;
  String selectedUnit = 'Serving';
  bool isSaving = false;

  final List<String> availableUnits = ['Serving', 'g', 'oz', 'tbsp'];

  // Calculate total grams based on the unit selected
  double _calculateTotalGrams(num gramsPerServing) {
    switch (selectedUnit) {
      case 'g':
        return quantity;
      case 'oz':
        return quantity * 28.3495; // 1 oz = 28.35g
      case 'tbsp':
        return quantity * 15.0; // 1 tbsp approx 15g
      case 'Serving':
      default:
        return quantity * gramsPerServing.toDouble();
    }
  }

  void _handleUnitChange(String newUnit) {
    setState(() {
      selectedUnit = newUnit;
      // Provide sensible defaults when switching units
      if (newUnit == 'g') {
        quantity = 100.0;
      } else if (newUnit == 'oz' || newUnit == 'tbsp' || newUnit == 'Serving') {
        quantity = 1.0;
      }
    });
  }

  void _incrementQuantity() {
    setState(() {
      if (selectedUnit == 'g') {
        quantity += 10; // Jump by 10g for speed
      } else {
        quantity += 0.5; // Jump by 0.5 for Serving/oz/tbsp
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (selectedUnit == 'g' && quantity > 10) {
        quantity -= 10;
      } else if (quantity > 0.5) {
        quantity -= 0.5;
      }
    });
  }

  void _saveMeal() async {
    setState(() => isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      num calPer100 = widget.foodData['caloriesPer100g'] ?? 0;
      num proteinPer100 = widget.foodData['proteinPer100g'] ?? 0;
      num carbsPer100 = widget.foodData['carbsPer100g'] ?? 0;
      num fatPer100 =
          (widget.foodData['monounsaturatedFatPer100g'] ?? 0) +
          (widget.foodData['polyunsaturatedFatPer100g'] ?? 0) +
          (widget.foodData['saturatedPer100g'] ?? 0);

      Map<String, dynamic> servingInfo = _extractServingInfo(
        widget.foodData['servingSizes'],
      );
      num gramsPerServing = servingInfo['grams'] ?? 100;

      // Calculate final nutrition based on selected unit
      double totalGrams = _calculateTotalGrams(gramsPerServing);
      int totalCalories = ((calPer100 / 100) * totalGrams).round();
      double totalProtein = (proteinPer100 / 100) * totalGrams;
      double totalCarbs = (carbsPer100 / 100) * totalGrams;
      double totalFat = (fatPer100 / 100) * totalGrams;

      String displayQuantity = quantity % 1 == 0
          ? quantity.toInt().toString()
          : quantity.toStringAsFixed(1);
      String savedUnitLabel = selectedUnit == 'Serving'
          ? servingInfo['label']
          : selectedUnit;

      await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(today)
          .collection(widget.mealType.toLowerCase())
          .add({
            'name': widget.foodData['name'],
            'calories': totalCalories,
            'protein': totalProtein,
            'carbs': totalCarbs,
            'fats': totalFat,
            'unit': "${displayQuantity}x $savedUnitLabel",
            'grams': totalGrams,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => isSaving = false);
      _logger.e("Error saving meal: $e"); // Replaced print with logger!
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.foodData['name'] ?? 'Food';
    Map<String, dynamic> servingInfo = _extractServingInfo(
      widget.foodData['servingSizes'],
    );
    num gramsPerServing = servingInfo['grams'] ?? 100;
    num calPer100 = widget.foodData['caloriesPer100g'] ?? 0;

    // Calculate dynamic calories to display
    double totalGrams = _calculateTotalGrams(gramsPerServing);
    int displayCalories = ((calPer100 / 100) * totalGrams).round();

    // Format quantity display
    String qtyText = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: Colors.black,
      body: isSaving
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          // 1. USE SingleChildScrollView to prevent overflow!
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),

                    // Display dynamic calories
                    Text(
                      "$displayCalories",
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "KCAL",
                      style: TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                    const SizedBox(height: 10),

                    // 2. COMPACT UNIT SELECTOR (Horizontal Scroll)
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: availableUnits.length,
                        itemBuilder: (context, index) {
                          String unit = availableUnits[index];
                          bool isSelected = selectedUnit == unit;
                          return GestureDetector(
                            onTap: () => _handleUnitChange(unit),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.cyanAccent.withValues(alpha: 0.2)
                                    : Colors.white10,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.cyanAccent
                                      : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.cyanAccent
                                        : Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. QUANTITY ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.redAccent,
                            size: 30,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _decrementQuantity,
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: 50,
                          child: Text(
                            qtyText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.greenAccent,
                            size: 30,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _incrementQuantity,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 4. LOG BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 8,
                        ),
                      ),
                      onPressed: _saveMeal,
                      child: const Text(
                        "LOG",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ), // Bottom padding for watch curve
                  ],
                ),
              ),
            ),
    );
  }
}
