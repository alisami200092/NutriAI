// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<void> addMealData() async {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   // Boiled Rice
//   await firestore.collection('ActivityPlan').add({
//     'barcode': 'boiledrice1111111111111',
//     'name': 'boiled rice',
//     'caloriesPer100g': 129,
//     'carbsPer100g': 28,
//     'cholesterolPer100g': 0,
//     'fiberPer100g': 0.4,
//     'magnesiumPer100g': 12,
//     'monounsaturatedFatPer100g': 0.1,
//     'polyunsaturatedFatPer100g': 0.1,
//     'potassiumPer100g': 35,
//     'proteinPer100g': 2.9,
//     'saturatedPer100g': 0.1,
//     'servingSizes': [
//       {'grams': 100, 'label': '1 cup boiled rice'},
//     ],
//     'sugarsPer100g': 0.1,
//     'vitaminB6Per100g': 0.05,
//     'vitaminCPer100g': 0,
//   });

//   // Roti (Chapati)
//   await firestore.collection('meals').add({
//     'barcode': 'roti2222222222222',
//     'name': 'roti (chapati)',
//     'caloriesPer100g': 297,
//     'carbsPer100g': 46,
//     'cholesterolPer100g': 0,
//     'fiberPer100g': 4.9,
//     'magnesiumPer100g': 91,
//     'monounsaturatedFatPer100g': 1.2,
//     'polyunsaturatedFatPer100g': 1.5,
//     'potassiumPer100g': 340,
//     'proteinPer100g': 11,
//     'saturatedPer100g': 1.0,
//     'servingSizes': [
//       {'grams': 40, 'label': '1 medium roti'},
//     ],
//     'sugarsPer100g': 0.5,
//     'vitaminB6Per100g': 0.1,
//     'vitaminCPer100g': 0,
//   });

//   // Paratha
//   await firestore.collection('meals').add({
//     'barcode': 'paratha3333333333333',
//     'name': 'paratha',
//     'caloriesPer100g': 326,
//     'carbsPer100g': 45,
//     'cholesterolPer100g': 0,
//     'fiberPer100g': 9.6,
//     'magnesiumPer100g': 95,
//     'monounsaturatedFatPer100g': 3.0,
//     'polyunsaturatedFatPer100g': 2.5,
//     'potassiumPer100g': 350,
//     'proteinPer100g': 6.4,
//     'saturatedPer100g': 4.0,
//     'servingSizes': [
//       {'grams': 60, 'label': '1 paratha'},
//     ],
//     'sugarsPer100g': 1.0,
//     'vitaminB6Per100g': 0.1,
//     'vitaminCPer100g': 0,
//   });

//   // Cooked White Rice
//   await firestore.collection('meals').add({
//     'barcode': 'whiterice4444444444444',
//     'name': 'cooked white rice',
//     'caloriesPer100g': 130,
//     'carbsPer100g': 29,
//     'cholesterolPer100g': 0,
//     'fiberPer100g': 0.4,
//     'magnesiumPer100g': 12,
//     'monounsaturatedFatPer100g': 0.1,
//     'polyunsaturatedFatPer100g': 0.1,
//     'potassiumPer100g': 35,
//     'proteinPer100g': 2.6,
//     'saturatedPer100g': 0.1,
//     'servingSizes': [
//       {'grams': 100, 'label': '1 cup cooked rice'},
//     ],
//     'sugarsPer100g': 0.1,
//     'vitaminB6Per100g': 0.05,
//     'vitaminCPer100g': 0,
//   });

//   // Boiled White Rice
//   await firestore.collection('meals').add({
//     'barcode': 'boiledwhiterice5555555555555',
//     'name': 'boiled white rice',
//     'caloriesPer100g': 131,
//     'carbsPer100g': 28,
//     'cholesterolPer100g': 0,
//     'fiberPer100g': 0.4,
//     'magnesiumPer100g': 12,
//     'monounsaturatedFatPer100g': 0.1,
//     'polyunsaturatedFatPer100g': 0.1,
//     'potassiumPer100g': 35,
//     'proteinPer100g': 2.9,
//     'saturatedPer100g': 0.1,
//     'servingSizes': [
//       {'grams': 100, 'label': '1 cup boiled rice'},
//     ],
//     'sugarsPer100g': 0.1,
//     'vitaminB6Per100g': 0.05,
//     'vitaminCPer100g': 0,
//   });

//   //print("✅ Meal data added successfully!");
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Add this function ---
  Future<void> addSampleActivities() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    // Using a Batch Write is better for adding multiple documents at once
    WriteBatch batch = _firestore.batch();

    // 1. Reference for Skipping Rope
    DocumentReference doc1 = _firestore.collection('ActivityPlan').doc();
    batch.set(doc1, {
      'exerciseName': 'Skipping Rope',
      'durationMinutes': 30,
      'caloriesBurned': 360,
      'caloriesPerMinute': 12,
      'notes': 'Moderate skipping session at 100-120 jumps/min',
      'userId': user.uid, // ✅ Uses real ID
      'date': Timestamp.fromDate(DateTime(2025, 12, 24, 16, 40)),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Reference for Jumping Jacks
    DocumentReference doc2 = _firestore.collection('ActivityPlan').doc();
    batch.set(doc2, {
      'exerciseName': 'Jumping Jacks',
      'durationMinutes': 30,
      'caloriesBurned': 300,
      'caloriesPerMinute': 10,
      'notes': 'Moderate intensity jumping jacks session',
      'userId': user.uid, // ✅ Uses real ID
      'date': Timestamp.fromDate(DateTime(2025, 12, 24, 16, 45)),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Commit all changes
    await batch.commit();
  }
}
