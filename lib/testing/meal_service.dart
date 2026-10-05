import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class MealService {
  List<List<dynamic>> _generalData = [];
  List<List<dynamic>> _pakistanData = [];
  List<List<dynamic>> _indianData = [];
  bool _isLoaded = false;

  // Meat keywords for the "Nuclear Safety Filter"
  final List<String> _meatKeywords = [
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
  ];

  // ---------------------------------------------------------------------------
  // 1. LOAD DATA
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    if (_isLoaded) {
      return;
    }

    try {
      final rawGeneral = await rootBundle.loadString(
        'assets/fyp_meal_plan.csv',
      );
      _generalData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(rawGeneral.replaceAll('\r\n', '\n'));

      final rawPak = await rootBundle.loadString(
        'assets/fyp_pakistan_meal_plan.csv',
      );
      _pakistanData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(rawPak.replaceAll('\r\n', '\n'));

      final rawInd = await rootBundle.loadString(
        'assets/fyp_indian_meal_plan.csv',
      );
      _indianData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(rawInd.replaceAll('\r\n', '\n'));

      _isLoaded = true;
      developer.log("✅ Offline Meal CSVs Loaded (General: ${_generalData.length}, Pakistani: ${_pakistanData.length}, Indian: ${_indianData.length})", name: 'MealService');
    } catch (e) {
      developer.log("❌ Error loading CSVs: $e", name: 'MealService');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. MAIN RECOMMENDATION FUNCTION
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> recommendMeal({
    required double targetCalories,
    required String cuisine,
    required String dietType,
    required String restriction,
  }) async {
    await loadData();

    final String cleanCuisine = cuisine.toLowerCase().trim();
    final String cleanDiet = dietType.toLowerCase().trim();
    final String cleanRestriction = restriction.toLowerCase().trim();

    final bool isPakistani = cleanCuisine == 'pakistan' ||
        cleanCuisine == 'pakistani' ||
        cleanCuisine.contains('pakistan') ||
        (cleanDiet.contains('pakistan') && !cleanCuisine.contains('indian'));

    final bool isIndian = !isPakistani && (cleanCuisine == 'indian' ||
        cleanCuisine.contains('indian') ||
        cleanDiet.contains('indian'));

    developer.log("recommendMeal: target=$targetCalories, cuisine=$cleanCuisine, isPakistani=$isPakistani, isIndian=$isIndian", name: 'MealService');

    if (isPakistani) {
      return _getKnnPlan(
        _pakistanData.isNotEmpty ? _pakistanData : _generalData,
        targetCalories,
        cleanDiet,
        cleanRestriction,
        sourceLabel: "Pakistani (FCTP Offline KNN)",
      );
    } else if (isIndian) {
      return _getKnnPlan(
        _indianData.isNotEmpty ? _indianData : _generalData,
        targetCalories,
        cleanDiet,
        cleanRestriction,
        sourceLabel: "Indian (Offline KNN)",
      );
    } else {
      return _getKnnPlan(
        _generalData,
        targetCalories,
        cleanDiet,
        cleanRestriction,
        sourceLabel: "General (Offline KNN)",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 4. GENERAL LOGIC (KNN + Safe Universe)
  // ---------------------------------------------------------------------------
  Map<String, String> _getKnnPlan(
    List<List<dynamic>> data,
    double target,
    String diet,
    String restriction, {
    String sourceLabel = "General (Offline KNN)",
  }) {
    List<dynamic> header = data[0]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    int idxCal = -1,
        idxDiet = -1,
        idxDisease = -1,
        idxB = -1,
        idxL = -1,
        idxD = -1,
        idxS = -1;
    for (int i = 0; i < header.length; i++) {
      String h = header[i].toString();
      if (h.contains('calories') && !h.contains('target')) {
        idxCal = i;
      } else if (h.contains('diet')) {
        idxDiet = i;
      } else if (h.contains('disease')) {
        idxDisease = i;
      } else if (h == 'breakfast') {
        idxB = i;
      } else if (h == 'lunch') {
        idxL = i;
      } else if (h == 'dinner') {
        idxD = i;
      } else if (h.contains('snack')) {
        idxS = i;
      }
    }

    List<List<dynamic>> fullPool = data.sublist(1); // All rows without header
    List<List<dynamic>> safeUniverse = [];

    bool hasRestriction =
        restriction.contains('vegetarian') || restriction.contains('vegan');

    // --- STEP 1: CREATE SAFE UNIVERSE ---
    for (var row in fullPool) {
      if (hasRestriction) {
        String rowString = row.join(' ').toLowerCase();
        if (!_meatKeywords.any((k) => rowString.contains(k))) {
          safeUniverse.add(row);
        }
      } else {
        safeUniverse.add(row);
      }
    }

    if (safeUniverse.isEmpty) {
      developer.log(
        "⚠️ Safe Universe Empty! Reverting to full pool.",
        name: 'MealService',
      );
      safeUniverse = fullPool;
    }

    // --- STEP 2: PARSE CONDITIONS AND DIET PREFERENCES ---
    List<String> conditions = restriction
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty && e != 'none')
        .toList();

    List<String> activeDiets = diet
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) =>
            e.isNotEmpty &&
            e != 'none' &&
            e != 'standard' &&
            e != 'balanced' &&
            !e.contains('pakistan') &&
            !e.contains('indian'))
        .toList();

    List<List<dynamic>> filteredPool = [];

    // Helper matcher
    bool matchesRow(List<dynamic> row, {bool matchAllConditions = true}) {
      String dVal = (idxDiet != -1) ? row[idxDiet].toString().toLowerCase() : "";
      String disVal = (idxDisease != -1) ? row[idxDisease].toString().toLowerCase() : "";

      if (conditions.isNotEmpty) {
        bool condMatch = matchAllConditions
            ? conditions.every((c) => disVal.contains(c) || dVal.contains(c))
            : conditions.any((c) => disVal.contains(c) || dVal.contains(c));
        if (!condMatch) return false;
      }

      if (activeDiets.isNotEmpty) {
        bool dietMatch = activeDiets.any((d) => dVal.contains(d));
        if (!dietMatch) return false;
      }

      return true;
    }

    // Priority 1: Match Diet AND all conditions
    for (var row in safeUniverse) {
      if (matchesRow(row, matchAllConditions: true)) {
        filteredPool.add(row);
      }
    }

    // Priority 2: If multiple conditions and empty, match ANY condition + Diet
    if (filteredPool.isEmpty && conditions.length > 1) {
      for (var row in safeUniverse) {
        if (matchesRow(row, matchAllConditions: false)) {
          filteredPool.add(row);
        }
      }
    }

    // Priority 3: Fallback to Conditions only (ignore diet preference if strict)
    if (filteredPool.isEmpty && conditions.isNotEmpty) {
      for (var row in safeUniverse) {
        String dVal = (idxDiet != -1) ? row[idxDiet].toString().toLowerCase() : "";
        String disVal = (idxDisease != -1) ? row[idxDisease].toString().toLowerCase() : "";
        bool condMatch = conditions.any((c) => disVal.contains(c) || dVal.contains(c));
        if (condMatch) {
          filteredPool.add(row);
        }
      }
    }

    // Priority 4: Fallback to Diet only
    if (filteredPool.isEmpty && activeDiets.isNotEmpty) {
      for (var row in safeUniverse) {
        String dVal = (idxDiet != -1) ? row[idxDiet].toString().toLowerCase() : "";
        if (activeDiets.any((d) => dVal.contains(d))) {
          filteredPool.add(row);
        }
      }
    }

    // ULTIMATE FALLBACK: Just use the Safe Universe
    if (filteredPool.isEmpty) {
      filteredPool = safeUniverse;
    }

    // --- KNN SEARCH (Classic Nearest Calorie Neighbor) ---
    double minDiff = 999999.0;
    List<dynamic> bestRow = [];

    for (var row in filteredPool) {
      if (idxCal >= row.length) continue;
      double rowCals = double.tryParse(row[idxCal].toString()) ?? 0.0;
      if (rowCals <= 0) continue;
      double diff = (target - rowCals).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestRow = row;
      }
    }

    if (bestRow.isEmpty && safeUniverse.isNotEmpty) {
      for (var row in safeUniverse) {
        if (idxCal >= row.length) continue;
        double rowCals = double.tryParse(row[idxCal].toString()) ?? 0.0;
        if (rowCals <= 0) continue;
        double diff = (target - rowCals).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestRow = row;
        }
      }
    }

    if (bestRow.isEmpty && data.length > 1) {
      bestRow = data[1];
    }

    return {
      "Calories": idxCal != -1 && idxCal < bestRow.length ? bestRow[idxCal].toString() : "0",
      "Breakfast": idxB != -1 && idxB < bestRow.length ? bestRow[idxB].toString() : "Healthy Breakfast",
      "Lunch": idxL != -1 && idxL < bestRow.length ? bestRow[idxL].toString() : "Healthy Lunch",
      "Dinner": idxD != -1 && idxD < bestRow.length ? bestRow[idxD].toString() : "Healthy Dinner",
      "Snack": idxS != -1 && idxS < bestRow.length ? bestRow[idxS].toString() : "Healthy Snack",
      "Source": sourceLabel,
    };
  }
}
