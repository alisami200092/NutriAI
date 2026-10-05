import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/meal_log/manual-meal-log/serving_size_page.dart';
import 'package:nutriapp/meal_log/manual-meal-log/serving_size_helper.dart';
import 'package:nutriapp/meal_log/camera_screen.dart';
import 'package:easy_localization/easy_localization.dart';

// ==============================================================================
// 1. ROBUST DATA MODEL
// ==============================================================================
class Meal {
  final String id;
  final String name;
  final int caloriesPer100g;
  final double carbs;
  final double protein;
  final double fat;
  final List<Map<String, dynamic>> servingSizes;

  Meal({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.servingSizes,
  });

  factory Meal.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<Map<String, dynamic>> parsedServings = [];
    var rawServing = data['servingSizes'];

    if (rawServing is List) {
      parsedServings = List<Map<String, dynamic>>.from(
        rawServing.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    } else if (rawServing is Map) {
      parsedServings = [Map<String, dynamic>.from(rawServing)];
    }

    double sat = (data['saturatedPer100g'] ?? 0).toDouble();
    double mono = (data['monounsaturatedFatPer100g'] ?? 0).toDouble();
    double poly = (data['polyunsaturatedFatPer100g'] ?? 0).toDouble();
    double totalFat = (data['fatPer100g'] ?? (sat + mono + poly)).toDouble();

    return Meal(
      id: doc.id,
      name: data['name'] ?? 'Unknown Food',
      caloriesPer100g: (data['caloriesPer100g'] ?? 0).toInt(),
      carbs: (data['carbsPer100g'] ?? 0).toDouble(),
      protein: (data['proteinPer100g'] ?? 0).toDouble(),
      fat: totalFat,
      servingSizes: parsedServings,
    );
  }

  factory Meal.fromMap(Map<String, dynamic> data, {String? id}) {
    List<Map<String, dynamic>> parsedServings = [];
    var rawServing = data['servingSizes'];
    if (rawServing is List) {
      parsedServings = List<Map<String, dynamic>>.from(
        rawServing.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    } else if (rawServing is Map) {
      parsedServings = [Map<String, dynamic>.from(rawServing)];
    }

    return Meal(
      id: id ?? (data['id'] ?? ''),
      name: data['name'] ?? 'Unknown Food',
      caloriesPer100g: (data['caloriesPer100g'] ?? 0).toInt(),
      carbs: (data['carbsPer100g'] ?? 0).toDouble(),
      protein: (data['proteinPer100g'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      servingSizes: parsedServings,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'caloriesPer100g': caloriesPer100g,
        'carbs': carbs,
        'protein': protein,
        'fat': fat,
        'servingSizes': servingSizes,
      };

  String get defaultServingLabel {
    final smartOptions = ServingSizeHelper.getSmartServingSizes(
      foodName: name,
      dbServingSizes: servingSizes,
    );
    if (smartOptions.isNotEmpty) {
      return smartOptions.first.label;
    }
    return "100g";
  }

  int get defaultServingCalories {
    final smartOptions = ServingSizeHelper.getSmartServingSizes(
      foodName: name,
      dbServingSizes: servingSizes,
    );
    if (smartOptions.isNotEmpty) {
      return ((caloriesPer100g / 100.0) * smartOptions.first.grams).round();
    }
    return caloriesPer100g;
  }
}

// ==============================================================================
// 2. SEARCH PAGE UI
// ==============================================================================
class ManualMealSearchPage extends StatefulWidget {
  final String mealCategory;
  final DateTime logDate;
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const ManualMealSearchPage({
    super.key,
    required this.mealCategory,
    required this.logDate,
    required this.cameras,
    required this.yolo,
  });

  @override
  State<ManualMealSearchPage> createState() => _ManualMealSearchPageState();
}

class _ManualMealSearchPageState extends State<ManualMealSearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<String> _tabs = [
    "Search",
    "Staples",
    "Favorites",
    "Frequents",
    "Recent",
  ];

  final List<String> _categoryFilters = [
    "All",
    "High Protein",
    "Low Carb",
    "Traditional",
    "Beverages",
    "Snacks",
  ];
  String _selectedCategoryFilter = "All";

  // Dynamic Recent and Favorite states
  List<Meal> _recentMeals = [];
  Set<String> _favoriteMealKeys = {};

  // Checkbox Selection state
  final Set<String> _selectedMealIds = {};
  final Map<String, Meal> _selectedMeals = {};
  bool _isLoggingBatch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    _loadRecentSearches();
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('recent_food_searches') ?? [];
      final List<Meal> meals = [];

      for (final raw in rawList) {
        final parts = raw.split(':::');
        if (parts.length >= 6) {
          meals.add(
            Meal(
              id: parts[0],
              name: parts[1],
              caloriesPer100g: int.tryParse(parts[2]) ?? 0,
              carbs: double.tryParse(parts[3]) ?? 0.0,
              protein: double.tryParse(parts[4]) ?? 0.0,
              fat: double.tryParse(parts[5]) ?? 0.0,
              servingSizes: [],
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _recentMeals = meals;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentMeal(Meal meal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('recent_food_searches') ?? [];
      final itemJson =
          '${meal.id}:::${meal.name}:::${meal.caloriesPer100g}:::${meal.carbs}:::${meal.protein}:::${meal.fat}';
      rawList.removeWhere((item) => item.contains(':::${meal.name}:::'));
      rawList.insert(0, itemJson);
      if (rawList.length > 25) rawList.removeRange(25, rawList.length);
      await prefs.setStringList('recent_food_searches', rawList);
      _loadRecentSearches();
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_food_searches');
      if (mounted) {
        setState(() {
          _recentMeals.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Recent searches cleared".tr()),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('favorite_food_ids') ?? [];
      if (mounted) {
        setState(() {
          _favoriteMealKeys = favList.toSet();
        });
      }
    } catch (_) {}
  }

  void _toggleMealSelection(Meal meal) {
    final key = meal.id.isNotEmpty ? meal.id : meal.name;
    setState(() {
      if (_selectedMealIds.contains(key)) {
        _selectedMealIds.remove(key);
        _selectedMeals.remove(key);
      } else {
        _selectedMealIds.add(key);
        _selectedMeals[key] = meal;
      }
    });
  }

  Future<void> _logSelectedMeals() async {
    if (_selectedMeals.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: You must be logged in.".tr())),
      );
      return;
    }

    setState(() => _isLoggingBatch = true);

    try {
      final dateKey =
          "${widget.logDate.year.toString().padLeft(4, '0')}-${widget.logDate.month.toString().padLeft(2, '0')}-${widget.logDate.day.toString().padLeft(2, '0')}";
      final category = widget.mealCategory.toLowerCase();
      final batch = FirebaseFirestore.instance.batch();
      final categoryRef = FirebaseFirestore.instance
          .collection('mealslog')
          .doc(user.uid)
          .collection('days')
          .doc(dateKey)
          .collection(category);

      for (final meal in _selectedMeals.values) {
        final smartOptions = ServingSizeHelper.getSmartServingSizes(
          foodName: meal.name,
          dbServingSizes: meal.servingSizes,
        );
        final defaultOption = smartOptions.isNotEmpty
            ? smartOptions.first
            : ServingOption(label: "100g", grams: 100);
        final ratio = defaultOption.grams / 100.0;
        final cals = (meal.caloriesPer100g * ratio).round();

        final docRef = categoryRef.doc();
        batch.set(docRef, {
          'name': meal.name,
          'caloriesPer100g': meal.caloriesPer100g,
          'carbsPer100g': meal.carbs,
          'proteinPer100g': meal.protein,
          'saturatedFatPer100g': meal.fat,
          'calories': cals,
          'estCalories': cals,
          'carbs': meal.carbs * ratio,
          'protein': meal.protein * ratio,
          'fat': meal.fat * ratio,
          'servingSizes': meal.servingSizes,
          'loggedServing': {
            'amount': defaultOption.grams,
            'unit': defaultOption.unit ?? 'g',
            'calculatedGrams': defaultOption.grams,
          },
          'date': dateKey,
          'category': category,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Also add to recent searches
        await _saveRecentMeal(meal);
      }

      await batch.commit();

      if (mounted) {
        final count = _selectedMeals.length;
        setState(() {
          _selectedMealIds.clear();
          _selectedMeals.clear();
          _isLoggingBatch = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${"Successfully logged".tr()} $count ${"foods to".tr()} ${widget.mealCategory.tr()}!"),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingBatch = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"Error logging items".tr()}: $e")),
        );
      }
    }
  }

  bool _matchesCategoryFilter(Meal meal) {
    if (_selectedCategoryFilter == "All") return true;
    final lower = meal.name.toLowerCase();

    if (_selectedCategoryFilter == "High Protein") {
      return meal.protein >= 10.0;
    }
    if (_selectedCategoryFilter == "Low Carb") {
      return meal.carbs <= 12.0;
    }
    if (_selectedCategoryFilter == "Beverages") {
      return lower.contains('tea') ||
          lower.contains('chai') ||
          lower.contains('coffee') ||
          lower.contains('milk') ||
          lower.contains('juice') ||
          lower.contains('lassi') ||
          lower.contains('shake') ||
          lower.contains('water') ||
          lower.contains('drink') ||
          lower.contains('soup');
    }
    if (_selectedCategoryFilter == "Traditional") {
      return lower.contains('roti') ||
          lower.contains('chapati') ||
          lower.contains('biryani') ||
          lower.contains('pulao') ||
          lower.contains('karahi') ||
          lower.contains('daal') ||
          lower.contains('dal') ||
          lower.contains('nihari') ||
          lower.contains('haleem') ||
          lower.contains('paratha') ||
          lower.contains('kebab') ||
          lower.contains('kabab') ||
          lower.contains('tikka') ||
          lower.contains('salan') ||
          lower.contains('samosa');
    }
    if (_selectedCategoryFilter == "Snacks") {
      return lower.contains('samosa') ||
          lower.contains('pakora') ||
          lower.contains('roll') ||
          lower.contains('biscuit') ||
          lower.contains('cookie') ||
          lower.contains('burger') ||
          lower.contains('sandwich') ||
          lower.contains('nugget') ||
          lower.contains('fries') ||
          lower.contains('patty');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildCustomSearchBar(),
            _buildCategoryFilterChips(),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[700],
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: _tabs.map((tabName) => Tab(text: tabName.tr())).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchTab(),
                  _buildStaplesTab(),
                  _buildFavoritesTab(),
                  _buildFrequentsTab(),
                  _buildRecentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedMealIds.isNotEmpty ? _buildSelectionBottomBar() : null,
    );
  }

  Widget _buildCategoryFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: _categoryFilters.map((cat) {
          final isSelected = _selectedCategoryFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(
                cat.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.blue[700],
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryFilter = selected ? cat : "All";
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search food name, brand, or dish".tr(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),

            // --- CUSTOM AI SCANNER BUTTON ---
            IconButton(
              onPressed: () {
                if (widget.cameras.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("No camera found on device".tr())),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      cameras: widget.cameras,
                      yolo: widget.yolo,
                    ),
                    fullscreenDialog: true,
                  ),
                );
              },
              icon: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF9B72CB),
                      Color(0xFFD96570),
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Image.asset(
                  'assets/images/ai-scanner.png',
                  width: 35,
                  height: 45,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'clear_recent') {
                  _clearRecentSearches();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'clear_recent',
                    child: Text('Clear Recent Searches'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'custom',
                    child: Text('Create & Log Custom Food'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'quick',
                    child: Text('Log Quick Entry'.tr()),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. SEARCH TAB ---
  Widget _buildSearchTab() {
    // A. If query is empty, show Dynamic Recent Searches!
    if (_searchQuery.isEmpty) {
      if (_recentMeals.isNotEmpty) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Searches".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text("Clear".tr(), style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ..._recentMeals.map((meal) {
              return _buildClickableFoodTile(meal);
            }),
          ],
        );
      }

      // If no recent searches yet, show popular suggestions from Firestore
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('meals').limit(15).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          final meals = docs.map((doc) => Meal.fromSnapshot(doc)).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                "Popular & Recommended Foods".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...meals.map((m) => _buildClickableFoodTile(m)),
            ],
          );
        },
      );
    }

    // B. Live Stream Search from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('meals').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        final filteredMeals = allDocs
            .map((doc) => Meal.fromSnapshot(doc))
            .where((meal) {
              final matchesQuery = meal.name.toLowerCase().contains(_searchQuery);
              final matchesCategory = _matchesCategoryFilter(meal);
              return matchesQuery && matchesCategory;
            })
            .toList();

        // Sort results: foods that start with the query come first
        filteredMeals.sort((a, b) {
          final aStarts = a.name.toLowerCase().startsWith(_searchQuery);
          final bStarts = b.name.toLowerCase().startsWith(_searchQuery);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          return a.name.compareTo(b.name);
        });

        if (filteredMeals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 50, color: Colors.grey),
                const SizedBox(height: 10),
                Text("${"No results for".tr()} '$_searchQuery'"),
                const SizedBox(height: 4),
                Text(
                  "Try a different keyword or category filter".tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredMeals.length,
          itemBuilder: (context, index) {
            return _buildClickableFoodTile(filteredMeals[index]);
          },
        );
      },
    );
  }

  // --- 2. STAPLES TAB ---
  Widget _buildStaplesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('meals').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final stapleKeywords = [
          'roti', 'chapati', 'rice', 'daal', 'dal', 'egg', 'chicken',
          'chai', 'milk', 'banana', 'apple', 'yogurt', 'biryani', 'salad'
        ];

        final stapleMeals = allDocs
            .map((doc) => Meal.fromSnapshot(doc))
            .where((m) {
              final lower = m.name.toLowerCase();
              return stapleKeywords.any((kw) => lower.contains(kw)) &&
                  _matchesCategoryFilter(m);
            })
            .toList();

        if (stapleMeals.isEmpty) {
          return Center(child: Text("No staples found in database".tr()));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: stapleMeals.length,
          itemBuilder: (context, index) {
            return _buildClickableFoodTile(stapleMeals[index]);
          },
        );
      },
    );
  }

  // --- 3. FAVORITES TAB ---
  Widget _buildFavoritesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('meals').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final favMeals = allDocs
            .map((doc) => Meal.fromSnapshot(doc))
            .where((m) =>
                _favoriteMealKeys.contains(m.id) ||
                _favoriteMealKeys.contains(m.name.toLowerCase()))
            .toList();

        if (favMeals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border, size: 54, color: Colors.amber),
                const SizedBox(height: 12),
                Text(
                  "No Favorites Saved Yet".tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    "Tap the star icon on any food's serving page to add it to your Favorites for 1-tap logging!".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: favMeals.length,
          itemBuilder: (context, index) {
            return _buildClickableFoodTile(favMeals[index]);
          },
        );
      },
    );
  }

  // --- 4. FREQUENTS TAB ---
  Widget _buildFrequentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('meals').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final meals = allDocs
            .map((doc) => Meal.fromSnapshot(doc))
            .where(_matchesCategoryFilter)
            .take(15)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            return _buildClickableFoodTile(meals[index]);
          },
        );
      },
    );
  }

  // --- 5. RECENT TAB ---
  Widget _buildRecentTab() {
    if (_recentMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 54, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "No Recent Food Searches".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "Foods you search or log will appear here for fast access.".tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${"Recent History".tr()} (${_recentMeals.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: Text("Clear All".tr(), style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._recentMeals.map((m) => _buildClickableFoodTile(m)),
      ],
    );
  }

  Widget _buildClickableFoodTile(Meal meal) {
    final key = meal.id.isNotEmpty ? meal.id : meal.name;
    final isSelected = _selectedMealIds.contains(key);
    final servingLabel = meal.defaultServingLabel;
    final displayCals = meal.defaultServingCalories;

    return InkWell(
      onTap: () async {
        await _saveRecentMeal(meal);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServingSizePage(
              meal: meal,
              mealCategory: widget.mealCategory,
              logDate: widget.logDate,
            ),
          ),
        );
        _loadRecentSearches();
        _loadFavorites();
      },
      child: _buildFoodTileUI(
        meal: meal,
        name: meal.name,
        info: "$displayCals ${"cals".tr()} / ${servingLabel.tr()}",
        icon: _getFoodIcon(meal.name),
        isSelected: isSelected,
        onCheckboxChanged: () => _toggleMealSelection(meal),
      ),
    );
  }

  Widget _buildFoodTileUI({
    required Meal meal,
    required String name,
    required String info,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onCheckboxChanged,
  }) {
    List<String> parts = info.split('/');
    String calsPart = parts.isNotEmpty ? parts[0].trim() : "";
    String sizePart = parts.length > 1 ? " / ${parts[1].trim()}" : "";

    return Container(
      color: isSelected ? Colors.blue.withValues(alpha: 0.08) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              activeColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: Colors.grey),
              onChanged: (_) => onCheckboxChanged(),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.blue[700] : Colors.orange[800],
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14),
            children: [
              TextSpan(
                text: calsPart,
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: sizePart,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildSelectionBottomBar() {
    final count = _selectedMealIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count ${"foods selected".tr()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${"Logging to".tr()} ${widget.mealCategory.tr()}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMealIds.clear();
                _selectedMeals.clear();
              });
            },
            child: Text("Clear".tr(), style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isLoggingBatch ? null : _logSelectedMeals,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isLoggingBatch
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(
              _isLoggingBatch ? "Logging...".tr() : "${"Log Selected".tr()} ($count)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFoodIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tea') || lower.contains('chai') || lower.contains('coffee')) {
      return Icons.local_cafe;
    }
    if (lower.contains('milk') || lower.contains('juice') || lower.contains('water') || lower.contains('lassi')) {
      return Icons.local_drink;
    }
    if (lower.contains('burger') || lower.contains('sandwich')) {
      return Icons.lunch_dining;
    }
    if (lower.contains('roti') || lower.contains('naan') || lower.contains('bread')) {
      return Icons.bakery_dining;
    }
    if (lower.contains('egg')) {
      return Icons.egg;
    }
    if (lower.contains('apple') || lower.contains('banana') || lower.contains('fruit')) {
      return Icons.apple;
    }
    if (lower.contains('biscuit') ||
        lower.contains('cookie') ||
        lower.contains('oreo') ||
        lower.contains('rite') ||
        lower.contains('sooper') ||
        lower.contains('candi') ||
        lower.contains('nankhatai')) {
      return Icons.cookie;
    }
    if (lower.contains('lays') ||
        lower.contains('chips') ||
        lower.contains('kurkure') ||
        lower.contains('slanty') ||
        lower.contains('kurleez') ||
        lower.contains('doritos') ||
        lower.contains('pringles') ||
        lower.contains('cheetos')) {
      return Icons.shopping_bag;
    }
    if (lower.contains('candy') ||
        lower.contains('chilli milli') ||
        lower.contains('gum') ||
        lower.contains('fanty')) {
      return Icons.star;
    }
    if (lower.contains('chocolate') ||
        lower.contains('dairy milk') ||
        lower.contains('kitkat') ||
        lower.contains('perk') ||
        lower.contains('snickers')) {
      return Icons.icecream;
    }
    if (lower.contains('ghee') || lower.contains('oil') || lower.contains('butter')) {
      return Icons.whatshot;
    }
    return Icons.restaurant;
  }
}
