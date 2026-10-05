# NutriAI 🥗🤖

An intelligent, AI-powered nutrition and meal tracking mobile application built with Flutter, Firebase, and OpenAI.

## Features
- **AI Meal & Calorie Tracking**: Log food via photo scanning (YOLO & ML models) or manual database search.
- **Multilingual Support**: Fully localized in 7 languages (English, Urdu, Arabic, Spanish, French, German, Italian).
- **Nutrition Analytics**: Deep macro and micronutrient breakdown, daily food reports, and volumetric calorie tracking.
- **Water & Activity Logs**: Track hydration and fitness activities synced with daily caloric burn.
- **AI Nutrition Assistant**: Interactive chatbot powered by OpenAI for personalized dietary advice.
- **Subscription & Premium**: Seamless payment processing via Stripe.

## Getting Started

### 1. Environment Setup
Create an environment file at `assets/api-key.env` using the provided template `assets/api-key.env.example`:

```env
OPENAI_API_KEY=your_openai_api_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_key_here
STRIPE_BACKEND_URL=your_backend_url_here
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```
