import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added Auth for UID

import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/meal_log/full_camera_screen.dart';

// Import all meal screens to navigate to them
import 'package:nutriapp/meal_log/breakfast_screen.dart';
import 'package:nutriapp/meal_log/lunch_screen.dart';
import 'package:nutriapp/meal_log/dinner_screen.dart';
import 'package:nutriapp/meal_log/snack_screen.dart';

final logger = Logger();

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;
  const CameraScreen({super.key, required this.cameras, required this.yolo});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _previewController;
  bool _isCameraInitialized = false;

  // UI State
  String _selectedMealType = 'lunch';
  bool _isLogging = false;

  // Data State
  String? _scannedLabel;
  Map<String, dynamic>? _scannedData;

  // Navigation State
  int _selectedIconIndex = 2;

  @override
  void initState() {
    super.initState();
    logger.i("CameraScreen: initState");
    WidgetsBinding.instance.addObserver(this);
    _initPreview();
  }

  @override
  void dispose() {
    logger.i("CameraScreen: dispose");
    WidgetsBinding.instance.removeObserver(this);
    _disposePreview(updateUI: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _previewController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposePreview();
    } else if (state == AppLifecycleState.resumed) {
      _initPreview();
    }
  }

  CameraDescription _pickInitialCamera(List<CameraDescription> cams) {
    final back = cams
        .where((c) => c.lensDirection == CameraLensDirection.back)
        .toList();
    return back.isNotEmpty ? back.first : cams.first;
  }

  Future<void> _initPreview() async {
    if (widget.cameras.isEmpty) {
      logger.w("No cameras available");
      return;
    }

    final cam = _pickInitialCamera(widget.cameras);

    final ctrl = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await ctrl.initialize();
      try {
        await ctrl.setFlashMode(FlashMode.off);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _previewController = ctrl;
        _isCameraInitialized = true;
      });
      logger.i("Camera Preview Initialized");
    } catch (e) {
      logger.e("Preview init failed: $e");
    }
  }

  Future<void> _disposePreview({bool updateUI = true}) async {
    if (_previewController != null) {
      final controller = _previewController;
      _previewController = null;

      if (updateUI && mounted) {
        setState(() => _isCameraInitialized = false);
      }

      try {
        await controller!.dispose();
      } catch (e) {
        logger.w("Error disposing preview: $e");
      }
    }
  }

  // --- NAVIGATION LOGIC ---
  Future<void> _openFullCamera() async {
    logger.i("Opening Full Camera...");
    setState(() {
      _selectedIconIndex = 2;
    });

    await _disposePreview();

    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FullCameraViewMin(cameras: widget.cameras, yolo: widget.yolo),
        fullscreenDialog: true,
      ),
    );

    if (mounted) await _initPreview();

    if (result != null && result is Map) {
      logger.i("Data received from Full Camera: $result");
      if (mounted) {
        setState(() {
          _scannedData = result as Map<String, dynamic>;
          _scannedLabel = result['name']?.toString();
        });
      }
    } else {
      logger.w("Full Camera returned NO data");
    }
  }

  void _onBottomIconTapped(int index) {
    logger.i("Bottom Icon Tapped: $index");
    setState(() {
      _selectedIconIndex = index;
    });
  }

  // --- ✅ FIX: UPDATED LOGGING LOGIC TO USE UID AND CORRECT MACROS ---
  Future<void> _confirmLog() async {
    logger.i(">>> _confirmLog Function Started <<<");

    if (_scannedData == null) {
      logger.w("Confirm pressed, but _scannedData is NULL.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No food scanned yet! Please scan an item first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLogging = true);

    try {
      // 1. Get UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("You must be logged in to save meals.");
      }
      final uid = user.uid;

      final now = DateTime.now();
      final dateKey =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final category = _selectedMealType.toLowerCase();

      logger.i("Logging Item: $_scannedLabel to $category for user $uid");

      // 2. Format Data exactly like Manual screen
      double getVal(String key) => (_scannedData![key] is num)
          ? (_scannedData![key] as num).toDouble()
          : 0.0;

      double calPer100 = getVal('caloriesPer100g');
      if (calPer100 == 0.0) calPer100 = getVal('calories');

      double carbsPer100 = getVal('carbs');
      if (carbsPer100 == 0.0) carbsPer100 = getVal('carbsPer100g');

      double proteinPer100 = getVal('protein');
      if (proteinPer100 == 0.0) proteinPer100 = getVal('proteinPer100g');

      double fatPer100 = getVal('fat');
      if (fatPer100 == 0.0) fatPer100 = getVal('fatPer100g');

      List<dynamic> servingSizes = [];
      if (_scannedData!['servingSizes'] is List) {
        servingSizes = _scannedData!['servingSizes'] as List;
      }

      double amount = 100.0;
      if (servingSizes.isNotEmpty && servingSizes.first is Map) {
        final firstOption = servingSizes.first;
        if (firstOption['grams'] is num) {
          amount = (firstOption['grams'] as num).toDouble();
        }
      }

      double ratio = amount / 100.0;
      int displayCals = (calPer100 * ratio).round();
      double displayCarbs = carbsPer100 * ratio;
      double displayProtein = proteinPer100 * ratio;
      double displayFat = fatPer100 * ratio;

      final docData = {
        'name': _scannedData!['name'] ?? 'Unknown',
        'caloriesPer100g': calPer100,
        'carbsPer100g': carbsPer100,
        'proteinPer100g': proteinPer100,
        'saturatedFatPer100g': fatPer100, // Matches your manual screen exactly
        'calories': displayCals,
        'estCalories': displayCals,
        'carbs': displayCarbs,
        'protein': displayProtein,
        'fat': displayFat,
        'servingSizes': servingSizes,
        'loggedServing': {
          'amount': amount,
          'unit': 'g',
          'calculatedGrams': amount,
        },
        'date': dateKey,
        'category': category,
        'timestamp': Timestamp.now(), // Instantly updates UI
      };

      // 3. Save to the CORRECT path!
      await FirebaseFirestore.instance
          .collection('mealslog')
          .doc(uid) // <--- Uses the Auth UID
          .collection('days') // <--- Nested inside days collection
          .doc(dateKey) // <--- Specific date
          .collection(category) // <--- Specific category
          .add(docData);

      logger.i("Firestore Write SUCCESS");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged to $_selectedMealType successfully!")),
      );

      // 4. Navigate to chosen screen
      Widget targetScreen;
      switch (category) {
        case 'breakfast':
          targetScreen = BreakfastScreen(
            selectedDate: now,
            cameras: widget.cameras,
            yolo: widget.yolo,
          );
          break;
        case 'lunch':
          targetScreen = LunchScreen(
            selectedDate: now,
            cameras: widget.cameras,
            yolo: widget.yolo,
          );
          break;
        case 'dinner':
          targetScreen = DinnerScreen(
            selectedDate: now,
            cameras: widget.cameras,
            yolo: widget.yolo,
          );
          break;
        case 'snack':
          targetScreen = SnacksScreen(
            selectedDate: now,
            cameras: widget.cameras,
            yolo: widget.yolo,
          );
          break;
        default:
          targetScreen = BreakfastScreen(
            selectedDate: now,
            cameras: widget.cameras,
            yolo: widget.yolo,
          );
      }

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => targetScreen));
    } catch (e) {
      logger.e("Failed to log meal: $e");

      if (mounted) {
        setState(() => _isLogging = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error Logging Meal"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  void _cancelLog() {
    logger.i("User Cancelled Logging");
    setState(() {
      _scannedLabel = null;
      _scannedData = null;
      _isLogging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2ECC71);
    final Color primaryBlue = const Color(0xFF4285F4);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double cameraHeight = screenWidth * 1.15;
    // We adjust overlap here manually
    const double overlapAmount = 45.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "AI MEAL SCAN",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // --- 1. Camera Stack (Just Camera + Overlay) ---
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Camera Preview
              Container(
                width: screenWidth - 32,
                height: cameraHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _isCameraInitialized && _previewController != null
                          ? CameraPreview(_previewController!)
                          : Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.05),
                              ],
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Targeting Overlay
              Positioned(
                top: 0,
                height: cameraHeight,
                width: screenWidth - 32,
                child: const IgnorePointer(child: ScanOverlay()),
              ),
            ],
          ),

          // --- 2. Prompt Card (Moved OUT of Stack) ---
          if (_scannedLabel != null)
            Transform.translate(
              // Move Up to overlap with camera
              offset: const Offset(0, -overlapAmount),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "LOG MEAL AS:",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                            letterSpacing: 0.8,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelLog,
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Meal Buttons
                    Row(
                      children: [
                        _buildMealOption(
                          value: 'breakfast',
                          icon: Icons.wb_sunny_outlined,
                          activeColor: primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildMealOption(
                          value: 'lunch',
                          text: 'LUNCH',
                          activeColor: primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildMealOption(
                          value: 'dinner',
                          icon: Icons.nightlight_round,
                          activeColor: primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        _buildMealOption(
                          value: 'snack',
                          text: 'SNACK',
                          activeColor: primaryGreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        "Scanned: $_scannedLabel",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (_scannedData != null &&
                        _scannedData!['estCalories'] != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Est. ${_scannedData!['estCalories']} kcal",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // --- CONFIRM BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isLogging
                            ? null
                            : () {
                                logger.i(
                                  "Confirm Button Clicked in UI",
                                ); // Immediate Log
                                _confirmLog();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          disabledBackgroundColor: primaryGreen.withValues(
                            alpha: 0.6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLogging
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "CONFIRM",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- 3. Spacing Adjustment ---
          // Since Card is translated up, we need to adjust space below it
          SizedBox(height: _scannedLabel != null ? 10 : overlapAmount + 25),

          // --- Bottom Icons ---
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(
                      Icons.mic,
                      "Voice Input",
                      _selectedIconIndex == 0,
                      onTap: () => _onBottomIconTapped(0),
                    ),
                    _buildIcon(
                      Icons.history,
                      "History",
                      _selectedIconIndex == 1,
                      onTap: () => _onBottomIconTapped(1),
                    ),
                    _buildIcon(
                      Icons.camera_alt,
                      "Camera",
                      _selectedIconIndex == 2,
                      onTap: _openFullCamera,
                    ),
                    _buildIcon(
                      Icons.favorite_border,
                      "Favorites",
                      _selectedIconIndex == 3,
                      onTap: () => _onBottomIconTapped(3),
                    ),
                    _buildIcon(
                      Icons.qr_code_scanner,
                      "Barcode",
                      _selectedIconIndex == 4,
                      onTap: () => _onBottomIconTapped(4),
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

  // --- Widget Helpers ---

  Widget _buildMealOption({
    required String value,
    IconData? icon,
    String? text,
    required Color activeColor,
  }) {
    final isSelected = _selectedMealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          logger.i("User Selected Meal Type: $value");
          setState(() => _selectedMealType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: icon != null
              ? Icon(
                  icon,
                  color: isSelected ? activeColor : Colors.grey,
                  size: 20,
                )
              : Text(
                  text ?? "",
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    IconData icon,
    String label,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    final Color activeColor = const Color(0xFF4285F4);
    final double size = isSelected ? 60 : 50;
    final double iconSize = isSelected ? 28 : 24;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.white,
              shape: BoxShape.circle,
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black45,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.split(' ')[0],
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? activeColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, -30),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2ECC71),
                    width: 2.5,
                  ),
                ),
              ),
              Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
