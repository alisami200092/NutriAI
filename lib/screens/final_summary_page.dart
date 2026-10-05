import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutriapp/testing/offline_testing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinalSummaryPage extends StatefulWidget {
  final String name;
  final int age;
  final double heightCm;
  final String gender;
  final double weight;
  final double targetWeight;
  final String dietaryGoal;
  final String eventName;
  final DateTime eventDate;
  final String activityLevel;
  final double weightChangePerWeek;
  final String restrictions;
  final String dietType;
  final String healthConditions;

  const FinalSummaryPage({
    super.key,
    required this.name,
    required this.age,
    required this.heightCm,
    required this.gender,
    required this.weight,
    required this.targetWeight,
    required this.dietaryGoal,
    required this.eventName,
    required this.eventDate,
    required this.activityLevel,
    required this.weightChangePerWeek,
    required this.restrictions,
    required this.dietType,
    required this.healthConditions,
  });

  @override
  State<FinalSummaryPage> createState() => _FinalSummaryPageState();
}

class _FinalSummaryPageState extends State<FinalSummaryPage>
    with TickerProviderStateMixin {
  late List<_SummaryItem> summaryData;
  late List<AnimationController> rowControllers;
  late List<Animation<double>> rowOpacities;
  late List<bool> showContent;

  bool _isDisposed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final formattedDate =
        "${widget.eventDate.day} ${_monthName(widget.eventDate.month)} ${widget.eventDate.year}";

    summaryData = [
      _SummaryItem("Gender", widget.gender, "assets/images/gender_symbol.png"),
      _SummaryItem(
        "Height",
        "${widget.heightCm.toStringAsFixed(1)} cm",
        "assets/images/height_symbol.jpg",
      ),
      _SummaryItem("Age", "${widget.age}", "assets/images/age.png"),
      _SummaryItem(
        "Weight",
        "${widget.weight.toStringAsFixed(1)} kg",
        "assets/images/weight.png",
      ),
      _SummaryItem("Goal", widget.dietaryGoal, "assets/images/goals.png"),
      _SummaryItem(
        "Target Weight",
        "${widget.targetWeight.toStringAsFixed(1)} kg",
        "assets/images/target_weight.png",
      ),
      _SummaryItem(
        "Event",
        "🏅 ${widget.eventName} ",
        "assets/images/event_symbol.png",
      ),
      _SummaryItem("Event Date", formattedDate, "assets/images/event_date.png"),
      _SummaryItem(
        "Activity Level",
        widget.activityLevel,
        "assets/images/activity_level_symbol.png",
      ),
      _SummaryItem(
        "${widget.dietaryGoal.toLowerCase().contains('loss') ? 'Weight Loss' : 'Weight Gain'} Speed",
        "${widget.weightChangePerWeek.toStringAsFixed(1)} kg/week",
        "assets/images/weight-goal-track.png",
      ),
      _SummaryItem(
        "Restrictions",
        widget.restrictions.isEmpty ? "None" : widget.restrictions,
        "assets/images/dietary_restrictions.png",
      ),
      _SummaryItem(
        "Diet",
        widget.dietType,
        "assets/images/diet-preference.png",
      ),
      _SummaryItem(
        "Health Conditions",
        widget.healthConditions.isEmpty ? "None" : widget.healthConditions,
        "assets/images/heart-beat.png",
      ),
    ];

    rowControllers = [];
    rowOpacities = [];
    showContent = List<bool>.filled(summaryData.length, false);

    for (int i = 0; i < summaryData.length; i++) {
      final rc = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );

      rc.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && !_isDisposed) {
          setState(() {});
        }
      });

      rowControllers.add(rc);
      rowOpacities.add(CurvedAnimation(parent: rc, curve: Curves.easeIn));
    }

    _startSequence();
  }

  double get overallProgress {
    final completed = rowControllers
        .where((c) => c.status == AnimationStatus.completed)
        .length;
    if (summaryData.isEmpty) return 0;
    return completed / summaryData.length;
  }

  void _startSequence() async {
    for (int i = 0; i < summaryData.length; i++) {
      if (!mounted || _isDisposed) return;

      setState(() {
        showContent[i] = false;
      });

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || _isDisposed) return;

      setState(() {
        showContent[i] = true;
      });

      if (i < rowControllers.length) {
        rowControllers[i].forward();
      }

      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted || _isDisposed) return;
    }
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  Future<void> saveUserProfileToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final payload = {
      "name": widget.name,
      "age": widget.age,
      "height": widget.heightCm,
      "gender": widget.gender,
      "weight": widget.weight,
      "targetWeight": widget.targetWeight,
      "dietaryGoal": widget.dietaryGoal,
      "eventName": widget.eventName,
      "eventDate": widget.eventDate,
      "activityLevel": widget.activityLevel,
      "weightChangePerWeek": widget.weightChangePerWeek,
      "restrictions": widget.restrictions,
      "dietType": widget.dietType,
      "healthConditions": widget.healthConditions,
      "healthSeverity": "Mild",
      "profileCompleted": true,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('UserProfiles')
        .doc(uid)
        .set(payload, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileCompleted', true);
  }

  Widget _buildSummaryRow(_SummaryItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showContent[index]
                    ? FadeTransition(
                        opacity: rowOpacities[index],
                        child: Image.asset(
                          item.iconPath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.help_outline, size: 22),
                        ),
                      )
                    : const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FadeTransition(
              opacity: rowOpacities[index],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check, color: Colors.green, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomProgress() {
    final pct = (overallProgress * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$pct%",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: _isSaving
            ? null
            : () async {
                setState(() => _isSaving = true);
                try {
                  await saveUserProfileToFirestore();
                  if (!mounted) return;

                  // --- 👇 TEMPORARILY COMMENTED OUT DASHBOARD NAVIGATION 👇 ---
                  // Navigator.pushReplacementNamed(context, "/main");

                  // --- 👇 OLD FLASK TESTING PAGE (Keep for future) 👇 ---
                  /*
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestingPage(
                        age: widget.age,
                        height: widget.heightCm,
                        weight: widget.weight,
                        weightChangePerWeek: widget.weightChangePerWeek,
                        gender: widget.gender,
                        activityLevel: widget.activityLevel,
                        goal: widget.dietaryGoal,
                        dietType: widget.dietType,
                        healthConditions: widget.healthConditions,
                        restrictions: widget.restrictions,
                      ),
                    ),
                  );
                  */

                  // --- 👇 NEW OFFLINE TFLITE TESTING PAGE 👇 ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OfflineTestingPage(
                        age: widget.age,
                        height: widget.heightCm,
                        weight: widget.weight,
                        weightChangePerWeek: widget.weightChangePerWeek,
                        gender: widget.gender,
                        activityLevel: widget.activityLevel,
                        goal: widget.dietaryGoal,
                        dietType: widget.dietType,
                        healthConditions: widget.healthConditions,
                        restrictions: widget.restrictions,
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to save profile: $e"),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_forward_ios),
        label: Text(_isSaving ? "Saving..." : "Continue to Prediction"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final rc in rowControllers) {
      rc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Lottie.asset(
              "assets/animations/robot-working.json",
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: summaryData.length,
                itemBuilder: (context, index) =>
                    _buildSummaryRow(summaryData[index], index),
              ),
            ),
            _buildBottomProgress(),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final String iconPath;
  _SummaryItem(this.label, this.value, this.iconPath);
}
