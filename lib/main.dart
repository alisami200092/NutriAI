import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:nutriapp/activity/activity_log_page.dart';
import 'package:nutriapp/authentication/login_page.dart';
import 'package:nutriapp/chatbot/chat_provider.dart';
import 'package:nutriapp/dashboard/bottom_nav.dart';
import 'package:nutriapp/meal_log/camera_screen.dart';
import 'package:nutriapp/services/notification_service.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/gender_selection.dart';
import 'screens/height_scale.dart';
import 'screens/age.dart';
import 'screens/dietary_goals.dart';
import 'screens/weight.dart';
import 'screens/dietary_restrictions.dart';
import 'package:camera/camera.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

late final List<CameraDescription> _cameras;
final YoloService _yolo = YoloService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp();
  await dotenv.load(fileName: "assets/api-key.env");

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  //Camera intialization
  try {
    _cameras = await availableCameras();
    logger.i("Main: found ${_cameras.length} cameras");
  } catch (e) {
    _cameras = [];
    logger.e("Main: failed to get available cameras: $e");
  }

  //Yolo service initliazation
  try {
    await _yolo.init();
    logger.i("YOLO service initialized");
  } catch (e) {
    logger.e("YOLO init failed: $e");
  }

  // Initialize Dynamic Notification & Alert Service
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    logger.e("NotificationService init failed: $e");
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('ar'),
        Locale('fr'),
        Locale('ur'),
        Locale('de'),
        Locale('it'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => ChatProvider(),
        child: const MainApp(),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 👉 2. FIX: ADDED THESE 3 REQUIRED LINES 👈
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ------------------------------------------
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/":
            return MaterialPageRoute(builder: (context) => SplashScreen());
          case "/onboarding":
            return MaterialPageRoute(builder: (context) => OnboardingScreen());
          case "/login":
            return MaterialPageRoute(
              builder: (context) => LoginPage(cameras: _cameras, yolo: _yolo),
            );
          case "/gender":
            return MaterialPageRoute(
              builder: (context) => const GenderSelectionScreen(),
            );
          case "/height":
            final selectedGender = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) =>
                  HeightScalePage(selectedGender: selectedGender),
            );
          case "/age":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AgeSelectionPage(
                selectedGender: args['gender'],
                heightCm: args['heightCm'],
              ),
            );
          case "/goals":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DietaryGoalsPage(
                age: args['age'],
                gender: args['gender'],
                heightCm: args['heightCm'],
                currentWeight: args['currentWeight'],
              ),
            );
          case "/weight":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => WeightPage(
                dietaryGoal: args['dietaryGoal'],
                heightCm: args['heightCm'],
                selectedAge: args['selectedAge'],
                selectedGender: args['selectedGender'],
              ),
            );
          case '/restrictions':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DietaryRestrictionsPage(
                age: args['age'],
                heightCm: args['heightCm'],
                gender: args['gender'],
                weightKg: args['weightKg'],
                targetWeight: args['targetWeight'],
                dietaryGoal: args['dietaryGoal'],
                eventName: args['eventName'],
                eventDate: args['eventDate'],
                activityLevel: args['activityLevel'],
                weightChangePerWeek: args['weightChangePerWeek'],
              ),
            );
          case "/main":
            return MaterialPageRoute(
              builder: (context) => BottomNav(cameras: _cameras, yolo: _yolo),
            );
          case "/camera":
            return MaterialPageRoute(
              builder: (context) =>
                  CameraScreen(cameras: _cameras, yolo: _yolo),
            );
          case "/premium":
            return MaterialPageRoute(
              builder: (context) => const PremiumScreen(),
            );
          case "/activity":
            return MaterialPageRoute(
              builder: (context) => const WorkoutScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
