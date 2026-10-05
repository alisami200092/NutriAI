import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutriapp/smart-watch/authentication/auth_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _passObscure = true;
  bool _confirmObscure = true;
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (_passController.text.trim() != _confirmController.text.trim()) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'weak-password') {
        message = "Password is too weak";
      } else if (e.code == 'email-already-in-use') {
        message = "Email already used";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format";
      }

      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: WatchContainer(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                WatchTextField(hint: "@ Email", controller: _emailController),
                const SizedBox(height: 5),

                WatchTextField(
                  hint: "Password",
                  isPassword: true,
                  isObscure: _passObscure,
                  controller: _passController,
                  onToggleVisibility: () =>
                      setState(() => _passObscure = !_passObscure),
                ),
                const SizedBox(height: 5),

                WatchTextField(
                  hint: "Confirm Pass",
                  isPassword: true,
                  isObscure: _confirmObscure,
                  controller: _confirmController,
                  onToggleVisibility: () =>
                      setState(() => _confirmObscure = !_confirmObscure),
                ),
                const SizedBox(height: 10),

                _isLoading
                    ? const SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.cyanAccent,
                        ),
                      )
                    : WatchButton(text: "SIGN UP >", onPressed: _handleSignUp),

                const SizedBox(height: 5),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 120
                      : 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
