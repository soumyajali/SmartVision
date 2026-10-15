import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../models/detection_history.dart';
import '../models/detection_result.dart';
import '../models/detection_settings.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';
import '../services/on_device_ai_service.dart';
import '../services/speech_service.dart';

class DetectionController extends ChangeNotifier {
  final CameraService _cameraService;
  final SpeechService _speechService;
  final DatabaseService _databaseService;
  final OnDeviceAiService _aiService = OnDeviceAiService.instance;

  bool _isDetecting = false;
  bool _isProcessingFrame = false;
  String? _lastAnalysisError;

  // Search mode & Target tracking
  String? _searchTarget;
  bool _isTargetFound = false;

  // Hazard / Threat Sentinel
  bool _hasActiveHazard = false;
  String? _activeHazardLabel;

  List<DetectionResult> _currentResults = [];
  final Map<String, int> _objectCounts = {};
  int _totalDetectionsCount = 0;

  bool get isDetecting => _isDetecting;
  bool get isProcessingFrame => _isProcessingFrame;
  String? get lastAnalysisError => _lastAnalysisError;
  List<DetectionResult> get currentResults => _currentResults;
  Map<String, int> get objectCounts => Map.unmodifiable(_objectCounts);
  int get totalDetectionsCount => _totalDetectionsCount;
  String? get searchTarget => _searchTarget;
  bool get isTargetFound => _isTargetFound;
  bool get hasActiveHazard => _hasActiveHazard;
  String? get activeHazardLabel => _activeHazardLabel;

  // Voice Announcement Cooldown
  final Map<String, DateTime> _lastAnnouncedObjects = {};
  final Duration announcementCooldown = const Duration(seconds: 4);

  // Database Save Cooldown
  final Map<String, DateTime> _lastSavedObjects = {};
  final Duration databaseSaveCooldown = const Duration(seconds: 8);

  DetectionSettings _settings = const DetectionSettings();
  DetectionSettings get settings => _settings;

  DetectionController(
    this._cameraService,
    this._speechService,
    this._databaseService,
  ) {
    _cameraService.addListener(_onCameraStateChanged);
  }

  void _onCameraStateChanged() {
    if (_cameraService.isInitialized &&
        _cameraService.controller != null &&
        _isDetecting) {
      _startDetectionLoop();
    }
  }

  void updateSettings(DetectionSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  void setSearchTarget(String? target) {
    final clean = target?.trim().toLowerCase();
    if (clean == null || clean.isEmpty) {
      _searchTarget = null;
      _isTargetFound = false;
    } else {
      _searchTarget = clean;
      _isTargetFound = false;
      _speechService.speak('Searching for $_searchTarget');
    }
    notifyListeners();
  }

  void toggleDetection() {
    _isDetecting = !_isDetecting;

    if (_isDetecting) {
      _startDetectionLoop();
    } else {
      _currentResults = [];
      _objectCounts.clear();
      _totalDetectionsCount = 0;
      _isTargetFound = false;
      _hasActiveHazard = false;
      _speechService.stop();
    }

    notifyListeners();
  }

  void _startDetectionLoop() async {
    while (_isDetecting) {
      if (!_isProcessingFrame &&
          _cameraService.isInitialized &&
          _cameraService.controller != null) {
        _isProcessingFrame = true;
        try {
          final xfile = await _cameraService.controller!.takePicture();
          final bytes = await xfile.readAsBytes();
          await analyzeImageBytes(bytes);
        } catch (e) {
          log('Frame capture error: $e');
          _lastAnalysisError = e.toString();
          _isDetecting = false;
          notifyListeners();
        } finally {
          _isProcessingFrame = false;
        }
      }
      await Future.delayed(const Duration(milliseconds: 750));
    }
  }

  /// Analyze a base64 image with the bundled on-device YOLOv8 model.
  Future<List<DetectionResult>> analyzeImageBase64(String base64Image) async {
    return analyzeImageBytes(base64Decode(base64Image));
  }

  /// Analyze raw bytes from a camera capture or selected image.
  Future<List<DetectionResult>> analyzeImageBytes(Uint8List bytes) async {
    _isProcessingFrame = true;
    notifyListeners();

    try {
      final results = await _aiService.detectObjects(
        bytes,
        settings: _settings,
      );

      _lastAnalysisError = null;
      _currentResults = results;
      _updateCountsAndMetrics(results);
      _checkTargetAndHazards(results);
      _announceResults(results);
      _saveResultsToDatabase(results);

      return results;
    } catch (error) {
      _lastAnalysisError = error.toString();
      _currentResults = [];
      _objectCounts.clear();
      _totalDetectionsCount = 0;
      _hasActiveHazard = false;
      _activeHazardLabel = null;
      rethrow;
    } finally {
      _isProcessingFrame = false;
      notifyListeners();
    }
  }

  void _updateCountsAndMetrics(List<DetectionResult> results) {
    _objectCounts.clear();
    for (final r in results) {
      final label = r.label.toLowerCase();
      _objectCounts[label] = (_objectCounts[label] ?? 0) + 1;
    }
    _totalDetectionsCount = results.length;
    // Detection is request/response based; do not present fabricated FPS.
  }

  void _checkTargetAndHazards(List<DetectionResult> results) {
    // 1. Target check
    if (_searchTarget != null && _searchTarget!.isNotEmpty) {
      final match = results
          .where((r) => r.label.toLowerCase().contains(_searchTarget!))
          .firstOrNull;
      if (match != null) {
        if (!_isTargetFound) {
          _isTargetFound = true;
          _speechService
              .speak('Target found! $_searchTarget detected in scene');
        }
      } else {
        _isTargetFound = false;
      }
    }

    // 2. Hazard check (knife, scissors, gun, fire)
    final hazard = results.where((r) => r.isHazard).firstOrNull;
    if (hazard != null) {
      _hasActiveHazard = true;
      _activeHazardLabel = hazard.label;
      final now = DateTime.now();
      final lastAnnounced = _lastAnnouncedObjects['HAZARD_${hazard.label}'];
      if (lastAnnounced == null ||
          now.difference(lastAnnounced) > const Duration(seconds: 3)) {
        _lastAnnouncedObjects['HAZARD_${hazard.label}'] = now;
        _speechService.speak('Caution! Hazard detected: ${hazard.label}');
      }
    } else {
      _hasActiveHazard = false;
      _activeHazardLabel = null;
    }
  }

  void _announceResults(List<DetectionResult> results) {
    if (results.isEmpty) return;

    final now = DateTime.now();
    for (final result in results) {
      final label = result.label;
      final lastTime = _lastAnnouncedObjects[label];

      if (lastTime == null || now.difference(lastTime) > announcementCooldown) {
        _lastAnnouncedObjects[label] = now;
        final distStr = result.distanceM != null
            ? ', ${result.distanceM!.toStringAsFixed(1)} meters away'
            : '';
        _speechService.speak('${result.label}$distStr');
        break; // Announce one prominent object at a time to prevent overlapping speech
      }
    }
  }

  void _saveResultsToDatabase(List<DetectionResult> results) async {
    if (results.isEmpty) return;

    final now = DateTime.now();
    for (final result in results) {
      final label = result.label;
      final lastTime = _lastSavedObjects[label];

      if (lastTime == null || now.difference(lastTime) > databaseSaveCooldown) {
        _lastSavedObjects[label] = now;
        try {
          await _databaseService.insertDetection(
            DetectionHistory(
              objectName: result.label,
              confidence: result.confidence,
              timestamp: now,
              boundingBox: result.boundingBox,
            ),
          );
        } catch (e) {
          log('Error saving detection to SQLite: $e');
        }
      }
    }
  }
}
