import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Ensure these files are in the same folder as this screen
import 'payment_service.dart';
import 'subscription_widgets.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // 0 = Monthly, 1 = Annual
  int _selectedPlanIndex = 1;
  bool _isLoading = false;

  final LinearGradient _glossyGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9DE088), Color(0xFF6EBC65), Color(0xFF53994B)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Handles the payment triggers using PaymentService
  Future<void> _handlePaymentTrigger() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get current user ID
      final user = FirebaseAuth.instance.currentUser;

      // Check if user is logged in
      if (user == null) {
        throw "User not logged in! Please sign in first.";
      }

      // Calculate amount: Monthly = 5999 cents, Annual = 2999 cents
      int amount = _selectedPlanIndex == 0 ? 5999 : 2999;

      // 2. Pass userId to the service
      await PaymentService.processPayment(
        amountInCents: amount,
        currency: 'usd',
        userId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Successful! Premium Unlocked."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        String message = e.toString();
        // Clean up error message for canceled payments
        if (message.contains("Payment Cancelled") ||
            message.contains("Canceled")) {
          message = "Payment was cancelled.";
        } else if (message.contains("User not logged in")) {
          message = "Please login to subscribe.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added AppBar to allow going back
      appBar: AppBar(
        backgroundColor: const Color(0xFFAFE6F1), // Matches gradient top
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, // Makes body go behind AppBar
      body: Stack(
        children: [
          // MAIN CONTENT
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFAFE6F1), Color(0xFF90DFAA)],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Logo & Header
                        Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: Image.asset(
                                'assets/images/n-logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Unlock Premium",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Achieve Your Health Goals",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 35),

                        // Features List
                        const FeatureRow(
                          icon: Icons.psychology,
                          text: "Advanced AI Features",
                        ),
                        const FeatureRow(
                          icon: Icons.restaurant_menu,
                          text: "Exclusive Recipes & Meal Plans",
                        ),
                        const FeatureRow(
                          icon: Icons.fitness_center,
                          text: "Personalized Fitness & Coaches",
                        ),
                        const FeatureRow(
                          icon: Icons.block,
                          text: "Ad-Free Experience",
                        ),

                        // Mini "Start Today" Button Row
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                "Plus Much More!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: _glossyGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handlePaymentTrigger,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    "Start Today",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black26,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Monthly Card
                        PricingCard(
                          title: "MONTHLY",
                          price: "\$59.99/month",
                          isSelected: _selectedPlanIndex == 0,
                          onTap: () => setState(() => _selectedPlanIndex = 0),
                          gradient: _glossyGradient,
                        ),

                        const SizedBox(height: 24),

                        // Annual Card
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            PricingCard(
                              title: "ANNUALLY",
                              price: "\$29.99/month",
                              subPrice: "(Save 60%)",
                              strikethrough: "\$59.99/month",
                              isSelected: _selectedPlanIndex == 1,
                              onTap: () =>
                                  setState(() => _selectedPlanIndex = 1),
                              gradient: _glossyGradient,
                            ),
                            const Positioned(
                              right: -5,
                              top: -35,
                              child: MedalBadge(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // MAIN ACTION BUTTON
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            gradient: _glossyGradient,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _handlePaymentTrigger,
                              borderRadius: BorderRadius.circular(30),
                              child: Center(
                                child: Text(
                                  _isLoading
                                      ? "PROCESSING..."
                                      : "START 7 DAY FREE TRIAL",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 20),
                            Text(
                              "Privacy Policy",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

typedef SubscriptionScreen = PremiumScreen;
