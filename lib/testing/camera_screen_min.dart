import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'full_camera_screen_min.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = <CameraDescription>[];
  try {
    cameras = await availableCameras();
    logger.i("Main: found ${cameras.length} cameras");
  } catch (e) {
    logger.e("Main: failed to get available cameras: $e");
  }

  final yolo = YoloService();
  try {
    await yolo.init();
    logger.i("YOLO service initialized");
  } catch (e) {
    logger.e("YOLO init failed: $e");
  }

  runApp(MyApp(cameras: cameras, yolo: yolo));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;
  const MyApp({super.key, required this.cameras, required this.yolo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Meal Scan',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: CameraScreenMin(cameras: cameras, yolo: yolo),
    );
  }
}

class CameraScreenMin extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;
  const CameraScreenMin({super.key, required this.cameras, required this.yolo});

  @override
  State<CameraScreenMin> createState() => _CameraScreenMinState();
}

class _CameraScreenMinState extends State<CameraScreenMin>
    with WidgetsBindingObserver {
  CameraController? _previewController;
  bool _isCameraInitialized = false;

  // UI State
  String _selectedMealType = 'lunch';

  // Data State
  String? _scannedLabel; // If null, the card is hidden
  Map<String, dynamic>? _scannedData;

  // Navigation State
  int _selectedIconIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPreview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposePreview();
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
    if (widget.cameras.isEmpty) return;
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
    } catch (e) {
      logger.e("Preview init failed: $e");
    }
  }

  Future<void> _disposePreview() async {
    if (_previewController != null) {
      final controller = _previewController;
      _previewController = null;
      if (mounted) {
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
    setState(() {
      _selectedIconIndex = 2;
    });

    await _disposePreview();

    if (!mounted) return;

    // Wait for the result from the full camera screen
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FullCameraViewMin(cameras: widget.cameras, yolo: widget.yolo),
        fullscreenDialog: true,
      ),
    );

    // Re-init preview
    if (mounted) await _initPreview();

    // If we got data back, show the card
    if (result != null && result is Map && mounted) {
      setState(() {
        _scannedData = result as Map<String, dynamic>;
        _scannedLabel = result['name']?.toString();
      });
      logger.i("Received scanned data: $_scannedLabel");
    }
  }

  void _onBottomIconTapped(int index) {
    setState(() {
      _selectedIconIndex = index;
    });
  }

  void _confirmLog() {
    logger.i("Logging $_scannedLabel as $_selectedMealType");

    // Hide card after logging
    setState(() {
      _scannedLabel = null;
      _scannedData = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Meal Logged Successfully!")));
  }

  void _cancelLog() {
    setState(() {
      _scannedLabel = null;
      _scannedData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2ECC71);
    final Color primaryBlue = const Color(0xFF4285F4);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double cameraHeight = screenWidth * 1.15;
    const double cardOverhang = 45.0;

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

          // --- Camera Stack ---
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Camera Preview
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
                      // Gradient
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

              // 2. Targeting Overlay
              Positioned(
                top: 0,
                height: cameraHeight,
                width: screenWidth - 32,
                child: const IgnorePointer(child: ScanOverlay()),
              ),

              // 3. Prompt Card - ONLY SHOW IF _scannedLabel IS NOT NULL
              if (_scannedLabel != null)
                Positioned(
                  bottom: -cardOverhang,
                  left: 36,
                  right: 36,
                  child: Container(
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
                            // Cancel Button
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

                        // --- UNIFIED EQUAL SIZED BUTTONS ---
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

                        // -----------------------------------
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

                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _confirmLog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
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
            ],
          ),

          SizedBox(height: cardOverhang + 25),

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

  // New Helper for Equal Sized Buttons
  Widget _buildMealOption({
    required String value,
    IconData? icon,
    String? text,
    required Color activeColor,
  }) {
    final isSelected = _selectedMealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMealType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40, // Fixed equal height
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
        const Positioned(
          top: 0,
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(child: SizedBox.shrink()),
        ),

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

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:logger/logger.dart';
// import 'package:nutriapp/meal_log/yolo_service.dart';
// import 'package:nutriapp/meal_log/full_camera_screen.dart';

// final logger = Logger();

// class CameraScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;
//   final YoloService yolo;
//   const CameraScreen({super.key, required this.cameras, required this.yolo});

//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _previewController;
//   Future<void>? _initFuture;
//   bool _disposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _initPreview();
//   }

//   CameraDescription _pickInitialCamera(List<CameraDescription> cams) {
//     final back = cams
//         .where((c) => c.lensDirection == CameraLensDirection.back)
//         .toList();
//     return back.isNotEmpty ? back.first : cams.first;
//   }

//   Future<void> _initPreview() async {
//     if (widget.cameras.isEmpty) {
//       logger.w("Minimal preview: no cameras available");
//       setState(() => _initFuture = Future.value());
//       return;
//     }

//     final cam = _pickInitialCamera(widget.cameras);
//     logger.i("Minimal preview: creating controller for ${cam.name}");
//     final ctrl = CameraController(
//       cam,
//       ResolutionPreset.medium,
//       enableAudio: false,
//     );

//     _initFuture = ctrl
//         .initialize()
//         .then((_) async {
//           if (_disposed || !mounted) {
//             await ctrl.dispose();
//             return;
//           }
//           try {
//             await ctrl.setFlashMode(FlashMode.off);
//           } catch (e) {
//             logger.w("Flash off failed on init: $e");
//           }
//           logger.i("Minimal preview: initialized");
//           setState(() => _previewController = ctrl);
//         })
//         .catchError((e, st) async {
//           logger.e("Minimal preview: init failed: $e");
//           try {
//             await ctrl.dispose();
//           } catch (_) {}
//           if (mounted) setState(() => _previewController = null);
//         });
//   }

//   Future<void> _disposePreview() async {
//     final ctrl = _previewController;
//     if (ctrl == null) return;
//     try {
//       if (ctrl.value.isStreamingImages) {
//         await ctrl.stopImageStream();
//       }
//     } catch (e) {
//       logger.w("stopImageStream failed during preview dispose: $e");
//     }
//     try {
//       await ctrl.dispose();
//       logger.i("Minimal preview: disposed");
//     } catch (e) {
//       logger.w("Minimal preview: dispose error: $e");
//     } finally {
//       _previewController = null;
//       _initFuture = null;
//     }
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     _disposePreview();
//     super.dispose();
//   }

//   Future<void> _openFullCamera() async {
//     if (!mounted) return;
//     final navigator = Navigator.of(context);

//     await _disposePreview();
//     if (!mounted) return;

//     await navigator.push(
//       MaterialPageRoute(
//         builder: (_) => FullCameraViewMin(
//           cameras: widget.cameras,
//           yolo: widget.yolo, // may throw on detect if init failed
//         ),
//         fullscreenDialog: true,
//       ),
//     );

//     if (!mounted) return;
//     _initPreview();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size.width * 0.8;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Minimal preview")),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: size,
//             height: size,
//             child: FutureBuilder<void>(
//               future: _initFuture,
//               builder: (context, snap) {
//                 if (snap.connectionState == ConnectionState.done &&
//                     _previewController != null &&
//                     _previewController!.value.isInitialized) {
//                   return ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: CameraPreview(_previewController!),
//                   );
//                 } else if (snap.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else {
//                   return const Center(child: Text("Preview not ready"));
//                 }
//               },
//             ),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: _openFullCamera,
//             child: const Text("Open full camera"),
//           ),
//         ],
//       ),
//     );
//   }
// }
