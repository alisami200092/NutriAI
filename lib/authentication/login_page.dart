import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutriapp/dashboard/bottom_nav.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import '../screens/gender_selection.dart';

class LoginPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const LoginPage({super.key, required this.cameras, required this.yolo});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _obscurePassword = true;

  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  late AnimationController _buttonController;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    // Card animation
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);

    // Button animation (slide in from left)
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
        );

    _cardController.forward().then((_) => _buttonController.forward());
  }

  @override
  void dispose() {
    _cardController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!mounted) return; // guard before setState
    setState(() => _loading = true);

    try {
      // Auth call
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return; // guard before context use

      final uid = _auth.currentUser!.uid;

      // Firestore fetch
      final userDoc = await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(uid)
          .get();

      if (!mounted) return;

      final bool completed = userDoc.exists
          ? (userDoc.data()?['profileCompleted'] ?? false)
          : false;

      // SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profileCompleted', completed);

      if (!mounted) return;

      // Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => completed
              ? BottomNav(cameras: widget.cameras, yolo: widget.yolo)
              : const GenderSelectionScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
      }
    } finally {
      // ✅ no return here, just guard setState
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background-login2.jpg', // your background image
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay for contrast
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: SizedBox(
                        width: size.width * 0.88,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Card
                            SlideTransition(
                              position: _cardSlide,
                              child: FadeTransition(
                                opacity: _cardFade,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 80,
                                      ), // space for logo overlap
                                      TextField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: "Email",
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFF388E3C),
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black54,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: "Password",
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF388E3C),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          floatingLabelStyle: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black54,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Animated Login Button (pill shape)
                                      SlideTransition(
                                        position: _buttonSlide,
                                        child: _loading
                                            ? const CircularProgressIndicator()
                                            : SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF388E3C),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: _login,
                                                  child: const Text("Login"),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Logo positioned above card (ignore pointer to fix tap bug)
                            Positioned(
                              top: -80, // adjust overlap distance
                              left: 0,
                              right: 0,
                              child: Center(
                                child: IgnorePointer(
                                  child: Image.asset(
                                    'assets/images/nutri-ai.png', // your logo
                                    height: 300,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Forgot password (outside card)
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot your password?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Don't have account? Sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SignupPage(
                                  cameras: widget.cameras,
                                  yolo: widget.yolo,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Color(0xFFF4AF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.white70,
                            indent: 30,
                            endIndent: 10,
                          ),
                        ),
                        Text(
                          "Login With",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.white70,
                            indent: 10,
                            endIndent: 30,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Social login buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Facebook
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              image: DecorationImage(
                                image: AssetImage('assets/images/fb-logo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Google
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              image: DecorationImage(
                                image: AssetImage(
                                  'assets/images/google-logo.png',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
