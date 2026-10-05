import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;
  const SignupPage({super.key, required this.cameras, required this.yolo});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _titleController;
  late Animation<Offset> _titleSlide;

  late AnimationController _fieldsController;
  late List<Animation<Offset>> _fieldSlides;
  late List<Animation<double>> _fieldFades;

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeOutBack),
        );

    _fieldsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fieldSlides = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.5;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fieldsController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _fieldFades = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.5;
      return CurvedAnimation(
        parent: _fieldsController,
        curve: Interval(start, end, curve: Curves.easeIn),
      );
    });

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonScale = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    );

    _titleController.forward().then((_) {
      _fieldsController.forward().then((_) {
        _buttonController.forward();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fieldsController.dispose();
    _buttonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final pwd = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (pwd != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _loading = true);
    try {
      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pwd,
      );
      final uid = userCredential.user!.uid;

      // Create (or overwrite) a single UserProfile doc keyed by UID
      await FirebaseFirestore.instance.collection('UserProfiles').doc(uid).set({
        'email': email,
        'profileCompleted': false, // questionnaire not done yet
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created! Please log in.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(cameras: widget.cameras, yolo: widget.yolo),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup failed")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF388E3C)),
      suffixIcon: suffixIcon,
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF388E3C),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background-login2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email
                    FadeTransition(
                      opacity: _fieldFades[0],
                      child: SlideTransition(
                        position: _fieldSlides[0],
                        child: TextField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            label: "Email",
                            icon: Icons.email_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    FadeTransition(
                      opacity: _fieldFades[1],
                      child: SlideTransition(
                        position: _fieldSlides[1],
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration(
                            label: "Password",
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    FadeTransition(
                      opacity: _fieldFades[2],
                      child: SlideTransition(
                        position: _fieldSlides[2],
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _inputDecoration(
                            label: "Confirm Password",
                            icon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    ScaleTransition(
                      scale: _buttonScale,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF388E3C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _signup,
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Login redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginPage(
                                  cameras: widget.cameras,
                                  yolo: widget.yolo,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFFF4AF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
