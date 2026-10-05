import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:nutriapp/services/fat_calculator_service.dart';

class MealItem {
  final String title;
  final List<String> benefits;
  final Map<String, String> nutrition;
  final String timeSuggestion;
  final List<String> highlights;
  final String emoji;
  final String cuisine;
  final Set<String> dietaryTags;

  MealItem({
    required this.title,
    required this.benefits,
    required this.nutrition,
    required this.timeSuggestion,
    required this.highlights,
    required this.emoji,
    this.cuisine = "General",
    Set<String>? dietaryTags,
  }) : dietaryTags = dietaryTags ?? <String>{};
}

class AIMealPlanGenerator {
  static final Random _random = Random();

  // Meat keywords for Vegetarian / Vegan filtering
  static final List<String> _meatKeywords = [
    'chicken',
    'beef',
    'turkey',
    'pork',
    'steak',
    'salmon',
    'tuna',
    'fish',
    'meat',
    'ham',
    'bacon',
    'mutton',
    'lamb',
    'prawn',
    'egg',
    'anda',
    'gosht',
    'keema',
    'kebab',
    'kabab',
    'shami',
    'machli',
    'haleem',
    'nihari',
  ];

  // Storage separated by cuisine to guarantee authentic, distinct meal pools
  static final List<MealItem> _pakistaniBreakfasts = [];
  static final List<MealItem> _pakistaniLunches = [];
  static final List<MealItem> _pakistaniDinners = [];
  static final List<MealItem> _pakistaniSnacks = [];

  static final List<MealItem> _indianBreakfasts = [];
  static final List<MealItem> _indianLunches = [];
  static final List<MealItem> _indianDinners = [];
  static final List<MealItem> _indianSnacks = [];

  static final List<MealItem> _generalBreakfasts = [];
  static final List<MealItem> _generalLunches = [];
  static final List<MealItem> _generalDinners = [];
  static final List<MealItem> _generalSnacks = [];

  static bool isLoaded = false;

  // ---------------------------------------------------------------------------
  // 1. INITIALIZE & LOAD DATA
  // ---------------------------------------------------------------------------
  static Future<void> loadData() async {
    if (isLoaded) return;

    try {
      // Clear previous pools if re-running
      _pakistaniBreakfasts.clear();
      _pakistaniLunches.clear();
      _pakistaniDinners.clear();
      _pakistaniSnacks.clear();

      _indianBreakfasts.clear();
      _indianLunches.clear();
      _indianDinners.clear();
      _indianSnacks.clear();

      _generalBreakfasts.clear();
      _generalLunches.clear();
      _generalDinners.clear();
      _generalSnacks.clear();

      // --- 1. Load General Data ---
      final rawGeneral = await rootBundle.loadString(
        'assets/fyp_meal_plan.csv',
      );
      List<List<dynamic>> generalData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(rawGeneral.replaceAll('\r\n', '\n'));
      _parseGeneralData(generalData);

      // --- 2. Load Pakistani Data ---
      final rawPakistani = await rootBundle.loadString(
        'assets/fyp_pakistan_meal_plan.csv',
      );
      List<List<dynamic>> pakistaniData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(rawPakistani.replaceAll('\r\n', '\n'));
      _parseRegionalData(
        pakistaniData,
        cuisineTag: "Pakistani",
        bList: _pakistaniBreakfasts,
        lList: _pakistaniLunches,
        dList: _pakistaniDinners,
        sList: _pakistaniSnacks,
      );

      // --- 3. Load Indian Data ---
      final rawIndian = await rootBundle.loadString(
        'assets/fyp_indian_meal_plan.csv',
      );
      List<List<dynamic>> indianData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(rawIndian.replaceAll('\r\n', '\n'));
      _parseRegionalData(
        indianData,
        cuisineTag: "Indian",
        bList: _indianBreakfasts,
        lList: _indianLunches,
        dList: _indianDinners,
        sList: _indianSnacks,
      );

      isLoaded = true;
      developer.log(
        "✅ AIMealPlanGenerator: Loaded Pakistani (${_pakistaniBreakfasts.length}B/${_pakistaniLunches.length}L/${_pakistaniDinners.length}D/${_pakistaniSnacks.length}S), Indian (${_indianBreakfasts.length}B/${_indianLunches.length}L/${_indianDinners.length}D/${_indianSnacks.length}S), General (${_generalBreakfasts.length}B)",
        name: 'AIMealPlanGenerator',
      );
    } catch (e) {
      developer.log(
        "❌ Error loading meal data: $e",
        name: 'AIMealPlanGenerator',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2. PARSING LOGIC
  // ---------------------------------------------------------------------------
  static void _parseGeneralData(List<List<dynamic>> data) {
    if (data.isEmpty) return;
    for (int i = 1; i < data.length; i++) {
      var row = data[i];
      try {
        String diet = row[0].toString().trim();
        List<String> tags = [diet.toLowerCase()];
        if (row.length > 14) {
          tags.addAll(row[14].toString().split(',').map((e) => e.trim().toLowerCase()));
        }
        if (row.length > 13) {
          tags.addAll(row[13].toString().split(',').map((e) => e.trim().toLowerCase()));
        }
        if (row.length > 9) {
          _addMealToTarget(
            list: _generalBreakfasts,
            name: row[9],
            type: "Breakfast",
            cuisineTag: "General",
            sourceTag: diet,
            tags: tags,
          );
        }
        if (row.length > 10) {
          _addMealToTarget(
            list: _generalLunches,
            name: row[10],
            type: "Lunch",
            cuisineTag: "General",
            sourceTag: diet,
            tags: tags,
          );
        }
        if (row.length > 11) {
          _addMealToTarget(
            list: _generalDinners,
            name: row[11],
            type: "Dinner",
            cuisineTag: "General",
            sourceTag: diet,
            tags: tags,
          );
        }
        if (row.length > 12) {
          _addMealToTarget(
            list: _generalSnacks,
            name: row[12],
            type: "Snack",
            cuisineTag: "General",
            sourceTag: diet,
            tags: tags,
          );
        }
      } catch (_) {}
    }
  }

  static void _parseRegionalData(
    List<List<dynamic>> data, {
    required String cuisineTag,
    required List<MealItem> bList,
    required List<MealItem> lList,
    required List<MealItem> dList,
    required List<MealItem> sList,
  }) {
    if (data.isEmpty) return;
    List<dynamic> header = data[0]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();
    int idxB = header.indexOf('breakfast');
    int idxL = header.indexOf('lunch');
    int idxD = header.indexOf('dinner');
    int idxS = header.indexOf('snack');
    if (idxS == -1) idxS = header.indexOf('snacks');

    int idxDiet = -1;
    int idxDisease = -1;
    for (int i = 0; i < header.length; i++) {
      if (header[i].toString().contains('diet')) idxDiet = i;
      if (header[i].toString().contains('disease')) idxDisease = i;
    }

    final bool isPak = cuisineTag.toLowerCase().contains('pakistan');
    final bool isInd = cuisineTag.toLowerCase().contains('indian');

    for (int i = 1; i < data.length; i++) {
      var row = data[i];
      List<String> rowTags = [cuisineTag.toLowerCase()];
      if (idxDiet != -1 && idxDiet < row.length) {
        rowTags.addAll(
          row[idxDiet]
              .toString()
              .split(',')
              .map((e) => e.trim().toLowerCase()),
        );
      }
      if (idxDisease != -1 && idxDisease < row.length) {
        rowTags.addAll(
          row[idxDisease]
              .toString()
              .split(',')
              .map((e) => e.trim().toLowerCase()),
        );
      }

      // Pakistani food should NOT include Indian tag; Indian food should NOT include Pakistani tag
      if (isPak) {
        rowTags = rowTags.where((t) => t != 'indian').toList();
      } else if (isInd) {
        rowTags = rowTags.where((t) => !t.contains('pakistan')).toList();
      }

      if (idxB != -1 && idxB < row.length) {
        _addMealToTarget(
          list: bList,
          name: row[idxB],
          type: "Breakfast",
          cuisineTag: cuisineTag,
          sourceTag: cuisineTag,
          tags: rowTags,
        );
      }
      if (idxL != -1 && idxL < row.length) {
        _addMealToTarget(
          list: lList,
          name: row[idxL],
          type: "Lunch",
          cuisineTag: cuisineTag,
          sourceTag: cuisineTag,
          tags: rowTags,
        );
      }
      if (idxD != -1 && idxD < row.length) {
        _addMealToTarget(
          list: dList,
          name: row[idxD],
          type: "Dinner",
          cuisineTag: cuisineTag,
          sourceTag: cuisineTag,
          tags: rowTags,
        );
      }
      if (idxS != -1 && idxS < row.length) {
        _addMealToTarget(
          list: sList,
          name: row[idxS],
          type: "Snack",
          cuisineTag: cuisineTag,
          sourceTag: cuisineTag,
          tags: rowTags,
        );
      }
    }
  }

  static void _addMealToTarget({
    required List<MealItem> list,
    required dynamic name,
    required String type,
    required String cuisineTag,
    required String sourceTag,
    List<String> tags = const [],
  }) {
    if (name == null || name.toString().trim().isEmpty) return;
    final String cleanTitle = name.toString().trim();

    final bool isPak = cuisineTag.toLowerCase().contains('pakistan');
    final bool isInd = cuisineTag.toLowerCase().contains('indian');

    // Deduplicate within the same cuisine pool and merge tags
    final existingIndex = list.indexWhere(
      (m) => m.title.toLowerCase() == cleanTitle.toLowerCase(),
    );
    if (existingIndex != -1) {
      for (var t in tags) {
        if (t.isNotEmpty && t != 'none') {
          if (isPak && t == 'indian') continue;
          if (isInd && t.contains('pakistan')) continue;
          list[existingIndex].dietaryTags.add(t);
        }
      }
      return;
    }

    int baseCals = type == "Snack" ? 180 : (type == "Lunch" ? 500 : (type == "Dinner" ? 450 : 350));
    final targets = FatCalculatorService.calculateMacroTargets(
      weightKg: 70.0,
      calorieBudget: baseCals,
      goal: cuisineTag,
      dietPreference: cuisineTag,
    );

    Set<String> initialTags = {
      cuisineTag.toLowerCase(),
      sourceTag.toLowerCase(),
      ...tags.where((t) => t.isNotEmpty && t != 'none'),
    };

    if (isPak) {
      initialTags.remove('indian');
    } else if (isInd) {
      initialTags.remove('pakistani');
      initialTags.remove('pakistan');
    }

    MealItem item = MealItem(
      title: cleanTitle,
      emoji: _getEmoji(type),
      benefits: ["Authentic $cuisineTag Choice", "$sourceTag Certified"],
      nutrition: {
        "Calories": "$baseCals",
        "Protein": "${targets.protein}g",
        "Fat": "${targets.fat}g",
        "Carbs": "${targets.carbs}g",
        "Source": sourceTag,
        "Type": cuisineTag,
      },
      timeSuggestion: _getTime(type),
      highlights: [cuisineTag, type],
      cuisine: cuisineTag,
      dietaryTags: initialTags,
    );

    list.add(item);
  }

  static String _getEmoji(String type) {
    if (type == "Breakfast") return "🍳";
    if (type == "Lunch") return "🥗";
    if (type == "Dinner") return "🍲";
    return "🍎";
  }

  static String _getTime(String type) {
    if (type == "Breakfast") return "8:00 AM";
    if (type == "Lunch") return "1:00 PM";
    if (type == "Dinner") return "7:00 PM";
    return "4:00 PM";
  }

  // ---------------------------------------------------------------------------
  // 3. RETRIEVAL & FILTERING ENGINE
  // ---------------------------------------------------------------------------
  static List<MealItem> _getPoolForCuisine(String type, String cleanCuisine) {
    final bool isPak = cleanCuisine.contains('pakistan');
    final bool isInd = cleanCuisine.contains('indian');

    if (isPak) {
      if (type == "Breakfast" && _pakistaniBreakfasts.isNotEmpty) return _pakistaniBreakfasts;
      if (type == "Lunch" && _pakistaniLunches.isNotEmpty) return _pakistaniLunches;
      if (type == "Dinner" && _pakistaniDinners.isNotEmpty) return _pakistaniDinners;
      if (type == "Snack" && _pakistaniSnacks.isNotEmpty) return _pakistaniSnacks;
    } else if (isInd) {
      if (type == "Breakfast" && _indianBreakfasts.isNotEmpty) return _indianBreakfasts;
      if (type == "Lunch" && _indianLunches.isNotEmpty) return _indianLunches;
      if (type == "Dinner" && _indianDinners.isNotEmpty) return _indianDinners;
      if (type == "Snack" && _indianSnacks.isNotEmpty) return _indianSnacks;
    }

    // General fallback
    if (type == "Breakfast") {
      return _generalBreakfasts.isNotEmpty
          ? _generalBreakfasts
          : (_pakistaniBreakfasts.isNotEmpty ? _pakistaniBreakfasts : _indianBreakfasts);
    }
    if (type == "Lunch") {
      return _generalLunches.isNotEmpty
          ? _generalLunches
          : (_pakistaniLunches.isNotEmpty ? _pakistaniLunches : _indianLunches);
    }
    if (type == "Dinner") {
      return _generalDinners.isNotEmpty
          ? _generalDinners
          : (_pakistaniDinners.isNotEmpty ? _pakistaniDinners : _indianDinners);
    }
    return _generalSnacks.isNotEmpty
        ? _generalSnacks
        : (_pakistaniSnacks.isNotEmpty ? _pakistaniSnacks : _indianSnacks);
  }

  static MealItem _fallback(String type) {
    return MealItem(
      title: "Healthy $type",
      emoji: _getEmoji(type),
      benefits: ["Balanced Nutrition"],
      nutrition: {
        "Calories": "400",
        "Protein": "20g",
        "Fat": "12g",
        "Carbs": "45g",
      },
      timeSuggestion: _getTime(type),
      highlights: ["Healthy"],
    );
  }

  static MealItem _pickMeal({
    required String type,
    DateTime? date,
    String? cuisine,
    String? dietPreference,
    String? restrictions,
    String? healthConditions,
    MealItem? currentMeal,
    int? calorieBudget,
    bool forceNew = false,
  }) {
    final String cleanCuisine =
        (cuisine ?? dietPreference ?? '').toLowerCase().trim();
    List<MealItem> basePool = _getPoolForCuisine(type, cleanCuisine);
    if (basePool.isEmpty) return _fallback(type);

    List<MealItem> pool = List<MealItem>.from(basePool);

    // 1. Safety Filter: Vegetarian / Vegan
    final String combinedPref =
        "${dietPreference ?? ''} ${restrictions ?? ''}".toLowerCase();
    final bool isVegetarian =
        combinedPref.contains("vegetarian") || combinedPref.contains("vegan");
    if (isVegetarian) {
      final vegPool = pool.where((m) {
        final title = m.title.toLowerCase();
        return !_meatKeywords.any((k) => title.contains(k));
      }).toList();
      if (vegPool.isNotEmpty) {
        pool = vegPool;
      }
    }

    // 2. Dietary & Health Tag Filters (High Protein, Low Carb, Low Fat, Diabetes, etc.)
    List<String> targetTags = [];
    if (dietPreference != null && dietPreference.isNotEmpty) {
      targetTags.addAll(
        dietPreference.split(',').map((e) => e.trim().toLowerCase()),
      );
    }
    if (restrictions != null && restrictions.isNotEmpty) {
      targetTags.addAll(
        restrictions.split(',').map((e) => e.trim().toLowerCase()),
      );
    }
    if (healthConditions != null && healthConditions.isNotEmpty) {
      targetTags.addAll(
        healthConditions.split(',').map((e) => e.trim().toLowerCase()),
      );
    }
    targetTags = targetTags
        .where((t) =>
            t.isNotEmpty &&
            t != 'none' &&
            t != 'standard' &&
            t != 'balanced' &&
            !t.contains('pakistan') &&
            !t.contains('indian'))
        .toList();

    if (targetTags.isNotEmpty) {
      final taggedPool = pool.where((m) {
        final mTitle = m.title.toLowerCase();
        return targetTags.any(
          (t) => m.dietaryTags.contains(t) || mTitle.contains(t),
        );
      }).toList();

      if (taggedPool.isNotEmpty) {
        pool = taggedPool;
      }
    }

    // 3. Avoid picking the exact same meal when single-replacing or regenerating
    if (currentMeal != null && pool.length > 1) {
      final altPool = pool.where((m) => m.title.trim().toLowerCase() != currentMeal.title.trim().toLowerCase()).toList();
      if (altPool.isNotEmpty) {
        pool = altPool;
      }
    }

    // 4. Random Selection:
    // If forceNew is true or date is null, generate fresh random dish.
    // If date is passed without forceNew, use a diverse seed incorporating meal type to avoid collisions.
    MealItem picked;
    if (forceNew || date == null) {
      picked = pool[_random.nextInt(pool.length)];
    } else {
      int typeSalt = type == "Breakfast" ? 101 : (type == "Lunch" ? 307 : (type == "Dinner" ? 521 : 709));
      int seed = (date.year * 10000 + date.month * 100 + date.day) ^ typeSalt;
      Random seededRnd = Random(seed);
      picked = pool[seededRnd.nextInt(pool.length)];
    }

    // 5. Scale macros & calories if calorieBudget is passed
    if (calorieBudget != null && calorieBudget > 0) {
      final targets = FatCalculatorService.calculateMacroTargets(
        weightKg: 70.0,
        calorieBudget: calorieBudget,
        goal: cleanCuisine.contains('pakistan')
            ? "Pakistani"
            : (cleanCuisine.contains('indian') ? "Indian" : (dietPreference ?? "Healthy")),
        dietPreference: dietPreference ?? "Balanced",
      );
      return MealItem(
        title: picked.title,
        emoji: picked.emoji,
        benefits: picked.benefits,
        timeSuggestion: picked.timeSuggestion,
        highlights: picked.highlights,
        cuisine: picked.cuisine,
        dietaryTags: picked.dietaryTags,
        nutrition: {
          "Calories": "$calorieBudget",
          "Protein": "${targets.protein}g",
          "Fat": "${targets.fat}g",
          "Carbs": "${targets.carbs}g",
          "Source": picked.cuisine,
          "Type": picked.highlights.isNotEmpty
              ? picked.highlights.first
              : "Healthy",
        },
      );
    }

    return picked;
  }

  // ---------------------------------------------------------------------------
  // 4. PUBLIC GETTERS
  // ---------------------------------------------------------------------------
  static MealItem getBreakfast({
    DateTime? date,
    String? cuisine,
    String? dietPreference,
    String? restrictions,
    String? healthConditions,
    MealItem? currentMeal,
    int? calorieBudget,
    bool forceNew = false,
  }) {
    return _pickMeal(
      type: "Breakfast",
      date: date,
      cuisine: cuisine,
      dietPreference: dietPreference,
      restrictions: restrictions,
      healthConditions: healthConditions,
      currentMeal: currentMeal,
      calorieBudget: calorieBudget,
      forceNew: forceNew,
    );
  }

  static MealItem getLunch({
    DateTime? date,
    String? cuisine,
    String? dietPreference,
    String? restrictions,
    String? healthConditions,
    MealItem? currentMeal,
    int? calorieBudget,
    bool forceNew = false,
  }) {
    return _pickMeal(
      type: "Lunch",
      date: date,
      cuisine: cuisine,
      dietPreference: dietPreference,
      restrictions: restrictions,
      healthConditions: healthConditions,
      currentMeal: currentMeal,
      calorieBudget: calorieBudget,
      forceNew: forceNew,
    );
  }

  static MealItem getDinner({
    DateTime? date,
    String? cuisine,
    String? dietPreference,
    String? restrictions,
    String? healthConditions,
    MealItem? currentMeal,
    int? calorieBudget,
    bool forceNew = false,
  }) {
    return _pickMeal(
      type: "Dinner",
      date: date,
      cuisine: cuisine,
      dietPreference: dietPreference,
      restrictions: restrictions,
      healthConditions: healthConditions,
      currentMeal: currentMeal,
      calorieBudget: calorieBudget,
      forceNew: forceNew,
    );
  }

  static MealItem getSnack({
    DateTime? date,
    String? cuisine,
    String? dietPreference,
    String? restrictions,
    String? healthConditions,
    MealItem? currentMeal,
    int? calorieBudget,
    bool forceNew = false,
  }) {
    return _pickMeal(
      type: "Snack",
      date: date,
      cuisine: cuisine,
      dietPreference: dietPreference,
      restrictions: restrictions,
      healthConditions: healthConditions,
      currentMeal: currentMeal,
      calorieBudget: calorieBudget,
      forceNew: forceNew,
    );
  }
}

