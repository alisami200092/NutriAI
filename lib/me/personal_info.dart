import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:nutriapp/me/app_settings.dart';
import 'package:nutriapp/me/manage_goals_events.dart';
import 'package:nutriapp/services/fat_calculator_service.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final Color _primaryColor = const Color(0xFF37C97D);
  final Color _tealColor = const Color(0xFF4DB6AC);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // --- State Variables ---
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- 1. Fetch Data ---
  Future<void> _fetchUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        if (mounted) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateField(String key, dynamic value) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(user!.uid)
          .update({key: value});

      if (mounted) {
        setState(() {
          if (userData != null) {
            userData![key] = value;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$key updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating $key: $e")),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: userData?['name'] ?? "");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Full Name"),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _tealColor),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _updateField('name', newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog() {
    final goals = ["Weight Loss", "Weight Gain", "Maintenance", "Healthy Living", "Muscle Building"];
    String selected = userData?['dietaryGoal'] ?? "Healthy Living";
    if (!goals.contains(selected)) {
      selected = "Healthy Living";
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("Select Dietary Goal"),
          content: DropdownButton<String>(
            isExpanded: true,
            value: selected,
            items: goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (val) {
              if (val != null) {
                setDlgState(() => selected = val);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _tealColor),
              onPressed: () {
                _updateField('dietaryGoal', selected);
                Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  void _showEditDetailsDialog() {
    final ageController = TextEditingController(text: "${userData?['age'] ?? 25}");
    final heightController = TextEditingController(text: "${(userData?['height'] ?? 170).toInt()}");
    String rawGender = (userData?['gender'] ?? "Male").toString().toLowerCase();
    String gender = "Male";
    if (rawGender.contains("fem")) {
      gender = "Female";
    } else if (rawGender.contains("oth")) {
      gender = "Other";
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Personal Details", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Gender"),
                value: gender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => gender = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age (years)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: "Height (cm)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final int? newAge = int.tryParse(ageController.text.trim());
                final double? newHeight = double.tryParse(heightController.text.trim());
                if (newAge != null && newHeight != null && user != null) {
                  await FirebaseFirestore.instance.collection('UserProfiles').doc(user!.uid).update({
                    'gender': gender,
                    'age': newAge,
                    'height': newHeight,
                  });
                  await _fetchUserData();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Image Picker ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // --- Helper: BMI Calculator ---
  double _calculateBMI() {
    if (userData == null) return 0.0;
    double heightCm = (userData!['height'] ?? 0).toDouble();
    double weightKg = (userData!['weight'] ?? 0).toDouble();
    if (heightCm == 0) return 0.0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String _getBMILabel(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange[700]!;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // 2. My Snapshot (BMI & Weight)
            _buildSnapshotCard(),
            const SizedBox(height: 16),

            // 3. Personal Details
            _buildPersonalDetailsCard(),
            const SizedBox(height: 16),

            // 4. Activity & Lifestyle
            _buildActivityLifestyleCard(),
            const SizedBox(height: 16),

            // 5. Upcoming Goal Event
            _buildUpcomingEventCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- 1. Profile Header ---
  Widget _buildProfileHeader() {
    String name = userData?['name'] ?? "User";
    String goal = userData?['dietaryGoal'] ?? "Healthy Living";

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _tealColor, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (userData?['photoUrl'] != null
                              ? NetworkImage(userData!['photoUrl'])
                              : const NetworkImage(
                                  'https://i.pravatar.cc/300?img=12',
                                ))
                          as ImageProvider,
              ),
            ),
            GestureDetector(
              onTap: _pickImage, // ACTIVATE IMAGE PICKER
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showEditNameDialog,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 16, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _showEditGoalDialog,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Goal: $goal",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 14, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Snapshot Card (Weight & BMI) ---
  // --- 2. Snapshot Card (Weight & BMI) ---
  Widget _buildSnapshotCard() {
    // 👇 Safely cast all numbers to double to avoid Firestore int/double TypeErrors
    double weight = (userData?['weight'] ?? 0).toDouble();
    double targetWeight = (userData?['targetWeight'] ?? 0).toDouble();
    double weightChangePerWeek = (userData?['weightChangePerWeek'] ?? 0.5)
        .toDouble();

    double bmi = _calculateBMI();
    String bmiLabel = _getBMILabel(bmi);
    Color bmiColor = _getBMIColor(bmi);

    return _buildCard(
      title: "My Snapshot",
      onEdit: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageWeightPage(
              currentWeight: weight,
              targetWeight: targetWeight,
              weightChangePerWeek: weightChangePerWeek,
              activityLevel:
                  userData?['activityLevel'] ?? "Moderately Active",
            ),
          ),
        );
        if (updated == true) _fetchUserData();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Weight Data
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      weight.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "kg",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  "Target: ${targetWeight.toStringAsFixed(1)} kg",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 10),
                // Custom Linear Progress
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      // Calculate width based on weight (just a visual approximation for UI)
                      Expanded(
                        flex: (weight > 200 ? 200 : weight).toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tealColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Spacer(flex: 200 - (weight > 200 ? 200 : weight).toInt()),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageWeightPage(
                          // 👇 FIX APPLIED HERE: Using the safely converted variables
                          currentWeight: weight,
                          targetWeight: targetWeight,
                          weightChangePerWeek: weightChangePerWeek,
                          activityLevel:
                              userData?['activityLevel'] ?? "Moderately Active",
                        ),
                      ),
                    );
                    if (updated == true) _fetchUserData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Manage Weight & Goals",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Right: BMI Gauge
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(
                  height: 80,
                  width: 100,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          size: const Size(100, 80),
                          painter: BMIGaugePainter(),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "BMI",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              bmi.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "- $bmiLabel",
                      style: TextStyle(
                        color: bmiColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.info_outline, size: 12, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Personal Details Card ---
  Widget _buildPersonalDetailsCard() {
    String gender = userData?['gender'] ?? "-";
    int age = userData?['age'] ?? 0;
    double height = (userData?['height'] ?? 0).toDouble();
    double weight = (userData?['weight'] ?? 0).toDouble();

    final double bodyFat = FatCalculatorService.calculateBodyFatPercentage(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: gender,
    );

    return _buildCard(
      title: "Personal Details",
      onEdit: _showEditDetailsDialog,
      child: Column(
        children: [
          _buildDetailRow(
            gender == "Male" ? Icons.male : Icons.female,
            "Gender: $gender",
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.cake_outlined, "Age: $age years old"),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.straighten,
            "Height: ${height.toStringAsFixed(0)} cm",
          ),
          if (bodyFat > 0) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.accessibility_new,
              "Estimated Body Fat: ${bodyFat.toStringAsFixed(1)}%",
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. Activity & Lifestyle Card ---
  Widget _buildActivityLifestyleCard() {
    String activity = userData?['activityLevel'] ?? "Sedentary";
    String diet = userData?['dietType'] ?? userData?['dietPreference'] ?? "Standard";
    dynamic rawRestrictions = userData?['restrictions'] ?? userData?['dietaryRestrictions'];
    double perWeek = (userData?['weightChangePerWeek'] ?? 0).toDouble();

    List<String> restrictionList = [];
    if (rawRestrictions is List) {
      restrictionList = rawRestrictions.map((e) => e.toString()).toList();
    } else if (rawRestrictions is String && rawRestrictions.isNotEmpty) {
      restrictionList = rawRestrictions.split(',').map((e) => e.trim()).toList();
    }
    if (restrictionList.isEmpty) restrictionList = ["None"];

    return _buildCard(
      title: "Activity & Lifestyle",
      onEdit: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageWeightPage(
              currentWeight: (userData?['weight'] ?? 75.0).toDouble(),
              targetWeight: (userData?['targetWeight'] ?? 75.0).toDouble(),
              weightChangePerWeek: perWeek,
              activityLevel: activity,
            ),
          ),
        );
        if (updated == true) _fetchUserData();
      },
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageWeightPage(
                    currentWeight: (userData?['weight'] ?? 75.0).toDouble(),
                    targetWeight: (userData?['targetWeight'] ?? 75.0).toDouble(),
                    weightChangePerWeek: perWeek,
                    activityLevel: activity,
                  ),
                ),
              );
              if (updated == true) _fetchUserData();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_run, color: _tealColor, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        "Activity Level",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        activity,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Goal: ${perWeek.toStringAsFixed(1)} kg / week",
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          // Diet Type - Editable
          InkWell(
            onTap: () => _showDietDialog(diet),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.eco_outlined, color: _tealColor, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    "Diet Type:",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(diet, style: const TextStyle(color: Colors.black54)),
                  ),
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Restrictions - Editable
          InkWell(
            onTap: () => _showRestrictionsDialog(restrictionList),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.no_food_outlined, color: _tealColor, size: 20),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      "Restrictions:",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: restrictionList
                          .map((tag) => _buildTag(tag))
                          .toList(),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDietDialog(String currentDiet) {
    final List<String> diets = [
      "Pakistani",
      "Indian",
      "High Protein",
      "Balanced",
      "Mediterranean",
      "Keto",
      "Vegetarian",
      "Vegan",
      "Low Carb",
      "Paleo",
    ];
    String selected = diets.contains(currentDiet) ? currentDiet : "Balanced";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Select Diet Type"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: diets
                  .map(
                    (d) => RadioListTile<String>(
                      title: Text(d),
                      value: d,
                      groupValue: selected,
                      activeColor: _primaryColor,
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selected = val);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('UserProfiles').doc(user.uid).update({
                    'dietPreference': selected,
                    'dietType': selected,
                  });
                  await _fetchUserData();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestrictionsDialog(List<String> currentList) {
    final List<String> available = [
      "Vegetarian",
      "Vegan",
      "Dairy-Free",
      "Gluten-Free",
      "Nut-Free",
      "Halal",
      "Kosher",
      "Low Sodium",
    ];

    List<String> selectedList = List<String>.from(
      currentList.where((e) => e.isNotEmpty && e.toLowerCase() != 'none'),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Dietary Restrictions"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((item) {
                final bool isSelected = selectedList.contains(item);
                return CheckboxListTile(
                  title: Text(item),
                  value: isSelected,
                  activeColor: _primaryColor,
                  onChanged: (bool? val) {
                    setDlgState(() {
                      if (val == true) {
                        if (!selectedList.contains(item)) selectedList.add(item);
                      } else {
                        selectedList.remove(item);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final String joined = selectedList.isEmpty ? "None" : selectedList.join(", ");
                  await FirebaseFirestore.instance.collection('UserProfiles').doc(user.uid).update({
                    'dietaryRestrictions': selectedList,
                    'restrictions': joined,
                  });
                  await _fetchUserData();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Upcoming Goal Event Card ---
  Widget _buildUpcomingEventCard() {
    String eventName = userData?['eventName'] ?? "My Goal";
    Timestamp? ts = userData?['eventDate'];
    DateTime? eventDate = ts?.toDate();

    String dateString = eventDate != null
        ? DateFormat('MMMM d, yyyy').format(eventDate)
        : "No date set";

    int daysLeft = eventDate != null
        ? eventDate.difference(DateTime.now()).inDays
        : 0;

    return _buildCard(
      title: "Upcoming Goal Event",
      onEdit: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditEventPage(
              currentName: userData?['eventName'] ?? "My Goal",
              currentDate: (userData?['eventDate'] as Timestamp?)?.toDate(),
            ),
          ),
        );
        if (updated == true) _fetchUserData();
      },
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventPage(
                    currentName: userData?['eventName'] ?? "My Goal",
                    currentDate: (userData?['eventDate'] as Timestamp?)?.toDate(),
                  ),
                ),
              );
              if (updated == true) _fetchUserData();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events_outlined, color: _tealColor, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Event Name:",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eventName,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    daysLeft > 0 ? "$daysLeft days to go!" : "Today!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: daysLeft > 0 ? Colors.black87 : _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventPage(
                    currentName: userData?['eventName'] ?? "My Goal",
                    currentDate: (userData?['eventDate'] as Timestamp?)?.toDate(),
                  ),
                ),
              );
              if (updated == true) _fetchUserData();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const SizedBox(width: 36),
                  const Text(
                    "Event Date:",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today_outlined, size: 14, color: _tealColor),
                  const SizedBox(width: 4),
                  Text(dateString, style: const TextStyle(color: Colors.black54)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventPage(
                      currentName: userData?['eventName'] ?? "My Goal",
                      currentDate: (userData?['eventDate'] as Timestamp?)
                          ?.toDate(),
                    ),
                  ),
                );
                if (updated == true) _fetchUserData();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _tealColor),
                foregroundColor: _tealColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Edit Event", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildCard({
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: _tealColor),
                        const SizedBox(width: 4),
                        Text(
                          "Edit",
                          style: TextStyle(
                            color: _tealColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _tealColor, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tealColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _tealColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// --- Custom Painter for BMI Gauge ---
class BMIGaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double arcVisualHeight = size.height * 0.75;
    final double ellipseTotalHeight = arcVisualHeight * 2;

    final Rect rect = Rect.fromLTWH(
      0,
      size.height - arcVisualHeight,
      size.width,
      ellipseTotalHeight,
    );

    const strokeWidth = 8.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw Background Arc (Grey)
    paint.color = Colors.grey.shade200;
    canvas.drawArc(rect, math.pi, math.pi, false, paint);
    paint.color = const Color(0xFF4DB6AC);
    canvas.drawArc(rect, math.pi, math.pi * 0.6, false, paint);

    // Orange for overweight portion
    paint.color = Colors.orangeAccent;
    canvas.drawArc(
      rect,
      math.pi + (math.pi * 0.6),
      math.pi * 0.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
