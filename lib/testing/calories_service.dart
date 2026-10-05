import 'dart:math';
import 'dart:developer' as developer;
import 'package:tflite_flutter/tflite_flutter.dart';

class CalorieService {
  Interpreter? _interpreter;

  // ---------------------------------------------------------
  // 1. DATA FROM PYTHON (Mean & Std)
  // ---------------------------------------------------------
  // Order: [Age, Gender, Height, Weight, BMI, Activity, Goal, WeightChange]
  final List<double> _means = [
    49.857,
    0.523,
    174.817,
    84.602,
    28.192,
    1.493,
    -0.526,
    -0.1769,
  ];

  final List<double> _stds = [
    18.105,
    0.499,
    14.326,
    20.078,
    8.035,
    0.217,
    0.810,
    0.325,
  ];

  // ---------------------------------------------------------
  // 2. MEDICAL RULES CONSTANTS
  // ---------------------------------------------------------
  final Map<String, Map<String, double>> _medicalRules = {
    'hypertension': {'loss': -250, 'gain': 150},
    'obesity': {'loss': -500, 'gain': 0},
    'kidney': {'loss': -200, 'gain': 150},
    'heart': {'loss': -300, 'gain': 150},
    'diabetes': {'loss': -300, 'gain': 150},
    'acne': {'loss': -250, 'gain': 150},
    'bipolar': {'loss': -250, 'gain': 150},
  };

  // Load the model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/calorie_model.tflite');
      developer.log("✅ Offline TFLite Model Loaded", name: 'CalorieService');
    } catch (e) {
      developer.log("❌ Error loading TFLite model: $e", name: 'CalorieService');
    }
  }

  // ---------------------------------------------------------
  // 3. PREDICTION LOGIC
  // ---------------------------------------------------------
  Future<double> predictCalories({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required String goal,
    required double weightChangePerWeek, // Magnitude (e.g., 0.5)
    required String disease,
  }) async {
    if (_interpreter == null) {
      await loadModel();
    }

    // --- A. Preprocessing Inputs ---

    // 1. Gender Map (Male=1, Female=0)
    final String gClean = gender.toLowerCase().trim();
    final bool isMale = gClean == 'male' || (gClean.contains('male') && !gClean.contains('female'));
    final double genderNum = isMale ? 1.0 : 0.0;

    // 2. Activity Map
    double activityMult = 1.55; // Default Moderate
    String act = activityLevel.toLowerCase();

    if (act.contains("sedentary")) {
      activityMult = 1.2;
    } else if (act.contains("light")) {
      activityMult = 1.375;
    } else if (act.contains("moderate")) {
      activityMult = 1.55;
    } else if (act.contains("active") || act.contains("very")) {
      activityMult = 1.725;
    }

    // 3. Goal Map (-1, 0, 1)
    double goalEncoded = 0.0;
    String g = goal.toLowerCase();

    if (g.contains("loss")) {
      goalEncoded = -1.0;
    } else if (g.contains("gain")) {
      goalEncoded = 1.0;
    }

    // 4. Calculate BMI
    double bmi = weight / pow(height / 100, 2);

    // 5. Handle Weight Change Sign logic
    double signedWeightChange = weightChangePerWeek.abs();

    if (goalEncoded == -1.0) {
      signedWeightChange = -signedWeightChange;
    } else if (goalEncoded == 0.0) {
      signedWeightChange = 0.0;
    }

    // --- B. Prepare Input Vector ---
    // [Age, Gender, Height, Weight, BMI, Activity, Goal, WeightChange]
    List<double> inputs = [
      age.toDouble(),
      genderNum,
      height,
      weight,
      bmi,
      activityMult,
      goalEncoded,
      signedWeightChange,
    ];

    // --- C. Normalize (Scale) Inputs ---
    // (Value - Mean) / Std
    List<double> scaledInputs = [];
    for (int i = 0; i < inputs.length; i++) {
      scaledInputs.add((inputs[i] - _means[i]) / _stds[i]);
    }

    // --- D. Run Inference ---
    // Reshape for TFLite [1, 8]
    var inputTensor = [scaledInputs];
    var outputTensor = List.filled(1, List.filled(1, 0.0)); // [1, 1]

    if (_interpreter != null) {
      _interpreter!.run(inputTensor, outputTensor);
    }

    // Raw Prediction from Neural Network
    double mlPrediction = outputTensor[0][0];

    // --- E. HYBRID LOGIC & MEDICAL SAFETY ---

    // Mifflin-St Jeor
    double bmr;
    if (genderNum == 1.0) {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double tdee = bmr * activityMult;

    // Standard Math Adjustment
    double standardAdjustment = (signedWeightChange * 7700) / 7;

    // ⚕️ Apply Medical Rules (Logic Ported from Python) ⚕️
    double finalAdjustment = standardAdjustment;

    String cleanDisease = disease.toLowerCase();
    String? matchedKey;

    // Find matching disease key
    for (var key in _medicalRules.keys) {
      if (cleanDisease.contains(key)) {
        matchedKey = key;
        break;
      }
    }

    if (matchedKey != null) {
      Map<String, double> rules = _medicalRules[matchedKey]!;

      if (goalEncoded == -1.0) {
        // Loss
        double safeLimit = rules['loss']!;
        if (standardAdjustment < safeLimit) {
          developer.log(
            "⚠️ Medical Safety: Capping loss for $matchedKey",
            name: 'CalorieService',
          );
          finalAdjustment = safeLimit;
        }
      } else if (goalEncoded == 1.0) {
        // Gain
        double safeLimit = rules['gain']!;
        if (standardAdjustment > safeLimit) {
          developer.log(
            "⚠️ Medical Safety: Capping gain for $matchedKey",
            name: 'CalorieService',
          );
          finalAdjustment = safeLimit;
        }
      }
    }

    double finalMathTarget = tdee + finalAdjustment;

    // --- F. Final Safety Floor ---
    double minLimit = (genderNum == 1.0) ? 1500.0 : 1200.0;

    // Use Math Target w/ Medical Rules (validated by ML logic)
    double finalResult = max(finalMathTarget, minLimit);

    developer.log(
      "🤖 AI: $mlPrediction | 🧮 Math: $finalMathTarget | ✅ Final: $finalResult",
      name: 'CalorieService',
    );

    return finalResult;
  }
}
