import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class YoloService {
  late Interpreter _interpreter;
  bool _initialized = false;

  static const int inputSize = 640; // YOLOv8 default

  // ✅ Hardcoded labels for your dataset
  final List<String> _labels = ["apple", "banana", "guava", "kiwi", "peach"];

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 🔎 Load the model bytes explicitly with the "assets/" prefix
      final data = await rootBundle.load('assets/best_float32.tflite');
      logger.i(
        "Asset found: assets/best_float32.tflite, size=${data.lengthInBytes} bytes",
      );

      // ✅ Create interpreter from buffer
      _interpreter = Interpreter.fromBuffer(data.buffer.asUint8List());
      logger.i("Interpreter successfully created from buffer");
    } catch (e) {
      logger.e("Failed to load TFLite model asset: $e");
      rethrow;
    }

    _initialized = true;

    logger.i("Model loaded with ${_labels.length} classes");
    for (var t in _interpreter.getInputTensors()) {
      logger.i("Input tensor: ${t.name}, shape=${t.shape}, type=${t.type}");
    }
    for (var t in _interpreter.getOutputTensors()) {
      logger.i("Output tensor: ${t.name}, shape=${t.shape}, type=${t.type}");
    }
  }

  Future<List<Map<String, dynamic>>> detect(String imagePath) async {
    if (!_initialized) {
      throw Exception("YoloService not initialized. Call init() first.");
    }

    // Load and preprocess image
    final imageBytes = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );

    // Prepare output buffer
    final outputTensor = _interpreter.getOutputTensors().first;
    final outputShape = outputTensor.shape;
    logger.i("Output shape: $outputShape");

    final output = List.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(outputShape);

    // Run inference
    _interpreter.run(input, output);

    // Postprocess
    const double confThreshold = 0.5;
    const double iouThreshold = 0.5;

    final results = <Map<String, dynamic>>[];

    // Case A: [1, 8400, 9] → boxes first, then channels
    if (outputShape[1] == 8400 && outputShape[2] == _labels.length + 4) {
      final numBoxes = outputShape[1];
      final numClasses = outputShape[2] - 4;

      for (int i = 0; i < numBoxes; i++) {
        final cx = output[0][i][0];
        final cy = output[0][i][1];
        final w = output[0][i][2];
        final h = output[0][i][3];

        double maxScore = 0;
        int classIndex = -1;
        for (int c = 0; c < numClasses; c++) {
          final score = output[0][i][4 + c];
          if (score > maxScore) {
            maxScore = score;
            classIndex = c;
          }
        }

        if (maxScore > confThreshold &&
            classIndex >= 0 &&
            classIndex < _labels.length) {
          results.add({
            "label": _labels[classIndex],
            "confidence": maxScore,
            "box": [cx, cy, w, h],
          });
        }
      }
    }
    // Case B: [1, 9, 8400] → channels first, then boxes
    else if (outputShape[1] == _labels.length + 4 && outputShape[2] == 8400) {
      final numBoxes = outputShape[2];
      final numClasses = outputShape[1] - 4;

      for (int i = 0; i < numBoxes; i++) {
        final cx = output[0][0][i];
        final cy = output[0][1][i];
        final w = output[0][2][i];
        final h = output[0][3][i];

        double maxScore = 0;
        int classIndex = -1;
        for (int c = 0; c < numClasses; c++) {
          final score = output[0][4 + c][i];
          if (score > maxScore) {
            maxScore = score;
            classIndex = c;
          }
        }

        if (maxScore > confThreshold &&
            classIndex >= 0 &&
            classIndex < _labels.length) {
          results.add({
            "label": _labels[classIndex],
            "confidence": maxScore,
            "box": [cx, cy, w, h],
          });
        }
      }
    } else {
      logger.e("Unexpected output shape: $outputShape");
    }

    return _nonMaxSuppression(results, iouThreshold);
  }

  List<Map<String, dynamic>> _nonMaxSuppression(
    List<Map<String, dynamic>> boxes,
    double iouThreshold,
  ) {
    // Sort by confidence descending
    boxes.sort(
      (a, b) =>
          (b["confidence"] as double).compareTo(a["confidence"] as double),
    );

    final selected = <Map<String, dynamic>>[];
    final usedLabels = <String>{};

    while (boxes.isNotEmpty) {
      final best = boxes.removeAt(0);

      // If we've already selected a detection for this label, skip
      if (usedLabels.contains(best["label"])) {
        continue;
      }

      selected.add(best);
      usedLabels.add(best["label"]);

      // Remove overlapping boxes of the same class
      boxes.removeWhere((box) {
        return box["label"] == best["label"] &&
            _iou(best["box"], box["box"]) > iouThreshold;
      });
    }

    return selected;
  }

  double _iou(List boxA, List boxB) {
    final xA1 = boxA[0] - boxA[2] / 2;
    final yA1 = boxA[1] - boxA[3] / 2;
    final xA2 = boxA[0] + boxA[2] / 2;
    final yA2 = boxA[1] + boxA[3] / 2;

    final xB1 = boxB[0] - boxB[2] / 2;
    final yB1 = boxB[1] - boxB[3] / 2;
    final xB2 = boxB[0] + boxB[2] / 2;
    final yB2 = boxB[1] + boxB[3] / 2;

    final interX1 = math.max(xA1, xB1);
    final interY1 = math.max(yA1, yB1);
    final interX2 = math.min(xA2, xB2);
    final interY2 = math.min(yA2, yB2);

    final interArea =
        math.max(0, interX2 - interX1) * math.max(0, interY2 - interY1);

    final boxAArea = (xA2 - xA1) * (yA2 - yA1);
    final boxBArea = (xB2 - xB1) * (yB2 - yB1);

    return interArea / (boxAArea + boxBArea - interArea);
  }
}
