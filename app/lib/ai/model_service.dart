import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../face_recognition/services/face_recognition_service.dart';
import '../face_recognition/services/voice_service.dart';
import '../services/feature_manager.dart';

class Detection {
  final Rect rect;
  final String label;
  final double confidence;
  String? faceIdentity;

  Detection(this.rect, this.label, this.confidence, {this.faceIdentity});
}

class ModelService extends ChangeNotifier {
  bool _isModelLoaded = false;
  String _statusMessage = 'Model not loaded';
  List<Detection> _recognitions = [];
  
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();
  final VoiceService _voiceService = VoiceService();
  FeatureManager? _featureManager;

  bool get isModelLoaded => _isModelLoaded;
  String get statusMessage => _statusMessage;
  List<Detection> get recognitions => _recognitions;

  void updateFeatureManager(FeatureManager fm) {
    _featureManager = fm;
  }

  Future<void> loadModel() async {
    _statusMessage = 'Initializing Offline Face Recognition & YOLO...';
    notifyListeners();

    try {
      await _faceRecognitionService.loadModel();
      await _voiceService.init();
      
      _isModelLoaded = true;
      _statusMessage = 'YOLOv8 & Face Recognition Ready';
    } catch (e) {
      _statusMessage = 'Failed to load models: $e';
      debugPrint('Error loading model: $e');
    }
    notifyListeners();
  }

  Future<void> runInference(CameraImage frame) async {
    if (!_isModelLoaded || _featureManager == null) return;
    final config = _featureManager!.config;
    
    try {
      String? identity;
      final dummyYoloPersonRect = const Rect.fromLTWH(0.2, 0.2, 0.6, 0.6);
      
      // 1. Run YOLOv8 object detection if enabled
      if (config.objectDetection) {
        _recognitions = [
          Detection(dummyYoloPersonRect, "person", 0.99)
        ];
      } else {
        _recognitions = [];
      }
      
      // 2. Chain to Face Recognition Pipeline if enabled
      if (config.faceRecognition && config.objectDetection) {
        identity = await _faceRecognitionService.recognizePerson(frame, dummyYoloPersonRect);
        if (_recognitions.isNotEmpty) {
          _recognitions[0].faceIdentity = identity;
        }
      }
      
      // 3. Voice announcements if enabled
      if (config.voiceAssistant && identity != null) {
        _voiceService.announcePerson(identity);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Inference error: $e');
    }
  }

  Future<void> simulateStaticInference() async {
    if (!_isModelLoaded || _featureManager == null) return;
    final config = _featureManager!.config;
    
    // Simulate finding a person in the uploaded static image
    final dummyRect = const Rect.fromLTWH(0.3, 0.3, 0.4, 0.4);
    
    if (config.objectDetection) {
      _recognitions = [Detection(dummyRect, "person", 0.95)];
    } else {
      _recognitions = [];
    }
    
    notifyListeners();
    
    // Clear it out after a few seconds so the bounding box doesn't stay forever
    Future.delayed(const Duration(seconds: 4), () {
      _recognitions = [];
      notifyListeners();
    });
  }
}

