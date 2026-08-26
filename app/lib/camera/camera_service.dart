import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:smart_vision/ai/model_service.dart';

class CameraService extends ChangeNotifier {
  bool _isCameraReady = false;
  bool _flashEnabled = false;
  double _zoomLevel = 1.0;
  CameraController? _controller;
  bool _isDetecting = false;

  bool get isCameraReady => _isCameraReady;
  bool get flashEnabled => _flashEnabled;
  double get zoomLevel => _zoomLevel;
  CameraController? get controller => _controller;

  Future<void> initialize({ModelService? modelService}) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isCameraReady = true;
      notifyListeners();

      if (modelService != null && !kIsWeb) {
        _controller!.startImageStream((CameraImage image) {
          if (_isDetecting) return;
          _isDetecting = true;
          
          try {
            modelService.runInference(image);
          } catch (e) {
            debugPrint("Inference error: $e");
          } finally {
            Future.delayed(const Duration(milliseconds: 300), () {
              _isDetecting = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _flashEnabled = !_flashEnabled;
      if (!kIsWeb) {
        await _controller!.setFlashMode(_flashEnabled ? FlashMode.torch : FlashMode.off);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  void setZoom(double value) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _zoomLevel = value.clamp(1.0, 3.0);
      if (!kIsWeb) {
        await _controller!.setZoomLevel(_zoomLevel);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Zoom error: $e');
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
