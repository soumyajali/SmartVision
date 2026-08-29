import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection_result.dart';

class TFLiteService extends ChangeNotifier {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  List<String> _labels = [];
  
  bool get isInitialized => _isInitialized;
  List<String> get labels => _labels;
  bool get hasError => _error != null;
  String? _error;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      log('Initializing TFLite Service...');
      await loadLabels();
      await loadModel();
      _isInitialized = true;
      _error = null;
      notifyListeners();
      log('TFLite Service initialized successfully.');
    } catch (e) {
      _error = 'Failed to load model: $e';
      log('Error initializing TFLite Service: $e');
      notifyListeners();
    }
  }

  Future<void> loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
      log('Loaded ${_labels.length} labels.');
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset('assets/models/yolov8n.tflite', options: options);
      log('Interpreter loaded successfully.');
    } catch (e) {
      throw Exception('Failed to load TFLite model: $e');
    }
  }

  List<DetectionResult> runInference(image_lib.Image image) {
    if (_interpreter == null || !_isInitialized) return [];

    try {
      // 1. Preprocess: Resize and Normalize
      // Input shape depends on YOLOv8 export: usually [1, 640, 640, 3] or [1, 3, 640, 640]
      // Float16 models take float32 input in tflite_flutter, so we normalize.
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      
      // Typical YOLOv8 input is [1, 640, 640, 3] NHWC
      final width = inputShape[1];
      final height = inputShape[2];

      // Convert image to normalized float32 tensor
      var inputTensor = Float32List(1 * width * height * 3);
      var index = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          inputTensor[index++] = image_lib.getRed(pixel) / 255.0;
          inputTensor[index++] = image_lib.getGreen(pixel) / 255.0;
          inputTensor[index++] = image_lib.getBlue(pixel) / 255.0;
        }
      }

      // YOLOv8 output is usually [1, 84, 8400]
      // [batch, classes + bbox(4), anchors]
      final outClassesBbox = outputShape[1]; // 84
      final outAnchors = outputShape[2]; // 8400

      var outputTensor = List.generate(
        1,
        (_) => List.generate(
          outClassesBbox,
          (_) => List.filled(outAnchors, 0.0),
        ),
      );

      // Run inference
      _interpreter!.run(inputTensor.buffer.asUint8List(), outputTensor);

      // Parse output
      return _parseOutput(outputTensor[0], outClassesBbox, outAnchors);
    } catch (e) {
      log('Inference error: $e');
      return [];
    }
  }

  List<DetectionResult> _parseOutput(List<List<double>> output, int classesBbox, int anchors) {
    List<DetectionResult> results = [];
    
    // threshold for confidence
    const confidenceThreshold = 0.5;

    for (int i = 0; i < anchors; i++) {
      // Find highest class confidence for this anchor
      double maxClassScore = 0;
      int classId = -1;
      
      for (int c = 4; c < classesBbox; c++) {
        if (output[c][i] > maxClassScore) {
          maxClassScore = output[c][i];
          classId = c - 4; // offset by 4 for bbox
        }
      }

      if (maxClassScore > confidenceThreshold && classId >= 0 && classId < _labels.length) {
        // cx, cy, w, h
        final cx = output[0][i];
        final cy = output[1][i];
        final w = output[2][i];
        final h = output[3][i];

        results.add(DetectionResult(
          label: _labels[classId],
          confidence: maxClassScore,
          boundingBox: Rect.fromCenter(
            center: Offset(cx, cy),
            width: w,
            height: h,
          ),
        ));
      }
    }

    // Sort by confidence (Non-Maximum Suppression should happen here ideally)
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Return top 5 for simplicity and performance before NMS implementation
    return results.take(5).toList();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
