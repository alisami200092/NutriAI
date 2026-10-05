// firebase_meal_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String defaultUserId = 'abc123';

  Future<void> addDefaultMeals() async {
    final WriteBatch batch = _firestore.batch();
    final CollectionReference meals = _firestore.collection('meals');

    final List<Map<String, dynamic>> items = [
      // ---------------- Burgers & Sandwiches ----------------
      {
        'barcode': 'beefburger123',
        'name': 'Beef Burger',
        'caloriesPer100g': 254,
        'proteinPer100g': 12.7,
        'carbsPer100g': 3.6,
        'fatPer100g': 20.8,
        'saturatedPer100g': 9.1,
        'cholesterolPer100g': 75,
        'servingSizes': [
          {'grams': 150, 'label': '1 beef burger'},
        ],
      },
      {
        'barcode': 'chickenburger123',
        'name': 'Chicken Burger',
        'caloriesPer100g': 237,
        'proteinPer100g': 27.1,
        'carbsPer100g': 0,
        'fatPer100g': 13.5,
        'saturatedPer100g': 3.8,
        'cholesterolPer100g': 87,
        'servingSizes': [
          {'grams': 150, 'label': '1 chicken burger'},
        ],
      },
      {
        'barcode': 'tikka_sandwich123',
        'name': 'Tikka Sandwich',
        'caloriesPer100g': 225,
        'proteinPer100g': 9.0,
        'carbsPer100g': 25.0,
        'fatPer100g': 9.7,
        'saturatedPer100g': 2.0,
        'cholesterolPer100g': 25,
        'servingSizes': [
          {'grams': 180, 'label': '1 tikka sandwich'},
        ],
      },
      {
        'barcode': 'fajita_sandwich123',
        'name': 'Fajita Sandwich',
        'caloriesPer100g': 150,
        'proteinPer100g': 10.5,
        'carbsPer100g': 13.6,
        'fatPer100g': 5.9,
        'saturatedPer100g': 2.2,
        'cholesterolPer100g': 25,
        'servingSizes': [
          {'grams': 170, 'label': '1 fajita sandwich'},
        ],
      },
      {
        'barcode': 'club_sandwich123',
        'name': 'Club Sandwich',
        'caloriesPer100g': 232,
        'proteinPer100g': 17.2,
        'carbsPer100g': 19.9,
        'fatPer100g': 8.1,
        'saturatedPer100g': 3.0,
        'cholesterolPer100g': 114,
        'servingSizes': [
          {'grams': 200, 'label': '1 club sandwich'},
        ],
      },
      {
        'barcode': 'peri_peri_sandwich123',
        'name': 'Peri Peri Chicken Sandwich',
        'caloriesPer100g': 300,
        'proteinPer100g': 22.0,
        'carbsPer100g': 24.0,
        'fatPer100g': 12.0,
        'saturatedPer100g': 3.5,
        'cholesterolPer100g': 80,
        'servingSizes': [
          {'grams': 180, 'label': '1 peri peri sandwich'},
        ],
      },
      {
        'barcode': 'bbq_sandwich123',
        'name': 'BBQ Sandwich',
        'caloriesPer100g': 210,
        'proteinPer100g': 14.0,
        'carbsPer100g': 22.0,
        'fatPer100g': 8.5,
        'saturatedPer100g': 2.8,
        'cholesterolPer100g': 50,
        'servingSizes': [
          {'grams': 180, 'label': '1 BBQ sandwich'},
        ],
      },

      // ---------------- Fish ----------------
      {
        'barcode': 'friedfish123',
        'name': 'Fried Fish',
        'caloriesPer100g': 232,
        'proteinPer100g': 19.0,
        'carbsPer100g': 11.0,
        'fatPer100g': 13.0,
        'saturatedPer100g': 2.5,
        'cholesterolPer100g': 65,
        'servingSizes': [
          {'grams': 100, 'label': '1 piece fried fish'},
        ],
      },
      {
        'barcode': 'grilledfish123',
        'name': 'Grilled Fish',
        'caloriesPer100g': 143,
        'proteinPer100g': 20.0,
        'carbsPer100g': 0.0,
        'fatPer100g': 6.0,
        'saturatedPer100g': 1.5,
        'cholesterolPer100g': 55,
        'servingSizes': [
          {'grams': 120, 'label': '1 fillet grilled fish'},
        ],
      },
      {
        'barcode': 'fishburger123',
        'name': 'Fish Burger',
        'caloriesPer100g': 230,
        'proteinPer100g': 12.0,
        'carbsPer100g': 22.0,
        'fatPer100g': 9.0,
        'saturatedPer100g': 2.0,
        'cholesterolPer100g': 45,
        'servingSizes': [
          {'grams': 160, 'label': '1 fish burger'},
        ],
      },
      {
        'barcode': 'fingerfish123',
        'name': 'Fish Fingers',
        'caloriesPer100g': 270,
        'proteinPer100g': 12.0,
        'carbsPer100g': 24.0,
        'fatPer100g': 14.0,
        'saturatedPer100g': 2.5,
        'cholesterolPer100g': 40,
        'servingSizes': [
          {'grams': 100, 'label': '100 g fish fingers'},
        ],
      },

      // ---------------- Karahi ----------------
      {
        'barcode': 'chickenkarahi123',
        'name': 'Chicken Karahi',
        'caloriesPer100g': 180,
        'proteinPer100g': 15.0,
        'carbsPer100g': 4.0,
        'fatPer100g': 12.0,
        'saturatedPer100g': 3.0,
        'cholesterolPer100g': 65,
        'servingSizes': [
          {'grams': 200, 'label': '1 serving chicken karahi'},
        ],
      },
      {
        'barcode': 'muttonkarahi123',
        'name': 'Mutton Karahi',
        'caloriesPer100g': 220,
        'proteinPer100g': 17.0,
        'carbsPer100g': 3.0,
        'fatPer100g': 16.0,
        'saturatedPer100g': 5.0,
        'cholesterolPer100g': 85,
        'servingSizes': [
          {'grams': 200, 'label': '1 serving mutton karahi'},
        ],
      },

      // ---------------- Biryani ----------------
      {
        'barcode': 'chickenbiryani123',
        'name': 'Chicken Biryani',
        'caloriesPer100g': 240,
        'proteinPer100g': 12.0,
        'carbsPer100g': 28.0,
        'fatPer100g': 8.0,
        'saturatedPer100g': 2.5,
        'cholesterolPer100g': 55,
        'servingSizes': [
          {'grams': 250, 'label': '1 plate chicken biryani'},
        ],
      },
      {
        'barcode': 'muttonbiryani123',
        'name': 'Mutton Biryani',
        'caloriesPer100g': 290,
        'proteinPer100g': 14.0,
        'carbsPer100g': 27.0,
        'fatPer100g': 12.0,
        'saturatedPer100g': 4.0,
        'cholesterolPer100g': 75,
        'servingSizes': [
          {'grams': 250, 'label': '1 plate mutton biryani'},
        ],
      },

      // ---------------- Chai (per 100g / per 100ml approximations) ----------------
      {
        'barcode': 'doodhpatti123',
        'name': 'Doodh Patti (Milk Tea)',
        'caloriesPer100g': 50, // approx per 100ml
        'proteinPer100g': 1.2,
        'carbsPer100g': 5.0,
        'fatPer100g': 2.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup milk tea'},
        ],
      },
      {
        'barcode': 'karakchai123',
        'name': 'Karak Chai',
        'caloriesPer100g': 55,
        'proteinPer100g': 1.3,
        'carbsPer100g': 5.5,
        'fatPer100g': 2.2,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup karak chai'},
        ],
      },
      {
        'barcode': 'kashmirichai123',
        'name': 'Kashmiri Chai',
        'caloriesPer100g': 65,
        'proteinPer100g': 1.5,
        'carbsPer100g': 6.0,
        'fatPer100g': 3.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup Kashmiri chai'},
        ],
      },
      {
        'barcode': 'qahwa123',
        'name': 'Qahwa (Green Tea / Simple Kawa)',
        'caloriesPer100g': 2,
        'proteinPer100g': 0.0,
        'carbsPer100g': 0.0,
        'fatPer100g': 0.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup qahwa'},
        ],
      },
      {
        'barcode': 'masalachai123',
        'name': 'Masala Chai',
        'caloriesPer100g': 50,
        'proteinPer100g': 1.2,
        'carbsPer100g': 5.0,
        'fatPer100g': 2.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup masala chai'},
        ],
      },
      {
        'barcode': 'sulaimani123',
        'name': 'Sulaimani Chai',
        'caloriesPer100g': 2,
        'proteinPer100g': 0.0,
        'carbsPer100g': 0.0,
        'fatPer100g': 0.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup sulaimani chai'},
        ],
      },
      {
        'barcode': 'noonchai123',
        'name': 'Noon Chai (Salted Tea)',
        'caloriesPer100g': 60,
        'proteinPer100g': 1.4,
        'carbsPer100g': 5.0,
        'fatPer100g': 2.5,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup noon chai'},
        ],
      },
      {
        'barcode': 'elaichi_chai123',
        'name': 'Elaichi Chai (Cardamom Tea)',
        'caloriesPer100g': 50,
        'proteinPer100g': 1.2,
        'carbsPer100g': 5.0,
        'fatPer100g': 2.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup elaichi chai'},
        ],
      },
      {
        'barcode': 'adrak_chai123',
        'name': 'Adrak Chai (Ginger Tea)',
        'caloriesPer100g': 50,
        'proteinPer100g': 1.2,
        'carbsPer100g': 5.0,
        'fatPer100g': 2.0,
        'servingSizes': [
          {'grams': 240, 'label': '1 cup adrak chai'},
        ],
      },
    ];

    // Add userId, timestamps and commit to batch
    for (final item in items) {
      final docRef = meals.doc(); // auto id
      final docData = <String, dynamic>{
        ...item,
        'userId': defaultUserId,
        'date': Timestamp.fromDate(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(docRef, docData);
    }

    // Commit batch
    await batch.commit();
  }
}
