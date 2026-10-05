import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

class DashboardData {
  final int breakfast;
  final int lunch;
  final int dinner;
  final int snack;
  final int burned;
  final double carbs;
  final double protein;
  final double fat;

  DashboardData({
    this.breakfast = 0,
    this.lunch = 0,
    this.dinner = 0,
    this.snack = 0,
    this.burned = 0,
    this.carbs = 0.0,
    this.protein = 0.0,
    this.fat = 0.0,
  });

  int get totalEaten => breakfast + lunch + dinner + snack;
}

class DashboardService {
  // Helper to format date as yyyy-MM-dd
  String _getDateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Stream<DashboardData> getDashboardStream(String userId, DateTime date) {
    final dateKey = _getDateKey(date);
    debugPrint(
      "🔥 DASHBOARD LISTENING TO NEW DB: mealslog/$userId/days/$dateKey",
    );

    // 1. Define Streams for Meals using the NEW Hierarchical Structure
    final breakfastStream = _getMealStream(userId, dateKey, 'breakfast');
    final lunchStream = _getMealStream(userId, dateKey, 'lunch');
    final dinnerStream = _getMealStream(userId, dateKey, 'dinner');
    final snackStream = _getMealStream(userId, dateKey, 'snack');

    // 2. Define Stream for Workout
    final workoutStream = FirebaseFirestore.instance
        .collection('ActivityLog')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          int totalBurned = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data(); // ActivityLog usually stays flatter
            if (data['date'] != null) {
              DateTime docDate = (data['date'] as Timestamp).toDate();
              // Check exact date match
              if (docDate.year == date.year &&
                  docDate.month == date.month &&
                  docDate.day == date.day) {
                totalBurned += (data['caloriesBurned'] as num? ?? 0).toInt();
              }
            }
          }
          return totalBurned;
        })
        .handleError((e) {
          debugPrint("⚠️ WORKOUT STREAM ERROR: $e");
          return 0;
        })
        .startWith(0);

    // 3. Merge streams
    return CombineLatestStream.list([
      breakfastStream,
      lunchStream,
      dinnerStream,
      snackStream,
      workoutStream,
    ]).map((results) {
      final b = results[0] as Map<String, double>;
      final l = results[1] as Map<String, double>;
      final d = results[2] as Map<String, double>;
      final s = results[3] as Map<String, double>;
      final burned = results[4] as int;

      debugPrint(
        "✅ DASHBOARD UPDATE: B:${b['cals']} L:${l['cals']} D:${d['cals']} S:${s['cals']}",
      );

      final totalCarbs = b['carbs']! + l['carbs']! + d['carbs']! + s['carbs']!;
      final totalProtein =
          b['protein']! + l['protein']! + d['protein']! + s['protein']!;
      final totalFat = b['fat']! + l['fat']! + d['fat']! + s['fat']!;

      return DashboardData(
        breakfast: b['cals']!.toInt(),
        lunch: l['cals']!.toInt(),
        dinner: d['cals']!.toInt(),
        snack: s['cals']!.toInt(),
        burned: burned,
        carbs: totalCarbs,
        protein: totalProtein,
        fat: totalFat,
      );
    });
  }

  // ✅ UPDATED: Queries mealslog/{uid}/days/{date}/{category}
  Stream<Map<String, double>> _getMealStream(
    String uid,
    String dateKey,
    String category,
  ) {
    if (uid.isEmpty) {
      return Stream.value({
        'cals': 0.0,
        'carbs': 0.0,
        'protein': 0.0,
        'fat': 0.0,
      });
    }

    // Direct path query
    return FirebaseFirestore.instance
        .collection('mealslog')
        .doc(uid)
        .collection('days')
        .doc(dateKey)
        .collection(category)
        .snapshots()
        .map((snapshot) {
          double cals = 0;
          double carbs = 0;
          double protein = 0;
          double fat = 0;

          for (var doc in snapshot.docs) {
            // ✅ FIX: Explicitly cast to Map<String, dynamic>
            final data = doc.data();

            // Priority: estCalories (from calculation) -> calories (fallback)
            if (data.containsKey('estCalories') && data['estCalories'] is num) {
              cals += (data['estCalories'] as num).toDouble();
            } else if (data['calories'] is num) {
              cals += (data['calories'] as num).toDouble();
            }

            carbs += (data['carbs'] as num? ?? 0).toDouble();
            protein += (data['protein'] as num? ?? 0).toDouble();
            fat += (data['fat'] as num? ?? 0).toDouble();
          }
          return {'cals': cals, 'carbs': carbs, 'protein': protein, 'fat': fat};
        })
        .handleError((e) {
          debugPrint("⚠️ $category ERROR: $e");
          return {'cals': 0.0, 'carbs': 0.0, 'protein': 0.0, 'fat': 0.0};
        })
        .startWith({'cals': 0.0, 'carbs': 0.0, 'protein': 0.0, 'fat': 0.0});
  }

  // ✅ UPDATED: Fetches weekly data from the new hierarchy
  Future<List<double>> getWeeklyCalories(
    String uid,
    DateTime anchorDate,
  ) async {
    List<double> weeklyData = List.filled(7, 0.0);
    if (uid.isEmpty) return weeklyData;

    // 1. Find Monday of the current week
    DateTime startOfWeek = anchorDate.subtract(
      Duration(days: anchorDate.weekday - 1),
    );
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    try {
      // We need to fetch data for 7 days
      List<Future<void>> dayTasks = [];

      for (int i = 0; i < 7; i++) {
        final dayDate = startOfWeek.add(Duration(days: i));
        final dateKey = _getDateKey(dayDate);
        final dayIndex = i;

        // Fetch all 4 categories for this specific day
        dayTasks.add(
          _fetchDayTotal(uid, dateKey).then((totalCals) {
            weeklyData[dayIndex] = totalCals;
          }),
        );
      }

      // Wait for all 7 days to be fetched
      await Future.wait(dayTasks);
    } catch (e) {
      debugPrint("Error fetching weekly data: $e");
    }

    return weeklyData;
  }

  // Helper to sum up breakfast, lunch, dinner, snack for ONE day
  Future<double> _fetchDayTotal(String uid, String dateKey) async {
    double total = 0;
    List<String> categories = ['breakfast', 'lunch', 'dinner', 'snack'];

    List<Future<QuerySnapshot>> tasks = categories.map((cat) {
      return FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid)
          .collection('days')
          .doc(dateKey)
          .collection(cat)
          .get();
    }).toList();

    final snapshots = await Future.wait(tasks);

    for (var snap in snapshots) {
      for (var doc in snap.docs) {
        // ✅ FIX: Explicitly cast to Map<String, dynamic> to fix nullable errors
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('estCalories') && data['estCalories'] is num) {
          total += (data['estCalories'] as num).toDouble();
        } else if (data['calories'] is num) {
          total += (data['calories'] as num).toDouble();
        }
      }
    }
    return total;
  }
}
