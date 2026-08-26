import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controllers/detection_controller.dart';
import '../../services/camera_service.dart';
import '../../services/speech_service.dart';
import '../../services/tflite_service.dart';
import '../../widgets/camera_preview_widget.dart';
import '../../widgets/control_button.dart';
import '../../widgets/detection_overlay.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = context.read<CameraService>();
    final controller = cameraService.controller;
    
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Pause is handled gracefully
    } else if (state == AppLifecycleState.resumed) {
      cameraService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraService>(
        builder: (context, cameraService, child) {
          if (cameraService.permissionStatus == CameraPermissionStatus.undetermined) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cameraService.permissionStatus == CameraPermissionStatus.denied) {
            return _buildPermissionDenied(cameraService);
          }
          
          if (cameraService.permissionStatus == CameraPermissionStatus.permanentlyDenied) {
            return _buildPermissionPermanentlyDenied();
          }

          if (!cameraService.isInitialized || cameraService.controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreviewWidget(controller: cameraService.controller!),
              Consumer<DetectionController>(
                builder: (context, controller, child) {
                  return DetectionOverlay(
                    detections: controller.isDetecting ? controller.currentResults : [],
                    screenSize: MediaQuery.of(context).size,
                  );
                },
              ),
              _buildControls(context, cameraService),
              _buildTopBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ControlButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Consumer<SpeechService>(
                builder: (context, speechService, child) {
                  return ControlButton(
                    icon: speechService.settings.enabled ? Icons.volume_up : Icons.volume_off,
                    isActive: speechService.settings.enabled,
                    onPressed: () {
                      speechService.toggleVoice(!speechService.settings.enabled);
                    },
                  );
                },
              ),
              Consumer<TFLiteService>(
                builder: (context, tfliteService, child) {
                  if (tfliteService.hasError) {
                    return const Icon(Icons.error, color: Colors.red);
                  }
                  if (!tfliteService.isInitialized) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  return const Icon(Icons.check_circle, color: Colors.green);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, CameraService cameraService) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom Slider
              Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white),
                  Expanded(
                    child: Slider(
                      value: cameraService.currentZoomLevel,
                      min: cameraService.minZoomLevel,
                      max: cameraService.maxZoomLevel,
                      onChanged: (value) => cameraService.setZoomLevel(value),
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.white54,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white),
                ],
              ),
              const SizedBox(height: 24),
              // Camera Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ControlButton(
                    icon: cameraService.isFlashOn ? Icons.flash_on : Icons.flash_off,
                    isActive: cameraService.isFlashOn,
                    onPressed: cameraService.toggleFlash,
                  ),
                  // AI Detection Toggle
                  Consumer<DetectionController>(
                    builder: (context, controller, child) {
                      return Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: controller.isDetecting ? Colors.green : Theme.of(context).colorScheme.primary, 
                            width: 4
                          ),
                          color: controller.isDetecting ? Colors.green.withOpacity(0.2) : Colors.white24,
                        ),
                        child: IconButton(
                          icon: Icon(
                            controller.isDetecting ? Icons.stop : Icons.play_arrow, 
                            color: controller.isDetecting ? Colors.green : Theme.of(context).colorScheme.primary, 
                            size: 32
                          ),
                          onPressed: controller.toggleDetection,
                        ),
                      );
                    },
                  ),
                  ControlButton(
                    icon: Icons.flip_camera_ios,
                    onPressed: cameraService.switchCamera,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(CameraService cameraService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Camera permission is required',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: cameraService.requestPermission,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPermanentlyDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'Camera permission is permanently denied.\nPlease enable it in app settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: openAppSettings,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
