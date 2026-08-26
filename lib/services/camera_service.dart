import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionStatus { granted, denied, permanentlyDenied, undetermined }

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  
  bool _isInitialized = false;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.undetermined;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  bool _isFlashOn = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  CameraPermissionStatus get permissionStatus => _permissionStatus;
  double get minZoomLevel => _minZoomLevel;
  double get maxZoomLevel => _maxZoomLevel;
  double get currentZoomLevel => _currentZoomLevel;
  bool get isFlashOn => _isFlashOn;

  Future<void> initialize() async {
    await checkPermission();
    if (_permissionStatus == CameraPermissionStatus.granted) {
      await _initCamera();
    }
  }

  Future<void> checkPermission() async {
    final status = await Permission.camera.status;
    _updatePermissionStatus(status);
  }

  Future<void> requestPermission() async {
    final status = await Permission.camera.request();
    _updatePermissionStatus(status);
    if (status.isGranted) {
      await _initCamera();
    }
  }

  void _updatePermissionStatus(PermissionStatus status) {
    if (status.isGranted) {
      _permissionStatus = CameraPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      _permissionStatus = CameraPermissionStatus.permanentlyDenied;
    } else {
      _permissionStatus = CameraPermissionStatus.denied;
    }
    notifyListeners();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        log('No cameras available');
        return;
      }
      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription cameraDescription) async {
    _controller?.dispose();

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      log('Error setting up camera controller: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.isEmpty) return;
    
    _isInitialized = false;
    notifyListeners();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      log('Error toggling flash: $e');
      _isFlashOn = !_isFlashOn; // Revert on error
    }
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.setZoomLevel(zoom);
      _currentZoomLevel = zoom;
      notifyListeners();
    } catch (e) {
      log('Error setting zoom level: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
