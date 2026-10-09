# NutriAI 🥗
### Smart Nutrition & Meal Planning App for Mobile and Wear OS

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://stripe.com)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o-412991?style=for-the-badge&logo=openai&logoColor=white)](https://openai.com)
[![Wear OS](https://img.shields.io/badge/Wear%20OS-Smartwatch-4285F4?style=for-the-badge&logo=android&logoColor=white)](https://wearos.google.com)
[![Languages](https://img.shields.io/badge/Languages-7%20Supported-4CAF50?style=for-the-badge)](https://en.wikipedia.org/wiki/Internationalization_and_localization)

---

## 📖 About the Project

**NutriAI** is a full-featured health, diet, and nutrition tracking mobile app built using **Flutter**. It is designed to help people reach their fitness goals—whether losing fat, building muscle, or maintaining weight—without the frustration of complicated tracking.

Instead of just logging numbers, NutriAI acts as a personal nutrition coach:
- It creates **personalized meal plans** tailored to real regional diets (Balanced, Mediterranean, Keto, DASH, Indian, Pakistani).
- It uses **on-device camera vision (YOLO)** so users can scan food dishes and log calories in seconds.
- It includes a **Wear OS smartwatch app** for checking daily targets and logging meals from the wrist.
- It features **Gut Shield**, a safety mode that detects digestive distress (like acid reflux or cramps), filters out irritating foods, and exports a clean 2-page medical brief PDF for a doctor.
- It processes secure subscriptions through **Stripe Payment Sheet**.
- It is translated into **7 languages** with full Right-to-Left (RTL) support for Arabic and Urdu.

---

## 🎥 App Demo Video (2 Minutes)

Watch a complete 2-minute walkthrough showing the app in action on a real device—from the welcome flow to the dashboard:

https://github.com/user-attachments/assets/app_demo_walkthrough.mp4

> **Direct file:** The 15MB high-resolution demo video is also included in this repository at [`assets/Git-hub-images/app_demo_walkthrough.mp4`](assets/Git-hub-images/app_demo_walkthrough.mp4).

---

## ✨ Key Features

1. **Smart Onboarding (15 Steps)**: Collects age, height, weight, activity level, dietary goals, allergies, and health conditions to calculate accurate BMR, TDEE, and daily calorie targets.
2. **Personalized Meal Planner**: Generates daily breakfast, lunch, dinner, and snack options based on the user's chosen diet style. Users can swap individual dishes or regenerate the whole day with one tap.
3. **Camera Food Scanner**: Uses on-device object detection to recognize food items in real time through the camera and autofill calories and macros.
4. **Gut Shield & Doctor PDF Export**: Detects when a user has an upset stomach or acid reflux, hides trigger foods (dairy, spicy, acidic), and creates a ready-to-print medical intake PDF.
5. **Wear OS Smartwatch Companion**: A dedicated smartwatch UI with calorie remaining gauges, macro progress bars, and wearable food logging.
6. **Detailed Food & Nutrition Diary**: Track daily calories, macros (protein, carbs, fats), micronutrients, and view letter grades (A, B, C) for food quality.
7. **NutriBot AI Coach**: An in-app assistant powered by OpenAI that answers nutrition questions and recalls what the user ate during the day.
8. **Workout & Hydration Tracking**: Log exercises with estimated calories burned and track daily water glasses with winter/summer goal modes.
9. **Profile & Goals Hub ("Me" Section)**: Manage weight progress, body measurements (waist, hips, chest), physique progress photos, custom macro targets, and connected fitness devices.
10. **Stripe Payments**: Real in-app checkout supporting Credit/Debit cards, Link, Cash App, and digital wallets.
11. **7 Languages with RTL Support**: Easily switch between English, Urdu, Arabic, Spanish, French, German, and Italian.

---

## 📱 Screenshots & Visual Walkthrough

All screenshots below were taken during real device testing on a **Samsung Galaxy A55 5G** and a **circular Wear OS smartwatch**.

---

### 1. Onboarding Walkthrough (15 Steps)
A guided step-by-step setup that builds a customized nutrition plan.

| 01. Gender | 02. Age | 03. Height | 04. Weight & BMI |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/01_onboarding_01_gender.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_02_age.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_03_height.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_04_weight_bmi.jpg" width="220"/> |

| 05. Main Goal | 06. Target Weight | 07. Motivation / Event | 08. Target Date |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/01_onboarding_05_dietary_goals.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_06_target_weight.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_07_motivation_event.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_08_target_date.jpg" width="220"/> |

| 09. Activity Level | 10. Calorie Surplus / Deficit | 11. Food Allergies | 12. Diet Preference |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/01_onboarding_09_activity_bmr_tdee.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_10_speed_surplus_slider.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_11_allergies_restrictions.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_12_diet_preference.jpg" width="220"/> |

| 13. Health Conditions | 14. Your Name | 15. Plan Summary |
|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/01_onboarding_13_medical_conditions.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_14_user_name.jpg" width="220"/> | <img src="assets/Git-hub-images/01_onboarding_15_profile_summary.jpg" width="220"/> |

---

### 2. Dashboard & Daily Meal Plans
The main screen displays calories remaining, macro progress rings, and intelligent meal recommendations with one-tap replacement.

| Home Dashboard | Mediterranean Plan | Swap All Meals | Swap Single Meal | Day Totals |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/03_dashboard_main_overview.jpg" width="200"/> | <img src="assets/Git-hub-images/02_mealplan_mediterranean_knn.jpg" width="200"/> | <img src="assets/Git-hub-images/02_mealplan_dashboard_cards_replace_all.jpg" width="200"/> | <img src="assets/Git-hub-images/02_mealplan_snack_card_replace_single.jpg" width="200"/> | <img src="assets/Git-hub-images/03_dashboard_day_totals_cards.jpg" width="200"/> |

---

### 3. Food Scanning with Camera & Food Diary
Log food either by scanning with the camera or through the built-in food database.

| Scanner Home | Camera Viewfinder | Scanned Apple | Scanned Chicken Breast | Log Meal Sheet |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/07_yolo_camera_scan_hub.jpg" width="200"/> | <img src="assets/Git-hub-images/07_yolo_camera_live_apple_viewfinder.jpg" width="200"/> | <img src="assets/Git-hub-images/07_yolo_detected_apple_modal.jpg" width="200"/> | <img src="assets/Git-hub-images/07_yolo_detected_chicken_breast.jpg" width="200"/> | <img src="assets/Git-hub-images/07_yolo_log_scanned_meal_bottom_sheet.jpg" width="200"/> |

| Logging Options | Daily Food Diary | Day Overview | Macro Donut | Food Detail: Boiled Egg |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/06_foodlog_mode_selection.jpg" width="200"/> | <img src="assets/Git-hub-images/06_foodlog_itemized_day_diary.jpg" width="200"/> | <img src="assets/Git-hub-images/06_foodlog_all_meals_day_totals.jpg" width="200"/> | <img src="assets/Git-hub-images/06_foodlog_all_meals_macro_summary.jpg" width="200"/> | <img src="assets/Git-hub-images/06_foodlog_item_boiled_egg_nutrition.jpg" width="200"/> |

| Food Detail: Chicken Karahi | Lunch Confirmation | Dinner Confirmation | Quick Actions Menu |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/06_foodlog_item_chicken_karahi_nutrition.jpg" width="220"/> | <img src="assets/Git-hub-images/06_foodlog_logged_apple_lunch.jpg" width="220"/> | <img src="assets/Git-hub-images/06_foodlog_logged_chicken_karahi_dinner.jpg" width="220"/> | <img src="assets/Git-hub-images/06_foodlog_quick_actions_menu.jpg" width="220"/> |

---

### 4. Gut Shield & Medical Safety (Doctor PDF Report)
When digestive discomfort is detected, Gut Shield protects the user and creates a printable report for their doctor.

| Symptom Detection | Dashboard Protection Banner | Clinical Notes | Food Triggers Table | Doctor Report PDF (Printable) |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/04_gut_shield_nutribot_activation.jpg" width="200"/> | <img src="assets/Git-hub-images/03_dashboard_gut_shield_active_banner.jpg" width="200"/> | <img src="assets/Git-hub-images/04_clinical_doctor_brief_scribe.jpg" width="200"/> | <img src="assets/Git-hub-images/04_clinical_doctor_intake_triggers_table.jpg" width="200"/> | <img src="assets/Git-hub-images/04_clinical_doctor_report_pdf_export.jpg" width="200"/> |

---

### 5. Profile, Health Goals & Settings ("Me" Section)
A complete personal health profile for managing long-term progress, connected devices, and customized targets.

| Profile Overview | Choose Diet Type | Plan Overview | Weight & Calories Target | Custom Macros |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/13_me_profile_details.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_diet_type_picker.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_plan_overview.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_weight_calories_goal.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_macronutrients_breakdown.jpg" width="200"/> |

| Popular Nutrients | Micronutrients Tab | Exercise Plan | Health Catalog | Connected Devices |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/13_me_popular_nutrients.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_micronutrients_tab.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_exercise_plan.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_health_catalog.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_apps_and_devices.jpg" width="200"/> |

| Progress Photos | Connect with Doctor | App Settings | Refer a Friend | Help & FAQs |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/13_me_progress_photos.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_professional_connect.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_app_settings.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_refer_friend.jpg" width="200"/> | <img src="assets/Git-hub-images/13_me_support_faq.jpg" width="200"/> |

---

### 6. Wear OS Smartwatch Companion App
A dedicated Wear OS client built for round smartwatches so users can log food and check calories on the go.

| Watch Sign In | Calorie Ring | Macro Progress Bars | Breakfast List | Logged Items |
|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/10_smartwatch_login_welcome.jpg" width="180"/> | <img src="assets/Git-hub-images/10_smartwatch_calorie_ring_gauge.jpg" width="180"/> | <img src="assets/Git-hub-images/10_smartwatch_macro_bars_progress.jpg" width="180"/> | <img src="assets/Git-hub-images/10_smartwatch_breakfast_items_list.jpg" width="180"/> | <img src="assets/Git-hub-images/10_smartwatch_breakfast_logged_items.jpg" width="180"/> |

| Egg & Juice Meal | Watch Food Search | Portion Stepper (+ / -) | Add Food to Meal |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/10_smartwatch_breakfast_egg_juice.jpg" width="200"/> | <img src="assets/Git-hub-images/10_smartwatch_lunch_search_add.jpg" width="200"/> | <img src="assets/Git-hub-images/10_smartwatch_portion_stepper_fishburger.jpg" width="200"/> | <img src="assets/Git-hub-images/10_smartwatch_add_food_almonds.jpg" width="200"/> |

---

### 7. Nutrition Analytics & Progress Reports
Visual reports that show calorie deficits, weight journey forecasts, and nutrient balance.

| Deficit Flask Indicator | Weight Forecast Curve | Top Calorie Contributor | Meals Breakdown | Macro Pie Chart | Food Quality Grades |
|:---:|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/08_analytics_daily_deficit_flask.jpg" width="180"/> | <img src="assets/Git-hub-images/08_analytics_weight_journey_forecast.jpg" width="180"/> | <img src="assets/Git-hub-images/08_analytics_calories_top_contributor.jpg" width="180"/> | <img src="assets/Git-hub-images/08_analytics_meal_breakdown_bars.jpg" width="180"/> | <img src="assets/Git-hub-images/08_analytics_macro_insights_pie.jpg" width="180"/> | <img src="assets/Git-hub-images/08_analytics_food_quality_grades.jpg" width="180"/> |

---

### 8. NutriBot Assistant & Reminders
A conversational AI assistant that understands what the user has eaten today and gives practical advice.

| NutriBot Chat | Daily Food Summary | Hydration Reminders | Social Links |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/05_nutribot_chat_main.jpg" width="220"/> | <img src="assets/Git-hub-images/05_nutribot_daily_intake_breakdown.jpg" width="220"/> | <img src="assets/Git-hub-images/05_alerts_hydration_push_notifications.jpg" width="220"/> | <img src="assets/Git-hub-images/13_me_connect_social.jpg" width="220"/> |

---

### 9. Hydration & Workout Tracking
Keep track of daily water intake and burned calories from workouts.

| Water Tracker (Empty) | Log Water Slider | Water Goal Reached | Find a Workout | Workout Catalog | Log Exercise |
|:---:|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/09_water_tracker_empty_glass.jpg" width="180"/> | <img src="assets/Git-hub-images/09_water_tracker_slider_modal.jpg" width="180"/> | <img src="assets/Git-hub-images/09_water_tracker_filled_glass.jpg" width="180"/> | <img src="assets/Git-hub-images/09_activity_log_empty_search.jpg" width="180"/> | <img src="assets/Git-hub-images/09_activity_catalog_workout_grid.jpg" width="180"/> | <img src="assets/Git-hub-images/09_activity_exercise_entry_form.jpg" width="180"/> |

---

### 10. Subscriptions & Stripe Payments
Real in-app payment sheet powered by Stripe with support for multiple payment methods.

| Premium Upgrade Screen | Features Paywall Modal | Stripe Payment Sheet | Add Card Form |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/11_subscription_unlock_premium_hero.jpg" width="220"/> | <img src="assets/Git-hub-images/11_subscription_premium_paywall_modal.jpg" width="220"/> | <img src="assets/Git-hub-images/11_stripe_payment_sheet_methods.jpg" width="220"/> | <img src="assets/Git-hub-images/11_stripe_payment_sheet_card_form.jpg" width="220"/> |

---

### 11. Multi-Language Support (7 Languages & RTL)
Full localization across 7 languages, including native Right-to-Left (RTL) mirroring for Arabic.

| Arabic (RTL) Dashboard | Language Selection (7 Languages) | Side Menu Drawer | Profile Tab |
|:---:|:---:|:---:|:---:|
| <img src="assets/Git-hub-images/03_dashboard_arabic_rtl_localization.jpg" width="220"/> | <img src="assets/Git-hub-images/12_settings_language_selector_7lang.jpg" width="220"/> | <img src="assets/Git-hub-images/03_dashboard_nav_drawer.jpg" width="220"/> | <img src="assets/Git-hub-images/03_dashboard_profile_me_tab.jpg" width="220"/> |

---

## 🛠 Tech Stack & Architecture

| Area | Technologies Used |
|:---|:---|
| **Frontend Framework** | **Flutter** (Dart 3.x) for Android, iOS, and Wear OS |
| **Backend & Cloud** | **Firebase** (Firebase Authentication, Cloud Firestore, Firebase Storage) |
| **Computer Vision** | **YOLOv8** running on-device via TensorFlow Lite (TFLite) |
| **Recommendation Engine** | **K-Nearest Neighbors (KNN)** multi-diet optimization across curated datasets |
| **Conversational AI** | **OpenAI GPT-4o API** with user profile & daily food log memory |
| **Payments & Monetization** | **Stripe SDK** (`flutter_stripe`) with Payment Sheet integration |
| **Medical Report PDF** | `pdf` and `printing` packages generating ISO A4 doctor briefs on device |
| **Smartwatch** | Standalone circular **Wear OS** client syncing with Firebase |
| **Internationalization** | Easy Localization supporting **English, Urdu, Arabic, Spanish, French, German, Italian** |

---

## 📁 Project Structure

```text
nutriapp/
├── assets/
│   ├── Git-hub-images/          # Demo video & 87 production screenshots
│   │   ├── app_demo_walkthrough.mp4
│   │   └── ...
│   ├── data/                    # Curated meal plan catalogs
│   │   ├── balanced_diet.csv
│   │   ├── fyp_keto_meal_plan.csv
│   │   ├── fyp_mediterranean_meal_plan.csv
│   │   └── fyp_dash_meal_plan.csv
│   ├── models/                  # YOLO TFLite model weights & label map
│   └── translations/            # 7 language JSON files (en, ur, ar, es, fr, de, it)
├── lib/
│   ├── authentication/          # User login, registration, and onboarding logic
│   ├── chatbot/                 # NutriBot AI assistant & symptom triage service
│   ├── dashboard/               # Daily calories, meal cards, Gut Shield banner
│   ├── doctor_summary/          # Medical summary screen & PDF generation service
│   ├── meal_planner/            # KNN recommendation algorithm & diet datasets
│   ├── meal_log/                # Food diary, camera YOLO scanner, calorie analysis
│   ├── me/                      # User profile, body logs, progress photos, devices
│   ├── smart-watch/             # Wear OS companion app screens and watch sync
│   ├── subscription/            # Stripe payment flow & premium paywalls
│   └── main.dart                # App entry point
└── pubspec.yaml                 # Dependencies and asset declarations
```

---

## 🚀 How to Run Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (`>= 3.3.0`)
- Android Studio or VS Code with Flutter and Dart extensions
- Connected Android smartphone or Android emulator

### 1. Clone the Repository
```bash
git clone https://github.com/alisami200092/NutriAI.git
cd NutriAI
```

### 2. Install Packages
```bash
flutter pub get
```

### 3. Add API Keys
Create a file at `assets/api-key.env` based on `assets/api-key.env.example`:
```env
OPENAI_API_KEY=your_openai_api_key_here
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
STRIPE_SECRET_KEY=your_stripe_secret_key_here
STRIPE_BACKEND_URL=your_backend_url_here
```

### 4. Run the App
```bash
# Run on phone or emulator
flutter run

# Run on Wear OS smartwatch
flutter run -d <wear-os-device-id>
```

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
