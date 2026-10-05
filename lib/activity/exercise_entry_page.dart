import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ExerciseEntryPage extends StatefulWidget {
  final String exerciseName;
  final String emoji;
  final int baseCaloriesPerMinute;

  // NEW: Optional fields for Editing
  final String? existingDocId;
  final int? initialDuration;
  final String? initialNotes;
  final DateTime? initialDate;

  const ExerciseEntryPage({
    super.key,
    required this.exerciseName,
    required this.emoji,
    this.baseCaloriesPerMinute = 8,
    this.existingDocId,
    this.initialDuration,
    this.initialNotes,
    this.initialDate,
  });

  @override
  State<ExerciseEntryPage> createState() => _ExerciseEntryPageState();
}

class _ExerciseEntryPageState extends State<ExerciseEntryPage> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;

  bool _isLoading = false;
  final List<int> _quickMinutes = [30, 25, 20, 45, 36];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing, otherwise defaults
    _amountController = TextEditingController(
      text: widget.initialDuration?.toString() ?? "30",
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? "");
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _calculateCalories() {
    int mins = int.tryParse(_amountController.text) ?? 0;
    return mins * widget.baseCaloriesPerMinute;
  }

  // --- FIRESTORE LOGIC (CREATE OR UPDATE) ---
  Future<void> _saveExercise() async {
    // 1. Get Real User ID
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: No user logged in!".tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int duration = int.tryParse(_amountController.text) ?? 0;
      int totalCalories = _calculateCalories();

      // 2. Prepare Data
      final exerciseData = {
        'userId': currentUserId,
        'exerciseName': widget.exerciseName,
        'emoji': widget.emoji,
        'durationMinutes': duration,
        'caloriesBurned': totalCalories,
        'notes': _notesController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        // Only add 'createdAt' for new entries, don't overwrite on edit
        if (widget.existingDocId == null)
          'createdAt': FieldValue.serverTimestamp(),
      };

      // 3. Check if Editing or Creating
      if (widget.existingDocId != null) {
        // --- UPDATE EXISTING ENTRY ---
        await FirebaseFirestore.instance
            .collection('ActivityLog')
            .doc(widget.existingDocId)
            .update(exerciseData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entry Updated!"),
              backgroundColor: Colors.blue,
            ),
          );
          // Pop once to go back to Activity Log Page
          Navigator.pop(context);
        }
      } else {
        // --- CREATE NEW ENTRY ---
        await FirebaseFirestore.instance
            .collection('ActivityLog')
            .add(exerciseData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Exercise Logged Successfully!"),
              backgroundColor: Color(0xFF37C97D),
            ),
          );
          // Pop twice: Entry -> Search -> Log Page
          Navigator.pop(context);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalCalories = _calculateCalories();
    bool isEditing = widget.existingDocId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF37C97D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? "Edit Entry".tr() : "Exercise Entry".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      widget.exerciseName.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "$totalCalories",
                      style: const TextStyle(
                        fontSize: 28,
                        color: Color(0xFF37C97D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "cals".tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF37C97D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 2. Amount Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, color: Colors.black),
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: "Amount".tr(),
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF37C97D),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "min".tr(),
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickMinutes.map((mins) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _amountController.text = mins.toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$mins ${"min".tr()}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 25),

            // 4. Date Picker
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF37C97D),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF37C97D),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('d MMM').format(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF37C97D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 5. Notes Input
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: "Notes".tr(),
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF37C97D), width: 1.5),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // 6. Premium Ad
            Row(
              children: [
                const Text("🍏", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Track food & exercise time with NutriAI Premium".tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // 7. Save/Update Button
      floatingActionButton: SizedBox(
        width: 120,
        height: 50,
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _saveExercise,
          // Change color slightly if editing
          backgroundColor: isEditing ? Colors.blue : const Color(0xFF64B5F6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(isEditing ? Icons.save : Icons.check, color: Colors.white),
          label: Text(
            _isLoading ? "Saving...".tr() : (isEditing ? "Update".tr() : "Log".tr()),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
