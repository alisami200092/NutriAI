import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/services/fat_calculator_service.dart';
import 'package:rxdart/rxdart.dart';

class DayNutritionData {
  final DateTime date;
  final String dateKey;
  final double totalCals;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;
  final double totalSatFat;
  final double totalTrFat;
  final double totalFiber;
  final double totalSalt;
  final double totalCalcium;

  // Targets
  final double targetCals;
  final double targetCarbs;
  final double targetProtein;
  final double targetFat;
  final double targetSatFat;
  final double targetTrFat;
  final double targetFiber;
  final double targetSalt;
  final double targetCalcium;

  // Categorized items
  final Map<String, List<Map<String, dynamic>>> itemsByCategory;

  const DayNutritionData({
    required this.date,
    required this.dateKey,
    required this.totalCals,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalSatFat,
    required this.totalTrFat,
    required this.totalFiber,
    required this.totalSalt,
    required this.totalCalcium,
    required this.targetCals,
    required this.targetCarbs,
    required this.targetProtein,
    required this.targetFat,
    required this.targetSatFat,
    required this.targetTrFat,
    required this.targetFiber,
    required this.targetSalt,
    required this.targetCalcium,
    required this.itemsByCategory,
  });

  int get totalFoodsCount =>
      itemsByCategory.values.fold(0, (acc, list) => acc + list.length);

  factory DayNutritionData.empty(DateTime date) {
    final key =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return DayNutritionData(
      date: date,
      dateKey: key,
      totalCals: 0,
      totalCarbs: 0,
      totalProtein: 0,
      totalFat: 0,
      totalSatFat: 0,
      totalTrFat: 0,
      totalFiber: 0,
      totalSalt: 0,
      totalCalcium: 0,
      targetCals: 2000,
      targetCarbs: 180,
      targetProtein: 80,
      targetFat: 70,
      targetSatFat: 20,
      targetTrFat: 0,
      targetFiber: 30,
      targetSalt: 5.8,
      targetCalcium: 1000,
      itemsByCategory: {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
        'snack': [],
      },
    );
  }

  int get calsPercent =>
      targetCals > 0 ? ((totalCals / targetCals) * 100).round() : 0;

  bool get isCalsOver => totalCals > targetCals;

  int get calsOverDiff => (totalCals - targetCals).round();
  int get calsLeftDiff => (targetCals - totalCals).clamp(0, 99999).round();

  double get carbCals => totalCarbs * 4.0;
  double get proteinCals => totalProtein * 4.0;
  double get fatCals => totalFat * 9.0;
  double get totalMacroCals => carbCals + proteinCals + fatCals;

  double get carbCalPercent =>
      totalMacroCals > 0 ? (carbCals / totalMacroCals) * 100 : 0.0;
  double get proteinCalPercent =>
      totalMacroCals > 0 ? (proteinCals / totalMacroCals) * 100 : 0.0;
  double get fatCalPercent =>
      totalMacroCals > 0 ? (fatCals / totalMacroCals) * 100 : 0.0;

  int get carbsLeft => (targetCarbs - totalCarbs).clamp(0, 9999).round();
  int get carbsOver => (totalCarbs - targetCarbs).clamp(0, 9999).round();

  int get proteinLeft => (targetProtein - totalProtein).clamp(0, 9999).round();
  int get proteinOver => (totalProtein - targetProtein).clamp(0, 9999).round();

  int get fatLeft => (targetFat - totalFat).clamp(0, 9999).round();
  int get fatOver => (totalFat - targetFat).clamp(0, 9999).round();

  String get foodGrade {
    if (totalCals == 0) return "--";

    int score = 50;

    // Calorie adherence
    final calRatio = totalCals / targetCals;
    if (calRatio >= 0.85 && calRatio <= 1.10) {
      score += 25;
    } else if (calRatio >= 0.70 && calRatio <= 1.25) {
      score += 15;
    }

    // Protein adherence
    if (targetProtein > 0) {
      final protRatio = totalProtein / targetProtein;
      if (protRatio >= 0.80) {
        score += 20;
      } else if (protRatio >= 0.50) {
        score += 10;
      }
    }

    // Saturated fat control
    if (targetSatFat > 0 && totalSatFat <= targetSatFat) {
      score += 5;
    }

    if (score >= 90) return "A";
    if (score >= 80) return "A-";
    if (score >= 70) return "B+";
    if (score >= 60) return "B";
    if (score >= 50) return "B-";
    if (score >= 40) return "C+";
    return "C";
  }

  Color get foodGradeColor {
    final grade = foodGrade;
    if (grade.startsWith("A")) return const Color(0xFF00C896);
    if (grade.startsWith("B")) return const Color(0xFF37C97D);
    if (grade.startsWith("C")) return Colors.orange;
    return Colors.grey;
  }
}

class DayNutritionService {
  static String getDateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  static double calculateMacroValue(
    Map<String, dynamic> data,
    String keyPer100g, [
    String? directKey,
  ]) {
    if (directKey != null &&
        data.containsKey(directKey) &&
        data[directKey] is num) {
      return (data[directKey] as num).toDouble();
    }
    double valPer100 = (data[keyPer100g] as num? ?? 0).toDouble();
    double loggedGrams = 100.0;
    if (data['loggedServing'] != null &&
        data['loggedServing']['calculatedGrams'] != null) {
      loggedGrams = (data['loggedServing']['calculatedGrams'] as num).toDouble();
    }
    return (valPer100 / 100.0) * loggedGrams;
  }

  /// Real-time stream combining all 4 meals and user target profile
  static Stream<DayNutritionData> streamDayNutrition(
    String uid,
    DateTime date,
  ) {
    if (uid.isEmpty) {
      return Stream.value(DayNutritionData.empty(date));
    }

    final dateKey = getDateKey(date);

    final breakfastStream = FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(dateKey)
        .collection('breakfast')
        .snapshots();

    final lunchStream = FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(dateKey)
        .collection('lunch')
        .snapshots();

    final dinnerStream = FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(dateKey)
        .collection('dinner')
        .snapshots();

    final snackStream = FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(dateKey)
        .collection('snack')
        .snapshots();

    final userProfileStream = FirebaseFirestore.instance
        .collection('UserProfiles')
        .doc(uid)
        .snapshots();

    return Rx.combineLatest5(
      breakfastStream,
      lunchStream,
      dinnerStream,
      snackStream,
      userProfileStream,
      (
        QuerySnapshot bSnap,
        QuerySnapshot lSnap,
        QuerySnapshot dSnap,
        QuerySnapshot sSnap,
        DocumentSnapshot uSnap,
      ) {
        // User Targets
        double targetCals = 2000;
        double targetCarbs = 180;
        double targetProtein = 80;
        double targetFat = 70;
        double targetSatFat = 20;
        double targetTrFat = 0;
        double targetFiber = 30;
        double targetSalt = 5.8;
        double targetCalcium = 1000;

        if (uSnap.exists && uSnap.data() != null) {
          final uData = uSnap.data() as Map<String, dynamic>;
          final cals = (uData['dailyCalorieTarget'] as num?)?.toDouble() ?? 2000.0;
          final weight = (uData['weight'] as num?)?.toDouble() ?? 70.0;
          final goal = (uData['dietaryGoal'] as String?) ?? "Healthy Living";

          targetCals = cals;
          final macros = FatCalculatorService.calculateMacroTargets(
            weightKg: weight,
            calorieBudget: cals.toInt(),
            goal: goal,
          );
          targetCarbs = macros.carbs.toDouble();
          targetProtein = macros.protein.toDouble();
          targetFat = macros.fat.toDouble();
          targetSatFat = (cals * 0.10 / 9.0).clamp(15.0, 30.0);
        }

        final bDocs = bSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
        final lDocs = lSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
        final dDocs = dSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
        final sDocs = sSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

        final itemsMap = {
          'breakfast': bDocs,
          'lunch': lDocs,
          'dinner': dDocs,
          'snack': sDocs,
        };

        double totalCals = 0;
        double totalCarbs = 0;
        double totalProtein = 0;
        double totalFat = 0;
        double totalSatFat = 0;
        double totalTrFat = 0;
        double totalFiber = 0;
        double totalSalt = 0;
        double totalCalcium = 0;

        for (var list in itemsMap.values) {
          for (var item in list) {
            double cals = 0;
            if (item.containsKey('estCalories') && item['estCalories'] is num) {
              cals = (item['estCalories'] as num).toDouble();
            } else if (item.containsKey('calories') && item['calories'] is num) {
              cals = (item['calories'] as num).toDouble();
            } else {
              cals = calculateMacroValue(item, 'caloriesPer100g');
            }
            totalCals += cals;

            totalCarbs += calculateMacroValue(item, 'carbsPer100g', 'carbs');
            totalProtein += calculateMacroValue(item, 'proteinPer100g', 'protein');
            totalFat += calculateMacroValue(item, 'saturatedFatPer100g', 'fat');
            totalSatFat += calculateMacroValue(item, 'saturatedFatPer100g');
            totalFiber += calculateMacroValue(item, 'fiberPer100g');
            totalSalt += calculateMacroValue(item, 'saltPer100g');
            totalCalcium += calculateMacroValue(item, 'calciumPer100g');
          }
        }

        return DayNutritionData(
          date: date,
          dateKey: dateKey,
          totalCals: totalCals,
          totalCarbs: totalCarbs,
          totalProtein: totalProtein,
          totalFat: totalFat,
          totalSatFat: totalSatFat,
          totalTrFat: totalTrFat,
          totalFiber: totalFiber,
          totalSalt: totalSalt,
          totalCalcium: totalCalcium,
          targetCals: targetCals,
          targetCarbs: targetCarbs,
          targetProtein: targetProtein,
          targetFat: targetFat,
          targetSatFat: targetSatFat,
          targetTrFat: targetTrFat,
          targetFiber: targetFiber,
          targetSalt: targetSalt,
          targetCalcium: targetCalcium,
          itemsByCategory: itemsMap,
        );
      },
    );
  }
}
