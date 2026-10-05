import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:nutriapp/smart-watch/authentication/login.dart';
import 'package:nutriapp/smart-watch/authentication/profile_settings.dart';
import 'package:nutriapp/smart-watch/authentication/signup.dart';
import 'package:nutriapp/smart-watch/calories_log_screen.dart';
import 'package:nutriapp/smart-watch/swipe_widget.dart';
import 'package:nutriapp/smart-watch/macros_screen.dart';
import 'package:nutriapp/smart-watch/meallog_screen.dart';
import 'package:nutriapp/smart-watch/weightlog_screen.dart';
import 'package:nutriapp/smart-watch/water_intake_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NutriWatchApp());
}

class NutriWatchApp extends StatelessWidget {
  const NutriWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriWatch',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.cyanAccent,
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 12)),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return SyncWatchDataWrapper(uid: snapshot.data!.uid);
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => SyncWatchDataWrapper(
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
      },
    );
  }
}

class SyncWatchDataWrapper extends StatefulWidget {
  final String uid;
  const SyncWatchDataWrapper({super.key, required this.uid});

  @override
  State<SyncWatchDataWrapper> createState() => _SyncWatchDataWrapperState();
}

class _SyncWatchDataWrapperState extends State<SyncWatchDataWrapper> {
  // Initialize Logger
  final Logger _logger = Logger();

  StreamSubscription? _profileSub;
  StreamSubscription? _breakfastSub;
  StreamSubscription? _lunchSub;
  StreamSubscription? _dinnerSub;
  StreamSubscription? _snackSub;

  int dailyCalorieTarget = 2000;
  int breakfastCals = 0;
  int lunchCals = 0;
  int dinnerCals = 0;
  int snackCals = 0;

  bool isLoading = true;

  // Calculates the sum dynamically
  int get totalConsumed => breakfastCals + lunchCals + dinnerCals + snackCals;

  @override
  void initState() {
    super.initState();
    _startSyncingData();
  }

  void _startSyncingData() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var db = FirebaseFirestore.instance;

    _logger.i("WATCH IS LOOKING FOR DATA ON: $today");

    // 1. Listen to Calorie Goal
    _profileSub = db
        .collection('UserProfiles')
        .doc(widget.uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            setState(() {
              var target = doc.data()!['dailyCalorieTarget'];
              dailyCalorieTarget = (target is num) ? target.toInt() : 2000;
              isLoading = false;
            });
          } else {
            setState(() => isLoading = false);
          }
        });

    // Helper to calculate total calories from a snapshot
    int calculateTotal(QuerySnapshot snap) {
      int temp = 0;
      for (var doc in snap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['calories'] != null) {
          temp += (data['calories'] as num).toInt();
        }
      }
      return temp;
    }

    // 2. Listen to all 4 meal types
    var baseDoc = db
        .collection('mealslog')
        .doc(widget.uid)
        .collection('days')
        .doc(today);

    _breakfastSub = baseDoc.collection('breakfast').snapshots().listen((s) {
      setState(() => breakfastCals = calculateTotal(s));
      _logger.d("Breakfast Calories Updated: $breakfastCals");
    });

    _lunchSub = baseDoc.collection('lunch').snapshots().listen((s) {
      setState(() => lunchCals = calculateTotal(s));
      _logger.d("Lunch Calories Updated: $lunchCals");
    });

    _dinnerSub = baseDoc.collection('dinner').snapshots().listen((s) {
      setState(() => dinnerCals = calculateTotal(s));
      _logger.d("Dinner Calories Updated: $dinnerCals");
    });

    _snackSub = baseDoc.collection('snack').snapshots().listen((s) {
      setState(() => snackCals = calculateTotal(s));
      _logger.d("Snack Calories Updated: $snackCals");
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _breakfastSub?.cancel();
    _lunchSub?.cancel();
    _dinnerSub?.cancel();
    _snackSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    return SwipeController(
      pages: [
        CalorieRingScreen(consumed: totalConsumed, target: dailyCalorieTarget),
        const MacrosScreen(),
        const MealLogScreen(),
        const WeightLogScreen(),
        WaterIntakeScreen(uid: widget.uid),
        const ProfileScreen(),
      ],
    );
  }
}
