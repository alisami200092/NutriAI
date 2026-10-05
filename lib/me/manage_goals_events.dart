import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. MANAGE WEIGHT, GOALS & LIFESTYLE PAGE
// ==========================================
class ManageWeightPage extends StatefulWidget {
  final double currentWeight;
  final double targetWeight;
  final double weightChangePerWeek;
  final String activityLevel;

  const ManageWeightPage({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.weightChangePerWeek,
    this.activityLevel = "Moderately Active", // Default fallback
  });

  @override
  State<ManageWeightPage> createState() => _ManageWeightPageState();
}

class _ManageWeightPageState extends State<ManageWeightPage> {
  late TextEditingController _currentController;
  late TextEditingController _targetController;

  late double _selectedWeightChange;
  late String _selectedActivityLevel;

  bool _isSaving = false;
  final Color _tealColor = const Color(0xFF4DB6AC);

  // Options for dropdowns
  final List<String> _activityLevels = [
    "Sedentary",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
    "Extra Active",
  ];

  final List<double> _weightChangeOptions = [0.25, 0.5, 0.75, 1.0];

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController(
      text: widget.currentWeight.toString(),
    );
    _targetController = TextEditingController(
      text: widget.targetWeight.toString(),
    );

    // Ensure the passed values exist in our dropdown lists, otherwise use a default
    _selectedActivityLevel = _activityLevels.contains(widget.activityLevel)
        ? widget.activityLevel
        : "Moderately Active";

    _selectedWeightChange =
        _weightChangeOptions.contains(widget.weightChangePerWeek)
        ? widget.weightChangePerWeek
        : 0.5;
  }

  Future<void> _saveWeightData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      double newCurrent =
          double.tryParse(_currentController.text) ?? widget.currentWeight;
      double newTarget =
          double.tryParse(_targetController.text) ?? widget.targetWeight;

      // 1. Update Main Profile in Firestore
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .update({
            'weight': newCurrent,
            'targetWeight': newTarget,
            'weightChangePerWeek': _selectedWeightChange,
            'activityLevel': _selectedActivityLevel,
            'lastWeightUpdate': FieldValue.serverTimestamp(),
          });

      // 2. Add to History Log (Sub-collection)
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .collection('WeightLogs')
          .add({'weight': newCurrent, 'date': FieldValue.serverTimestamp()});

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Goals & Lifestyle",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        // Added to prevent overflow with new fields
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CURRENT WEIGHT ---
                  const Text(
                    "Current Weight (kg)",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextField(
                    controller: _currentController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: "kg",
                    ),
                  ),
                  const Divider(),

                  // --- TARGET WEIGHT ---
                  const Text(
                    "Target Weight (kg)",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: "kg",
                    ),
                  ),
                  const Divider(height: 30),

                  // --- ACTIVITY LEVEL ---
                  const Text(
                    "Activity Level",
                    style: TextStyle(color: Colors.grey),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedActivityLevel,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _activityLevels.map((String level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedActivityLevel = newValue);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 30),

                  // --- WEIGHT CHANGE PER WEEK ---
                  const Text(
                    "Goal Rate (Weight Change/Week)",
                    style: TextStyle(color: Colors.grey),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      isExpanded: true,
                      value: _selectedWeightChange,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _weightChangeOptions.map((double rate) {
                        return DropdownMenuItem<double>(
                          value: rate,
                          child: Text("$rate kg per week"),
                        );
                      }).toList(),
                      onChanged: (double? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedWeightChange = newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWeightData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tealColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Entry",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. EDIT EVENT PAGE (Kept intact from your original code)
// ==========================================
class EditEventPage extends StatefulWidget {
  final String currentName;
  final DateTime? currentDate;

  const EditEventPage({
    super.key,
    required this.currentName,
    required this.currentDate,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late String _selectedEvent;
  late TextEditingController _customNameController;
  DateTime? _selectedDate;
  bool _isSaving = false;
  final Color _tealColor = const Color(0xFF4DB6AC);

  final List<Map<String, String>> eventOptions = const [
    {'emoji': '🏝️', 'label': 'Vacation'},
    {'emoji': '💍', 'label': 'Wedding'},
    {'emoji': '🏅', 'label': 'Competition'},
    {'emoji': '🧑‍🤝‍🧑', 'label': 'Reunion'},
    {'emoji': '🎂', 'label': 'Birthday'},
    {'emoji': '🗓️', 'label': 'Other Event'},
    {'emoji': '❌', 'label': 'No'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.currentDate ?? DateTime.now().add(const Duration(days: 30));
    _customNameController = TextEditingController();

    final bool matchesOption = eventOptions.any((opt) => opt['label'] == widget.currentName);
    if (matchesOption) {
      _selectedEvent = widget.currentName;
    } else if (widget.currentName.isNotEmpty && widget.currentName != "My Goal") {
      _selectedEvent = "Other Event";
      _customNameController.text = widget.currentName;
    } else {
      _selectedEvent = "Vacation";
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _tealColor,
            colorScheme: ColorScheme.light(primary: _tealColor),
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
  }

  Future<void> _saveEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);

    String finalEventName = _selectedEvent;
    if (_selectedEvent == "Other Event") {
      final custom = _customNameController.text.trim();
      finalEventName = custom.isNotEmpty ? custom : "Special Event";
    } else if (_selectedEvent == "No") {
      finalEventName = "Personal Fitness";
    }

    try {
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user.uid)
          .update({
            'eventName': finalEventName,
            'eventDate': Timestamp.fromDate(_selectedDate!),
          });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Edit Goal Event", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Selection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Your Motivating Event",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Choose an event that inspires your fitness progress:",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: eventOptions.map((opt) {
                      final bool isSelected = _selectedEvent == opt['label'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEvent = opt['label']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _tealColor.withValues(alpha: 0.12) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _tealColor : Colors.transparent,
                              width: 1.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(opt['emoji']!, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                opt['label']!,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? _tealColor : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedEvent == "Other Event") ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customNameController,
                      decoration: InputDecoration(
                        labelText: "Custom Event Name",
                        hintText: "e.g. Marathon, Graduation, Family Trip",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _tealColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Event Date Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Target Event Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "When does this event take place or when do you plan to reach your goal?",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: _tealColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Change",
                            style: TextStyle(
                              color: _tealColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tealColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Update Event",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
