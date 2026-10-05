import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/activity/activity_catalogue_page.dart';
import 'activity_search_page.dart';
import 'exercise_entry_page.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  String _getDateText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      return "Today".tr();
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return "Yesterday".tr();
    } else if (selected == today.add(const Duration(days: 1))) {
      return "Tomorrow".tr();
    } else {
      return DateFormat('EEE, d MMM').format(_selectedDate);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteLog(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ActivityLog')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Entry deleted".tr()),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  // --- DIALOG LOGIC ---
  void _showOptionsDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${"Manage".tr()} ${data['exerciseName']}"),
        content: Text("What would you like to do with this entry?".tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteLog(docId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Delete".tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              int duration = data['durationMinutes'] ?? 1;
              int cals = data['caloriesBurned'] ?? 0;
              int calcRate = (duration > 0) ? (cals / duration).round() : 5;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseEntryPage(
                    exerciseName: data['exerciseName'] ?? "Exercise",
                    emoji: data['emoji'] ?? "🏃‍♂️",
                    baseCaloriesPerMinute: calcRate,
                    existingDocId: docId,
                    initialDuration: duration,
                    initialNotes: data['notes'],
                    initialDate: (data['date'] as Timestamp).toDate(),
                  ),
                ),
              );
            },
            child: Text(
              "Edit".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. GET USER ID INSIDE BUILD (Fixes the Empty State issue)
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // If no user logged in, show simple message or empty state
    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Please log in to view your workout.".tr())),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        // 2. USE THE FRESH USER ID
        stream: FirebaseFirestore.instance
            .collection('ActivityLog')
            .where('userId', isEqualTo: userId) // <--- Fixed here
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF37C97D)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final dailyExercises = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] != null) {
              DateTime docDate = (data['date'] as Timestamp).toDate();
              return _isSameDay(docDate, _selectedDate);
            }
            return false;
          }).toList();

          final bool hasLogs = dailyExercises.isNotEmpty;

          return Column(
            children: [
              _buildCustomHeader(showSearch: hasLogs),
              Expanded(
                child: hasLogs
                    ? _buildPopulatedState(dailyExercises)
                    : _buildEmptyState(),
              ),
            ],
          );
        },
      ),

      // FAB STREAM (Also Updated)
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ActivityLog')
            .where('userId', isEqualTo: userId) // <--- Fixed here
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final dailyExercises = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] != null) {
              return _isSameDay(
                (data['date'] as Timestamp).toDate(),
                _selectedDate,
              );
            }
            return false;
          }).toList();

          if (dailyExercises.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivitySearchPage(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF64B5F6),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ... (Keep ALL your existing widget methods below: _buildPopulatedState, _buildEmptyState, etc.)
  // ... Paste the rest of your UI code here exactly as it was ...

  Widget _buildPopulatedState(List<QueryDocumentSnapshot> exercises) {
    int dailyTotalCals = 0;
    for (var doc in exercises) {
      final data = doc.data() as Map<String, dynamic>;
      dailyTotalCals += (data['caloriesBurned'] as num? ?? 0).toInt();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Claim your FREE trial".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "Unlock all Premium features".tr(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTextLink("Find and Log Exercise".tr(), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivitySearchPage(),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _buildTextLink("Select Custom Exercise".tr(), () {}),
                const SizedBox(height: 12),
                _buildTextLink(
                  "Copy Last Day's Exercise ($dailyTotalCals cals)",
                  () {},
                ),
              ],
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final doc = exercises[index];
              final data = doc.data() as Map<String, dynamic>;

              final String emoji = data['emoji'] ?? "🏃‍♂️";
              final String name = data['exerciseName'] ?? "Exercise";
              final int duration = data['durationMinutes'] ?? 0;
              final int cals = data['caloriesBurned'] ?? 0;

              return InkWell(
                onTap: () => _showOptionsDialog(context, doc.id, data),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "$duration ${"min".tr()}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$cals",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37C97D),
                            ),
                          ),
                          Text(
                            "cals".tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF37C97D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTextLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2196F3),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "FIND YOUR WORKOUT".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B3A33),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),

            _buildGradientButton(
              text: "Search For Exercise".tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivitySearchPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),
            Text(
              "or".tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 25),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseListPage(),
                  ),
                );
              },
              child: Text(
                "Browse All Exercises".tr(),
                style: const TextStyle(
                  color: Color(0xFF1B3A33),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader({bool showSearch = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 10,
        right: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF37C97D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Activity Log".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (showSearch)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivitySearchPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, color: Colors.white, size: 26),
                ),
            ],
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDateText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5AB678).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF88C96C), Color(0xFF4FA87F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
