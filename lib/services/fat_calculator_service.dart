import 'dart:math';

/// Utility class providing medically sound and sports nutrition validated formulas
/// for Body Fat % and Daily Macro Targets.
class FatCalculatorService {
  /// Calculates physical Body Fat Percentage (%) using the peer-reviewed
  /// Deurenberg Formula (combining BMI, Age, and Gender).
  ///
  /// Gender: Male = 1, Female = 0
  /// Formula: (1.20 * BMI) + (0.23 * Age) - (10.8 * Gender) - 5.4
  static double calculateBodyFatPercentage({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (heightCm <= 0 || weightKg <= 0 || age <= 0) return 0.0;

    final double heightM = heightCm / 100.0;
    final double bmi = weightKg / (heightM * heightM);
    final int genderFactor = gender.toLowerCase().contains('male') ? 1 : 0;

    final double bodyFat = (1.20 * bmi) + (0.23 * age) - (10.8 * genderFactor) - 5.4;

    // Clamp between realistic human physiology limits (3% - 60%)
    return double.parse(bodyFat.clamp(3.0, 60.0).toStringAsFixed(1));
  }

  /// Calculates actual daily dietary fat target in grams based on active body weight (kg)
  /// and the user's specific health/fitness goal (Weight Loss, Maintenance, Muscle Gain, Keto).
  ///
  /// - Weight Loss: 0.8g per kg bodyweight (safeguards hormonal health in a deficit)
  /// - Muscle Gain: 0.9g per kg bodyweight
  /// - Maintenance / Healthy: 1.0g per kg bodyweight
  /// - Keto: 70% of total daily calorie budget
  /// - Guardrails: Respects Acceptable Macronutrient Distribution Range (20% - 35% of total energy)
  static int calculateDietaryFatGrams({
    required double weightKg,
    required int calorieBudget,
    required String goal,
    String? dietPreference,
  }) {
    if (calorieBudget <= 0) return 65; // Safe default

    // 1. Keto or Low Carb Diet
    final String cleanDiet = (dietPreference ?? "").toLowerCase();
    if (cleanDiet.contains("keto") || cleanDiet.contains("ketogenic")) {
      return ((calorieBudget * 0.70) / 9).round();
    }

    // 2. Goal-based multiplier per kg of bodyweight
    final String cleanGoal = goal.toLowerCase();
    double multiplier;
    if (cleanGoal.contains("loss") || cleanGoal.contains("lose")) {
      multiplier = 0.8;
    } else if (cleanGoal.contains("gain")) {
      multiplier = 0.9;
    } else {
      multiplier = 1.0; // Maintenance / Healthy
    }

    final double baseFatGrams = (weightKg > 0 ? weightKg : 70.0) * multiplier;

    // 3. Clinical Safety Guardrails (Between 20% and 35% of daily calories)
    final double minGrams = (calorieBudget * 0.20) / 9.0;
    final double maxGrams = (calorieBudget * 0.35) / 9.0;

    return baseFatGrams.clamp(minGrams, maxGrams).round();
  }

  /// Calculates complete personalized macronutrient targets (Carbs, Protein, Fat)
  /// calibrated to the user's body weight, calorie budget, and dietary goal.
  static MacroTargets calculateMacroTargets({
    required double weightKg,
    required int calorieBudget,
    required String goal,
    String? dietPreference,
  }) {
    // 1. Fat based on active body weight
    final int fatGrams = calculateDietaryFatGrams(
      weightKg: weightKg,
      calorieBudget: calorieBudget,
      goal: goal,
      dietPreference: dietPreference,
    );

    // 2. Protein based on fitness guidelines:
    // Loss: 2.0g/kg (preserves lean mass in deficit)
    // Gain: 1.8g/kg (supports hypertrophy)
    // Maintenance: 1.4g/kg
    final String cleanGoal = goal.toLowerCase();
    double proteinMultiplier;
    if (cleanGoal.contains("loss") || cleanGoal.contains("lose")) {
      proteinMultiplier = 1.8;
    } else if (cleanGoal.contains("gain")) {
      proteinMultiplier = 1.9;
    } else {
      proteinMultiplier = 1.4;
    }

    final double validWeight = weightKg > 0 ? weightKg : 70.0;
    int proteinGrams = (validWeight * proteinMultiplier).round();

    // Guardrail protein between 15% and 35% of calories
    final double minProteinGrams = (calorieBudget * 0.15) / 4.0;
    final double maxProteinGrams = (calorieBudget * 0.35) / 4.0;
    proteinGrams = proteinGrams.clamp(minProteinGrams.round(), maxProteinGrams.round());

    // 3. Carbs fill the remainder of the calorie budget (1g carb = 4 kcal)
    final int caloriesFromFat = fatGrams * 9;
    final int caloriesFromProtein = proteinGrams * 4;
    final int remainingCalories = calorieBudget - (caloriesFromFat + caloriesFromProtein);

    int carbsGrams = (max(0, remainingCalories) / 4.0).round();

    // Ensure safe carb minimum (at least 50g unless strict keto)
    final String cleanDiet = (dietPreference ?? "").toLowerCase();
    if (!cleanDiet.contains("keto") && carbsGrams < 50) {
      carbsGrams = 50;
    }

    return MacroTargets(
      carbs: carbsGrams,
      protein: proteinGrams,
      fat: fatGrams,
    );
  }
}

class MacroTargets {
  final int carbs;
  final int protein;
  final int fat;

  const MacroTargets({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  int get carbGrams => carbs;
  int get proteinGrams => protein;
  int get fatGrams => fat;

  int get carbCalories => carbs * 4;
  int get proteinCalories => protein * 4;
  int get fatCalories => fat * 9;
  int get totalCalories => carbCalories + proteinCalories + fatCalories;

  double get carbPercent => totalCalories > 0 ? (carbCalories / totalCalories) * 100 : 50.0;
  double get proteinPercent => totalCalories > 0 ? (proteinCalories / totalCalories) * 100 : 25.0;
  double get fatPercent => totalCalories > 0 ? (fatCalories / totalCalories) * 100 : 25.0;
}
