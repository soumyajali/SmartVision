import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:video_player/video_player.dart';

import '../models/detection_result.dart';
import '../models/detection_settings.dart';

class OnDeviceAiService extends ChangeNotifier {
  OnDeviceAiService._();

  static final OnDeviceAiService instance = OnDeviceAiService._();

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  List<String> _labels = const [];
  String? _modelError;
  bool _isLoading = false;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  int _closedEyeFrames = 0;
  int _drowsinessIncidents = 0;
  bool _wasDrowsy = false;

  bool get isModelLoaded => _interpreter != null;
  bool get isLoading => _isLoading;
  String? get modelError => _modelError;
  String get modelName => 'YOLOv8n TFLite · COCO 80';

  Future<void> initialize() async {
    if (_interpreter != null || _isLoading) return;
    _isLoading = true;
    _modelError = null;
    notifyListeners();
    try {
      final options = InterpreterOptions()..threads = 4;
      final interpreter = await Interpreter.fromAsset(
        'assets/models/yolov8n.tflite',
        options: options,
      );
      interpreter.allocateTensors();
      final input = interpreter.getInputTensor(0);
      final output = interpreter.getOutputTensor(0);
      if (input.shape.length != 4 ||
          input.shape[0] != 1 ||
          input.shape[3] != 3 ||
          input.type != TensorType.float32) {
        interpreter.close();
        throw StateError(
          'Unsupported YOLOv8n input tensor: shape=${input.shape}, '
          'type=${input.type}. Expected [1, height, width, 3] float32.',
        );
      }
      if (output.shape.length != 3 || output.type != TensorType.float32) {
        interpreter.close();
        throw StateError(
          'Unsupported YOLOv8n output tensor: '
          'shape=${output.shape}, type=${output.type}.',
        );
      }

      final labels = (await rootBundle.loadString(
        'assets/models/labels.txt',
      ))
          .split(RegExp(r'\r?\n'))
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList(growable: false);
      final expectedChannels = labels.length + 4;
      if (output.shape[1] != expectedChannels &&
          output.shape[2] != expectedChannels) {
        interpreter.close();
        throw StateError(
          'YOLOv8 output does not match the bundled labels: '
          'shape=${output.shape}, labels=${labels.length}.',
        );
      }

      _labels = labels;
      _interpreter = interpreter;
      _isolateInterpreter =
          await IsolateInterpreter.create(address: interpreter.address);
    } catch (error) {
      _modelError = 'Could not load on-device object model: $error';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DetectionResult>> detectObjects(
    Uint8List bytes, {
    DetectionSettings settings = const DetectionSettings(),
  }) async {
    await initialize();
    final interpreter = _interpreter!;
    final isolate = _isolateInterpreter!;
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final inputHeight = inputTensor.shape[1];
    final inputWidth = inputTensor.shape[2];
    final decoded = image.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('The selected image could not be decoded.');
    }
    final resized = image.copyResize(
      decoded,
      width: inputWidth,
      height: inputHeight,
      interpolation: image.Interpolation.linear,
    );
    final inputBytes = Uint8List(inputWidth * inputHeight * 3 * 4);
    final inputData = ByteData.view(inputBytes.buffer);
    var inputOffset = 0;
    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        inputData.setFloat32(
          inputOffset,
          image.getRed(pixel) / 255,
          Endian.little,
        );
        inputData.setFloat32(
          inputOffset + 4,
          image.getGreen(pixel) / 255,
          Endian.little,
        );
        inputData.setFloat32(
          inputOffset + 8,
          image.getBlue(pixel) / 255,
          Endian.little,
        );
        inputOffset += 12;
      }
    }

    final outputBytes = Uint8List(outputTensor.numBytes());
    await isolate.run(inputBytes, outputBytes);
    return _decodeDetections(
      outputBytes,
      outputTensor.shape,
      inputWidth,
      inputHeight,
      settings,
    );
  }

  List<DetectionResult> _decodeDetections(
    Uint8List bytes,
    List<int> shape,
    int inputWidth,
    int inputHeight,
    DetectionSettings settings,
  ) {
    final channelsFirst = shape[1] == _labels.length + 4;
    final candidateCount = channelsFirst ? shape[2] : shape[1];
    final output = ByteData.view(bytes.buffer, bytes.offsetInBytes);

    double valueAt(int candidate, int channel) {
      final element = channelsFirst
          ? channel * candidateCount + candidate
          : candidate * (_labels.length + 4) + channel;
      return output.getFloat32(element * 4, Endian.little);
    }

    final candidates = <_Candidate>[];
    for (var index = 0; index < candidateCount; index++) {
      var labelIndex = 0;
      var confidence = 0.0;
      for (var label = 0; label < _labels.length; label++) {
        final score = valueAt(index, label + 4);
        if (score > confidence) {
          confidence = score;
          labelIndex = label;
        }
      }
      if (!confidence.isFinite || confidence < settings.minimumConfidence) {
        continue;
      }

      var centerX = valueAt(index, 0);
      var centerY = valueAt(index, 1);
      var boxWidth = valueAt(index, 2);
      var boxHeight = valueAt(index, 3);
      if (![centerX, centerY, boxWidth, boxHeight]
          .every((value) => value.isFinite)) {
        continue;
      }
      if (centerX.abs() <= 1.5 &&
          centerY.abs() <= 1.5 &&
          boxWidth.abs() <= 1.5 &&
          boxHeight.abs() <= 1.5) {
        centerX *= inputWidth;
        centerY *= inputHeight;
        boxWidth *= inputWidth;
        boxHeight *= inputHeight;
      }
      final left =
          ((centerX - boxWidth / 2) / inputWidth).clamp(0.0, 1.0).toDouble();
      final top =
          ((centerY - boxHeight / 2) / inputHeight).clamp(0.0, 1.0).toDouble();
      final right =
          ((centerX + boxWidth / 2) / inputWidth).clamp(0.0, 1.0).toDouble();
      final bottom =
          ((centerY + boxHeight / 2) / inputHeight).clamp(0.0, 1.0).toDouble();
      if (right <= left || bottom <= top) continue;
      candidates.add(
        _Candidate(
          label: _labels[labelIndex],
          confidence: confidence,
          rect: Rect.fromLTRB(left, top, right, bottom),
        ),
      );
    }

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final selected = <_Candidate>[];
    for (final candidate in candidates) {
      final overlaps = selected.any(
        (kept) =>
            kept.label == candidate.label &&
            _intersectionOverUnion(kept.rect, candidate.rect) >
                settings.iouThreshold,
      );
      if (!overlaps) selected.add(candidate);
      if (selected.length >= settings.maximumDetections) break;
    }

    const hazardLabels = {'knife', 'scissors'};
    return selected
        .map(
          (candidate) => DetectionResult(
            label: candidate.label,
            confidence: candidate.confidence,
            boundingBox: candidate.rect,
            isHazard: hazardLabels.contains(candidate.label.toLowerCase()),
          ),
        )
        .toList(growable: false);
  }

  double _intersectionOverUnion(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.isEmpty) return 0;
    final intersectionArea = intersection.width * intersection.height;
    final unionArea =
        a.width * a.height + b.width * b.height - intersectionArea;
    return unionArea <= 0 ? 0 : intersectionArea / unionArea;
  }

  Future<String> recognizeTextFromFile(String path) async {
    final recognized = await _textRecognizer.processImage(
      InputImage.fromFilePath(path),
    );
    return recognized.text;
  }

  Future<String> recognizeTextFromBytes(Uint8List bytes) async {
    final file = await _writeTemporaryImage(bytes, 'ocr');
    try {
      return await recognizeTextFromFile(file.path);
    } finally {
      await file.delete();
    }
  }

  Future<List<Face>> detectFacesFromBytes(Uint8List bytes) async {
    final file = await _writeTemporaryImage(bytes, 'face-detection');
    try {
      return await _faceDetector.processImage(
        InputImage.fromFilePath(file.path),
      );
    } finally {
      await file.delete();
    }
  }

  Future<Map<String, dynamic>> recognizeTextFromVideo(String path) async {
    final durationMs = await _videoDurationMs(path);
    final lines = <String>[];
    final seen = <String>{};
    final timeline = <Map<String, dynamic>>[];
    var framesProcessed = 0;
    for (var timeMs = 0;
        timeMs < durationMs && framesProcessed < 600;
        timeMs += 1000) {
      final bytes = await _videoFrame(path, timeMs);
      if (bytes == null) continue;
      final text = await recognizeTextFromBytes(bytes);
      framesProcessed++;
      final uniqueLines = <String>[];
      for (final line in text.split('\n').map((value) => value.trim())) {
        if (line.isEmpty || !seen.add(line.toLowerCase())) continue;
        lines.add(line);
        uniqueLines.add(line);
      }
      if (uniqueLines.isNotEmpty) {
        timeline.add({
          'seconds': timeMs / 1000,
          'text': uniqueLines.join('\n'),
        });
      }
    }
    if (framesProcessed == 0) {
      throw StateError('No frames could be extracted from this video.');
    }
    return {
      'full_text': lines.join('\n'),
      'timeline': timeline,
      'total_frames_processed': framesProcessed,
      'truncated': durationMs > 600000,
    };
  }

  Future<Map<String, dynamic>> reviewVideo({
    required String path,
    required String targetObject,
    required DetectionSettings settings,
  }) async {
    await initialize();
    final durationMs = await _videoDurationMs(path);
    final timeline = <Map<String, dynamic>>[];
    var framesProcessed = 0;
    var detectionsCount = 0;
    for (var timeMs = 0;
        timeMs < durationMs && framesProcessed < 600;
        timeMs += 1000) {
      final bytes = await _videoFrame(path, timeMs);
      if (bytes == null) continue;
      final detections = await detectObjects(bytes, settings: settings);
      framesProcessed++;
      final matching = detections
          .where(
              (item) => item.label.toLowerCase() == targetObject.toLowerCase())
          .toList();
      if (matching.isEmpty) continue;
      detectionsCount += matching.length;
      timeline.add({
        'seconds': timeMs / 1000,
        'timestamp': _formatTimestamp(timeMs),
        'detections': matching
            .map(
              (item) => {
                'label': item.label,
                'confidence': item.confidence,
                'rect': {
                  'left': item.boundingBox.left,
                  'top': item.boundingBox.top,
                  'right': item.boundingBox.right,
                  'bottom': item.boundingBox.bottom,
                },
              },
            )
            .toList(),
      });
    }
    if (framesProcessed == 0) {
      throw StateError('No frames could be extracted from this video.');
    }
    return {
      'target': targetObject,
      'timeline': timeline,
      'total_events': timeline.length,
      'total_detections': detectionsCount,
      'total_frames_processed': framesProcessed,
      'truncated': durationMs > 600000,
    };
  }

  Future<Map<String, dynamic>> analyzeDrowsinessImage(
    Uint8List bytes, {
    required double closedEyeProbabilityThreshold,
    required int consecutiveFrames,
  }) async {
    final file = await _writeTemporaryImage(bytes, 'drowsiness');
    try {
      final faces = await _faceDetector.processImage(
        InputImage.fromFilePath(file.path),
      );
      if (faces.isEmpty) {
        _closedEyeFrames = 0;
        _wasDrowsy = false;
        return {
          'face_detected': false,
          'eye_open_probability': null,
          'drowsy': false,
          'closed_frames': 0,
          'incidents': _drowsinessIncidents,
        };
      }
      final probabilities = [
        faces.first.leftEyeOpenProbability,
        faces.first.rightEyeOpenProbability,
      ].whereType<double>().toList();
      if (probabilities.isEmpty) {
        throw StateError(
          'The face detector could not estimate eye openness. '
          'Improve lighting and face the camera directly.',
        );
      }
      final eyeOpenProbability =
          probabilities.reduce((a, b) => a + b) / probabilities.length;
      final eyesClosed = eyeOpenProbability < closedEyeProbabilityThreshold;
      _closedEyeFrames = eyesClosed ? _closedEyeFrames + 1 : 0;
      final drowsy = _closedEyeFrames >= consecutiveFrames;
      if (drowsy && !_wasDrowsy) _drowsinessIncidents++;
      _wasDrowsy = drowsy;
      return {
        'face_detected': true,
        'eye_open_probability': eyeOpenProbability,
        'drowsy': drowsy,
        'closed_frames': _closedEyeFrames,
        'incidents': _drowsinessIncidents,
      };
    } finally {
      await file.delete();
    }
  }

  Future<Map<String, dynamic>> analyzeDrowsinessVideo({
    required String path,
    required double closedEyeProbabilityThreshold,
    required int consecutiveFrames,
  }) async {
    resetDrowsinessSession();
    final durationMs = await _videoDurationMs(path);
    final incidents = <Map<String, dynamic>>[];
    var framesProcessed = 0;
    var wasDrowsy = false;
    for (var timeMs = 0;
        timeMs < durationMs && framesProcessed < 600;
        timeMs += 1000) {
      final bytes = await _videoFrame(path, timeMs);
      if (bytes == null) continue;
      final result = await analyzeDrowsinessImage(
        bytes,
        closedEyeProbabilityThreshold: closedEyeProbabilityThreshold,
        consecutiveFrames: consecutiveFrames,
      );
      framesProcessed++;
      final drowsy = result['drowsy'] == true;
      if (drowsy && !wasDrowsy) {
        incidents.add({
          'timestamp': _formatTimestamp(timeMs),
          'seconds': timeMs / 1000,
          'eye_open_probability': result['eye_open_probability'],
        });
      }
      wasDrowsy = drowsy;
    }
    if (framesProcessed == 0) {
      throw StateError('No frames could be extracted from this video.');
    }
    return {
      'incidents': incidents,
      'total_incidents': incidents.length,
      'frames_analyzed': framesProcessed,
      'truncated': durationMs > 600000,
    };
  }

  void resetDrowsinessSession() {
    _closedEyeFrames = 0;
    _drowsinessIncidents = 0;
    _wasDrowsy = false;
  }

  Future<int> _videoDurationMs(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      return controller.value.duration.inMilliseconds;
    } finally {
      await controller.dispose();
    }
  }

  Future<Uint8List?> _videoFrame(String path, int timeMs) {
    return const MethodChannel('com.smartvision/video_frames')
        .invokeMethod<Uint8List>(
      'getFrame',
      {
        'path': path,
        'timeMs': timeMs,
        'maxWidth': 640,
        'quality': 75,
      },
    );
  }

  String _formatTimestamp(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String summarizeText(String text, {int maxSentences = 3}) {
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();
    if (sentences.length <= maxSentences) return sentences.join(' ');

    const stopWords = {
      'a',
      'an',
      'and',
      'are',
      'as',
      'at',
      'be',
      'by',
      'for',
      'from',
      'in',
      'is',
      'it',
      'of',
      'on',
      'or',
      'that',
      'the',
      'this',
      'to',
      'was',
      'were',
      'with',
    };
    final frequencies = <String, int>{};
    final wordsBySentence = <List<String>>[];
    for (final sentence in sentences) {
      final words = RegExp(r"[A-Za-z0-9']+")
          .allMatches(sentence.toLowerCase())
          .map((match) => match.group(0)!)
          .where((word) => !stopWords.contains(word))
          .toList();
      wordsBySentence.add(words);
      for (final word in words) {
        frequencies.update(word, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final ranked = List.generate(sentences.length, (index) {
      final words = wordsBySentence[index];
      final score = words.isEmpty
          ? 0.0
          : words.fold<int>(0, (sum, word) => sum + frequencies[word]!) /
              words.length;
      return (index: index, score: score);
    })
      ..sort((a, b) => b.score.compareTo(a.score));
    final selected =
        ranked.take(maxSentences).map((item) => item.index).toList()..sort();
    return selected.map((index) => sentences[index]).join(' ');
  }

  Future<String> translateText({
    required String text,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Text must not be empty.');
    }
    final target = _translateLanguage(targetLanguage);
    if (target == null) {
      throw UnsupportedError(
        'On-device translation does not support $targetLanguage.',
      );
    }
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    String sourceCode;
    try {
      sourceCode = await identifier.identifyLanguage(text);
    } finally {
      await identifier.close();
    }
    final source = BCP47Code.fromRawValue(sourceCode);
    if (source == null) {
      throw StateError('Could not identify the source language.');
    }
    if (source == target) return text;

    final manager = OnDeviceTranslatorModelManager();
    final sourceReady = await manager.downloadModel(
      source.bcpCode,
      isWifiRequired: false,
    );
    final targetReady = await manager.downloadModel(
      target.bcpCode,
      isWifiRequired: false,
    );
    if (!sourceReady || !targetReady) {
      throw StateError(
          'Required on-device translation models are unavailable.');
    }
    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return await translator.translateText(text);
    } finally {
      await translator.close();
    }
  }

  TranslateLanguage? _translateLanguage(String name) {
    final normalized = name.trim().toLowerCase();
    final aliases = <String, String>{
      'chinese (simplified)': 'chinese',
      'hindi': 'hindi',
      'kannada': 'kannada',
      'telugu': 'telugu',
      'tamil': 'tamil',
      'marathi': 'marathi',
      'bengali': 'bengali',
      'gujarati': 'gujarati',
      'spanish': 'spanish',
      'french': 'french',
      'german': 'german',
      'japanese': 'japanese',
      'russian': 'russian',
      'arabic': 'arabic',
    };
    final language = aliases[normalized];
    if (language == null) return null;
    for (final value in TranslateLanguage.values) {
      if (value.name == language) return value;
    }
    return null;
  }

  Future<File> _writeTemporaryImage(Uint8List bytes, String prefix) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/$prefix-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _isolateInterpreter?.close();
    _textRecognizer.close();
    _faceDetector.close();
    super.dispose();
  }
}

class _Candidate {
  const _Candidate({
    required this.label,
    required this.confidence,
    required this.rect,
  });

  final String label;
  final double confidence;
  final Rect rect;
}
