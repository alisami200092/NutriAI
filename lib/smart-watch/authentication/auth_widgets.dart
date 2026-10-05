import 'package:flutter/material.dart';

// --- The Neon Glowing Circle Container ---
class WatchContainer extends StatelessWidget {
  final Widget child;
  const WatchContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.95;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(
          // Uses standard opacity for compatibility
          color: Colors.cyanAccent.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// --- Custom Compact Text Field with Eye Icon ---
class WatchTextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final bool isObscure;
  final TextEditingController? controller;
  final VoidCallback? onToggleVisibility;

  const WatchTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.isObscure = false,
    this.controller,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height ensures the inputs look identical and fit the UI
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        textAlignVertical: TextAlignVertical.center,

        // --- STABLE CONFIGURATION ---
        // We use basic text types and disable smart features.
        // This ensures the text actually appears on the screen without freezing.
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : TextInputType.text,

        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none, // No auto-caps for email
        keyboardAppearance: Brightness.dark,

        // ----------------------------
        cursorColor: Colors.cyanAccent,
        style: const TextStyle(fontSize: 12, color: Colors.white),

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          // Clean padding so text is centered and not cut off
          contentPadding: const EdgeInsets.only(left: 10, right: 35),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.cyanAccent),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: Colors.cyanAccent,
                  ),
                  onPressed: onToggleVisibility,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// --- Gradient Button ---
class WatchButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const WatchButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.shade700, Colors.cyanAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
