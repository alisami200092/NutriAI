import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';

final logger = Logger();

class FullCameraViewMin extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const FullCameraViewMin({
    super.key,
    required this.cameras,
    required this.yolo,
  });

  @override
  State<FullCameraViewMin> createState() => _FullCameraViewMinState();
}

class _FullCameraViewMinState extends State<FullCameraViewMin>
    with SingleTickerProviderStateMixin {
  // ===== Feature toggles =====
  final bool kEnableTorch = true;
  final bool kEnableTapToFocus = true;
  final bool kEnableSwitchCamera = true;
  final bool kEnableDetection = true;
  final bool kShowBoxesOverlay = true;
  // -----------------------------------------------

  CameraController? _controller;
  Future<void>? _initFuture;
  late CameraDescription _currentCamera;

  bool _disposed = false;
  bool _torchOn = false;
  bool _capturing = false;

  bool _yoloReady = false;

  List<Map<String, dynamic>> _predictions = [];

  Offset? _reticlePos;
  bool _showReticle = false;
  late AnimationController _reticleAnim;

  @override
  void initState() {
    super.initState();
    _currentCamera = _pickInitialCamera(widget.cameras);
    _createController(_currentCamera);
    _initYolo();

    _reticleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  Future<void> _initYolo() async {
    try {
      await widget.yolo.init();
      if (!mounted) return;
      setState(() => _yoloReady = true);
      logger.i("FullCameraViewMin: YOLO initialized");
    } catch (e) {
      logger.e("FullCameraViewMin: YOLO init failed: $e");
      _yoloReady = false;
    }
  }

  CameraDescription _pickInitialCamera(List<CameraDescription> cams) {
    final back = cams
        .where((c) => c.lensDirection == CameraLensDirection.back)
        .toList();
    return back.isNotEmpty ? back.first : cams.first;
  }

  void _createController(CameraDescription cam) {
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initFuture = _controller!
        .initialize()
        .then((_) async {
          if (kEnableTorch) {
            try {
              await _controller!.setFlashMode(FlashMode.off);
              _torchOn = false;
            } catch (e) {
              logger.w("Failed to set flash off: $e");
            }
          }
          if (!_disposed && mounted) setState(() {});
        })
        .catchError((e) {
          logger.e("Camera init failed: $e");
        });
  }

  Future<void> _disposeController() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    try {
      if (ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
    } catch (_) {}
    try {
      await ctrl.dispose();
    } catch (_) {
    } finally {
      _controller = null;
      _initFuture = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reticleAnim.dispose();
    _disposeController();
    super.dispose();
  }

  Future<void> _captureAndDetect() async {
    if (_capturing) return;
    _capturing = true;

    try {
      await _initFuture;
      if (_controller == null || !_controller!.value.isInitialized) return;

      if (kEnableDetection && !_yoloReady) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Detector not ready")));
        }
        return;
      }

      final image = await _controller!.takePicture();

      if (kEnableDetection) {
        final predictions = await widget.yolo.detect(image.path);

        if (!mounted || _disposed) return;
        setState(() => _predictions = predictions);

        final foodData = _mapPredictionsToFoodData(predictions);

        // 1. Show SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                foodData != null
                    ? "Detected: ${foodData['name']}"
                    : "No food detected",
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // 2. Show Dialog and Return Data
        if (foodData != null && mounted) {
          _showDetectionPrompt(foodData);
        }
      }
    } catch (e) {
      logger.e("Error during capture: $e");
    } finally {
      _capturing = false;
    }
  }

  void _showDetectionPrompt(Map<String, dynamic> foodData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(height: 10),
              Text(
                "Detected: ${foodData['name']}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Do you want to log this item?",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog, stay on camera
              },
              child: const Text("Retake", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                // Return data to previous screen
                Navigator.pop(context, foodData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic>? _mapPredictionsToFoodData(
    List<Map<String, dynamic>> preds,
  ) {
    if (preds.isEmpty) return null;
    // Sort by confidence
    preds.sort((a, b) {
      final ca = (a['confidence'] ?? 0.0) is num
          ? (a['confidence'] as num).toDouble()
          : 0.0;
      final cb = (b['confidence'] ?? 0.0) is num
          ? (b['confidence'] as num).toDouble()
          : 0.0;
      return cb.compareTo(ca);
    });

    final top = preds.first;
    final label = (top['label'] ?? '').toString().toLowerCase();

    // Mock data based on label
    if (label.contains('banana')) {
      return {
        "barcode": "1234567890123",
        "name": "Banana",
        "estCalories": 89,
        // Add more fields if needed for your main screen logic
      };
    } else if (label.contains('apple')) {
      return {"barcode": "111", "name": "Apple", "estCalories": 52};
    }

    return {
      "barcode": null,
      "name": label.isNotEmpty ? label : "Unknown Food",
      "estCalories": 0,
    };
  }

  Future<void> _toggleTorch() async {
    if (!kEnableTorch || _controller == null) return;
    try {
      await _controller!.setFlashMode(
        _torchOn ? FlashMode.off : FlashMode.torch,
      );
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (!kEnableSwitchCamera) return;
    await _disposeController();
    final idx =
        (widget.cameras.indexOf(_currentCamera) + 1) % widget.cameras.length;
    _currentCamera = widget.cameras[idx];
    _createController(_currentCamera);
    if (mounted) setState(() {});
  }

  Future<void> _setFocusFromTap(TapDownDetails details) async {
    if (!kEnableTapToFocus || _controller == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final nx = (local.dx / box.size.width).clamp(0.0, 1.0);
    final ny = (local.dy / box.size.height).clamp(0.0, 1.0);
    try {
      await _controller!.setFocusPoint(Offset(nx, ny));
      setState(() {
        _reticlePos = local;
        _showReticle = true;
      });
      _reticleAnim.reset();
      _reticleAnim.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _showReticle = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _setFocusFromTap,
                  child: CameraPreview(_controller!),
                ),

                // Reticle
                if (kEnableTapToFocus && _showReticle && _reticlePos != null)
                  Positioned(
                    left: _reticlePos!.dx - 24,
                    top: _reticlePos!.dy - 24,
                    width: 48,
                    height: 48,
                    child: ScaleTransition(
                      scale: _reticleAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                // Bounding Boxes
                if (kShowBoxesOverlay)
                  ..._predictions.map((p) {
                    final rect = p["rect"];
                    final label = p["label"]?.toString() ?? "";
                    if (rect is Map<String, dynamic>) {
                      return Positioned(
                        left: (rect["x"] ?? 0).toDouble(),
                        top: (rect["y"] ?? 0).toDouble(),
                        width: (rect["w"] ?? 0).toDouble(),
                        height: (rect["h"] ?? 0).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.green,
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                // Capture Button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: _captureAndDetect,
                      child: const Icon(
                        Icons.camera,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Top Controls
                Positioned(
                  top: 40,
                  right: 20,
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _torchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                        onPressed: _toggleTorch,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ),

                // Back Button
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
