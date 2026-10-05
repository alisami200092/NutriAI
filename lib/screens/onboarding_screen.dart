import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final int _numPages = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // ✅ Prevent overflow on tall/narrow screens
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              children: [
                _buildPage(
                  title: "Welcome to NutriAi",
                  subtitle:
                      "Transform your health with smart nutrition planning! Get personalized meal recommendations tailored to your goals—whether it’s weight loss, muscle gain, or balanced eating.",
                  imagePath: "assets/images/onboarding_screen1.jpg",
                ),
                _buildPage(
                  title: "Your Personalized Nutrition Guide",
                  subtitle:
                      "Track your daily calories, essential nutrients, and meal plans—all customized to fit your health goals. Stay on top of your wellness journey with smart recommendations!",
                  imagePath: "assets/images/onboarding_screen2.jpg",
                ),
                _buildPage(
                  title: "Fuel Your Body with Smart Choices",
                  subtitle:
                      "Discover tailored meal plans packed with healthy, delicious ingredients. Let AI help you find the perfect balance for a stronger, healthier you!",
                  imagePath: "assets/images/onboarding_screen3.jpg",
                ),
              ],
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: _numPages,
                  effect: const ExpandingDotsEffect(
                    dotColor: Colors.white54,
                    activeDotColor: Colors.white,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24, // ✅ Lower margin to avoid overflow
              right: 24,
              child: InkWell(
                onTap: () {
                  if (_controller.page != null &&
                      _controller.page!.toInt() < (_numPages - 1)) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, "/login");
                  }
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: size.width,
            height: size.height,
            color: const Color.fromARGB(76, 0, 0, 0),
          ),
          Positioned(
            bottom: size.height * 0.2,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
