import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added Auth
import 'package:nutriapp/meal_log/manual-meal-log/manual_search_page.dart';
import 'package:nutriapp/meal_log/manual-meal-log/serving_size_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:easy_localization/easy_localization.dart';

final logger = Logger();

class ServingSizePage extends StatefulWidget {
  final Meal meal;
  final String mealCategory;
  final DateTime logDate;

  const ServingSizePage({
    super.key,
    required this.meal,
    required this.mealCategory,
    required this.logDate,
  });

  @override
  State<ServingSizePage> createState() => _ServingSizePageState();
}

class _ServingSizePageState extends State<ServingSizePage> {
  final TextEditingController _amountController = TextEditingController();

  double _enteredAmount = 100;
  String _selectedUnit = 'g';
  late DateTime _selectedDate;

  int _displayCals = 0;
  double _displayCarbs = 0;
  double _displayProtein = 0;
  double _displayFat = 0;

  late List<ServingOption> _smartServingOptions;
  late Map<String, double> _unitMultipliers;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.logDate;
    _smartServingOptions = ServingSizeHelper.getSmartServingSizes(
      foodName: widget.meal.name,
      dbServingSizes: widget.meal.servingSizes,
    );
    _unitMultipliers = ServingSizeHelper.getSmartUnitMultipliers(
      foodName: widget.meal.name,
      options: _smartServingOptions,
    );
    _loadFavoriteStatus();
    _initializeDefaults();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('favorite_food_ids') ?? [];
      final key = widget.meal.id.isNotEmpty
          ? widget.meal.id
          : widget.meal.name.toLowerCase();
      if (mounted) {
        setState(() {
          _isFavorite = favList.contains(key) ||
              favList.contains(widget.meal.name.toLowerCase());
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('favorite_food_ids') ?? [];
      final key = widget.meal.id.isNotEmpty
          ? widget.meal.id
          : widget.meal.name.toLowerCase();
      setState(() {
        if (_isFavorite) {
          favList.remove(key);
          favList.remove(widget.meal.name.toLowerCase());
          _isFavorite = false;
        } else {
          favList.add(key);
          _isFavorite = true;
        }
      });
      await prefs.setStringList('favorite_food_ids', favList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? "${widget.meal.name} ${"added to Favorites".tr()}"
                : "${widget.meal.name} ${"removed from Favorites".tr()}"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  double get _actualGrams {
    if (_unitMultipliers.containsKey(_selectedUnit)) {
      return _enteredAmount * _unitMultipliers[_selectedUnit]!;
    }
    return _enteredAmount;
  }

  void _initializeDefaults() {
    if (_smartServingOptions.isNotEmpty) {
      final firstOption = _smartServingOptions[0];
      if (firstOption.unit != null &&
          firstOption.unit != 'g' &&
          _unitMultipliers.containsKey(firstOption.unit)) {
        _selectedUnit = firstOption.unit!;
        final multiplier = _unitMultipliers[firstOption.unit]!;
        final double amount = firstOption.grams / multiplier;
        _enteredAmount = amount;
        _amountController.text = amount % 1 == 0
            ? amount.toInt().toString()
            : amount.toStringAsFixed(1);
      } else {
        _selectedUnit = 'g';
        _enteredAmount = firstOption.grams;
        _amountController.text = firstOption.grams % 1 == 0
            ? firstOption.grams.toInt().toString()
            : firstOption.grams.toStringAsFixed(0);
      }
    } else {
      _enteredAmount = 100;
      _amountController.text = "100";
      _selectedUnit = 'g';
    }
    _recalculateMacros();
  }

  void _recalculateMacros() {
    double actualGrams = _actualGrams;
    double ratio = actualGrams / 100.0;

    setState(() {
      _displayCals = (widget.meal.caloriesPer100g * ratio).round();
      _displayCarbs = widget.meal.carbs * ratio;
      _displayProtein = widget.meal.protein * ratio;
      _displayFat = widget.meal.fat * ratio;
    });
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) {
      setState(() {
        _enteredAmount = 0;
        _recalculateMacros();
      });
      return;
    }
    double? parsed = double.tryParse(val);
    if (parsed != null) {
      setState(() {
        _enteredAmount = parsed;
        _recalculateMacros();
      });
    }
  }

  void _applyQuickOption(ServingOption option) {
    setState(() {
      if (option.unit != null &&
          option.unit != 'g' &&
          _unitMultipliers.containsKey(option.unit)) {
        _selectedUnit = option.unit!;
        final multiplier = _unitMultipliers[option.unit]!;
        final double amount = option.grams / multiplier;
        _enteredAmount = amount;
        _amountController.text = amount % 1 == 0
            ? amount.toInt().toString()
            : amount.toStringAsFixed(1);
      } else {
        _selectedUnit = 'g';
        _enteredAmount = option.grams;
        _amountController.text = option.grams % 1 == 0
            ? option.grams.toInt().toString()
            : option.grams.toStringAsFixed(1);
      }
      _recalculateMacros();
    });
  }

  String _getDateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  // --- ✅ UPDATED FIRESTORE LOGIC ---
  Future<void> _logMealToFirestore() async {
    try {
      // 1. Get User ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: You must be logged in.".tr())),
        );
        return;
      }
      final uid = user.uid;

      final dateKey = _getDateKey(_selectedDate);
      final category = widget.mealCategory
          .toLowerCase(); // 'breakfast', 'lunch', etc.

      // 2. Prepare Data
      final data = {
        'name': widget.meal.name,
        // Base Info
        'caloriesPer100g': widget.meal.caloriesPer100g,
        'carbsPer100g': widget.meal.carbs,
        'proteinPer100g': widget.meal.protein,
        'saturatedFatPer100g': widget.meal.fat,
        // Calculated Values
        'calories': _displayCals,
        'estCalories': _displayCals,
        'carbs': _displayCarbs,
        'protein': _displayProtein,
        'fat': _displayFat,
        // Log Details
        'servingSizes': widget.meal.servingSizes,
        'loggedServing': {
          'amount': _enteredAmount,
          'unit': _selectedUnit,
          'calculatedGrams': _actualGrams,
        },
        // Metadata
        'date': dateKey,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 3. ✅ Save to mealslog -> uid -> days -> date -> category
      await FirebaseFirestore.instance
          .collection('mealslog') // Global DB
          .doc(uid) // Specific User
          .collection('days') // Structural Collection
          .doc(dateKey) // Specific Date
          .collection(category) // "breakfast", "lunch", "dinner", "snack"
          .add(data);

      // 4. Save to Recent Searches locally
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawRecent = prefs.getStringList('recent_food_searches') ?? [];
        final itemJson =
            '${widget.meal.id}:::${widget.meal.name}:::${widget.meal.caloriesPer100g}:::${widget.meal.carbs}:::${widget.meal.protein}:::${widget.meal.fat}';
        rawRecent.removeWhere(
          (item) => item.contains(':::${widget.meal.name}:::'),
        );
        rawRecent.insert(0, itemJson);
        if (rawRecent.length > 25) rawRecent.removeRange(25, rawRecent.length);
        await prefs.setStringList('recent_food_searches', rawRecent);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"Logged".tr()} ${widget.meal.name} ${"to".tr()} ${widget.mealCategory.tr()}")),
        );
        // Pop back to dashboard/log list
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e("Error logging food: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${"Error saving".tr()}: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.brown[800],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                widget.meal.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=2000&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: _onAmountChanged,
                              style: TextStyle(
                                fontSize: 36,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedUnit,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.blue,
                            ),
                            underline: Container(),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 18,
                            ),
                            items: _unitMultipliers.keys.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedUnit = val;
                                  _recalculateMacros();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$_displayCals",
                            style: const TextStyle(
                              fontSize: 40,
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "cals".tr(),
                            style: const TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${"Weight".tr()}: ${_actualGrams.toStringAsFixed(0)}g",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _smartServingOptions.map((opt) {
                        return _buildOptionChip(opt);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('d MMM').format(_selectedDate),
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text("Grade".tr(), style: const TextStyle(fontSize: 12)),
                          const Text(
                            "A",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: _isFavorite ? Colors.amber : Colors.blue,
                        ),
                        label: Text(
                          _isFavorite ? "Favorited".tr() : "Favorite".tr(),
                          style: TextStyle(
                            color:
                                _isFavorite ? Colors.amber[800] : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Food Macros".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: [
                                _buildPieSection(
                                  Colors.teal,
                                  _displayCarbs,
                                  "Carbs".tr(),
                                ),
                                _buildPieSection(
                                  Colors.purple,
                                  _displayProtein,
                                  "Prot".tr(),
                                ),
                                _buildPieSection(
                                  Colors.amber,
                                  _displayFat,
                                  "Fat".tr(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                "Carbs".tr(),
                                _displayCarbs,
                                Colors.teal,
                              ),
                              const SizedBox(height: 5),
                              _buildLegendItem(
                                "Protein".tr(),
                                _displayProtein,
                                Colors.purple,
                              ),
                              const SizedBox(height: 5),
                              _buildLegendItem(
                                "Fat".tr(),
                                _displayFat,
                                Colors.amber,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C853),
        onPressed: _logMealToFirestore,
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildOptionChip(ServingOption opt) {
    bool isSelected = (_actualGrams - opt.grams).abs() < 1.0;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(opt.label.tr()),
        selected: isSelected,
        onSelected: (_) => _applyQuickOption(opt),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue[900] : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.blue[900],
        side: const BorderSide(color: Colors.transparent),
      ),
    );
  }

  PieChartSectionData _buildPieSection(
    Color color,
    double value,
    String title,
  ) {
    final val = value <= 0 ? 0.001 : value;
    return PieChartSectionData(color: color, value: val, title: "", radius: 45);
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(
          "${value.toStringAsFixed(1)}g",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
