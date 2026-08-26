import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../models/detection_history.dart';
import '../models/detection_result.dart';
import '../models/detection_settings.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';
import '../services/image_processor.dart';
import '../services/speech_service.dart';
import '../services/tflite_service.dart';

class DetectionController extends ChangeNotifier {
  final CameraService _cameraService;
  final TFLiteService _tfliteService;
  final SpeechService _speechService;
  final DatabaseService _databaseService;

  bool _isDetecting = false;
  bool _isProcessingFrame = false;
  
  // Throttle frames to avoid queueing up too much work
  int _frameCount = 0;
  final int _processEveryNFrames = 10; 

  List<DetectionResult> _currentResults = [];

  bool get isDetecting => _isDetecting;
  List<DetectionResult> get currentResults => _currentResults;

  // Voice Announcement Cooldown
  final Map<String, DateTime> _lastAnnouncedObjects = {};
  final Duration announcementCooldown = const Duration(seconds: 5);

  // Database Save Cooldown
  final Map<String, DateTime> _lastSavedObjects = {};
  final Duration databaseSaveCooldown = const Duration(seconds: 10);

  DetectionController(this._cameraService, this._tfliteService, this._speechService, this._databaseService) {
    _cameraService.addListener(_onCameraStateChanged);
  }

  void _onCameraStateChanged() {
    if (_cameraService.isInitialized && _cameraService.controller != null && _isDetecting) {
      _startImageStream();
    }
  }

  void toggleDetection() {
    if (!_tfliteService.isInitialized || _tfliteService.hasError) {
      log('Cannot start detection: TFLite Service not ready or has error');
      return;
    }

    _isDetecting = !_isDetecting;
    
    if (_isDetecting) {
      _startImageStream();
    } else {
      _stopImageStream();
      _currentResults = [];
      _speechService.stop();
    }
    
    notifyListeners();
  }

  Future<void> _startImageStream() async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;
    
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processFrame);
    } catch (e) {
      log('Error starting image stream: $e');
      _isDetecting = false;
      notifyListeners();
    }
  }

  Future<void> _stopImageStream() async {
    final controller = _cameraService.controller;
    if (controller != null && controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (e) {
        log('Error stopping image stream: $e');
      }
    }
  }

  DetectionSettings _settings = DetectionSettings();
  DetectionSettings get settings => _settings;

  void updateSettings(DetectionSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  void _processFrame(CameraImage cameraImage) async {
    if (!_isDetecting || _isProcessingFrame) return;

    _frameCount++;
    if (_frameCount % _processEveryNFrames != 0) return;

    _isProcessingFrame = true;

    try {
      final processedImage = ImageProcessor.processCameraImage(cameraImage);
      
      if (processedImage != null) {
        final rawResults = _tfliteService.runInference(processedImage);
        final filteredResults = rawResults.where((r) => r.confidence >= _settings.minimumConfidence).toList();
        
        _currentResults = filteredResults;
        notifyListeners();

        _announceResults(filteredResults);
        _saveResultsToDatabase(filteredResults);
      }
    } catch (e) {
      log('Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _announceResults(List<DetectionResult> results) {
    if (results.isEmpty || !_speechService.settings.enabled) return;

    final now = DateTime.now();
    List<String> objectsToAnnounce = [];

    for (var result in results) {
      final label = result.label;
      final lastAnnounced = _lastAnnouncedObjects[label];

      if (lastAnnounced == null || now.difference(lastAnnounced) > announcementCooldown) {
        objectsToAnnounce.add(label);
        _lastAnnouncedObjects[label] = now;
      }
    }

    if (objectsToAnnounce.isNotEmpty) {
      objectsToAnnounce = objectsToAnnounce.toSet().toList();
      
      String announcement = '';
      if (objectsToAnnounce.length == 1) {
        announcement = '${objectsToAnnounce[0]} detected';
      } else if (objectsToAnnounce.length == 2) {
        announcement = '${objectsToAnnounce[0]} and ${objectsToAnnounce[1]} detected';
      } else {
        final last = objectsToAnnounce.removeLast();
        announcement = '${objectsToAnnounce.join(', ')}, and $last detected';
      }

      _speechService.speak(announcement);
    }
  }

  void _saveResultsToDatabase(List<DetectionResult> results) {
    if (results.isEmpty) return;
    
    final now = DateTime.now();

    for (var result in results) {
      final label = result.label;
      final lastSaved = _lastSavedObjects[label];

      if (lastSaved == null || now.difference(lastSaved) > databaseSaveCooldown) {
        _lastSavedObjects[label] = now;
        
        final history = DetectionHistory(
          objectName: label,
          confidence: result.confidence,
          timestamp: now,
          boundingBox: result.boundingBox,
        );
        _databaseService.insertDetection(history);
      }
    }
  }

  void announceTargetObject(String object) {
    _speechService.speak('$object found');
  }

  @override
  void dispose() {
    _stopImageStream();
    _cameraService.removeListener(_onCameraStateChanged);
    super.dispose();
  }
}

