import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../services/camera_service.dart';
import '../../services/speech_service.dart';
import '../../widgets/camera_preview_widget.dart';
import '../../widgets/control_button.dart';
import '../../widgets/detection_overlay.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CameraService>().initialize();
      }
    });
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

    if (state == AppLifecycleState.resumed) {
      cameraService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraService>(
        builder: (context, cameraService, child) {
          if (cameraService.permissionStatus ==
              CameraPermissionStatus.undetermined) {
            return _buildLoadingScreen('Requesting camera access...');
          }

          if (cameraService.permissionStatus == CameraPermissionStatus.denied) {
            return _buildPermissionDenied(cameraService);
          }

          if (cameraService.permissionStatus ==
              CameraPermissionStatus.permanentlyDenied) {
            return _buildPermissionPermanentlyDenied();
          }

          if (!cameraService.isInitialized ||
              cameraService.controller == null) {
            if (cameraService.initializationError != null) {
              return _buildCameraErrorScreen(
                cameraService,
                cameraService.initializationError!,
              );
            }
            return _buildLoadingScreen(
                'Initializing camera optical pipeline...');
          }

          final screenSize = MediaQuery.of(context).size;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Preview (Maintains real camera sensor feed)
              CameraPreviewWidget(controller: cameraService.controller!),

              // 2. Real-time Bounding Box Overlay (Rebuilt only when detections change)
              Consumer<DetectionController>(
                builder: (context, detectionCtrl, child) {
                  return DetectionOverlay(
                    detections: detectionCtrl.isDetecting
                        ? detectionCtrl.currentResults
                        : const [],
                    screenSize: screenSize,
                  );
                },
              ),

              // 3. Top Status & Quick Action Bar
              _buildTopBar(context, cameraService),

              Consumer<DetectionController>(
                builder: (context, detectionCtrl, child) {
                  final error = detectionCtrl.lastAnalysisError;
                  if (error == null) return const SizedBox.shrink();
                  return Positioned(
                    top: 76,
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Detection stopped: $error',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 4. Live Detections Horizontal Chips HUD
              _buildLiveDetectionsChipHUD(),

              // 5. Bottom Floating Control Panel
              _buildBottomControls(context, cameraService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Container(
      color: AppColors.primaryBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryViolet.withValues(alpha: 0.3)),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.neonAccent),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraErrorScreen(
    CameraService cameraService,
    String error,
  ) {
    return Container(
      color: AppColors.primaryBackground,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera could not be initialized',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: cameraService.initialize,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry camera access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, CameraService cameraService) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              ControlButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Exit Camera',
                onPressed: () {
                  final detectionCtrl = context.read<DetectionController>();
                  if (detectionCtrl.isDetecting) {
                    detectionCtrl.toggleDetection();
                  }
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),

              // Center Detection Status Pill
              Consumer<DetectionController>(
                builder: (context, controller, child) {
                  final isDetecting = controller.isDetecting;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDetecting
                            ? AppColors.neonAccent
                            : AppColors.border,
                        width: 1.2,
                      ),
                      boxShadow: [
                        if (isDetecting)
                          BoxShadow(
                            color: AppColors.neonAccent.withValues(alpha: 0.25),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDetecting
                                ? AppColors.neonAccent
                                : AppColors.mutedText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDetecting ? 'AI TRACKING' : 'STANDBY',
                          style: TextStyle(
                            color: isDetecting
                                ? AppColors.neonAccent
                                : AppColors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Right Actions: TTS Speech Toggle & Flash
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<SpeechService>(
                    builder: (context, speechService, child) {
                      final enabled = speechService.settings.enabled;
                      return ControlButton(
                        icon: enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        isActive: enabled,
                        tooltip: enabled
                            ? 'Voice announcements ON'
                            : 'Voice announcements OFF',
                        onPressed: () => speechService.toggleVoice(!enabled),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ControlButton(
                    icon: cameraService.isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    isActive: cameraService.isFlashOn,
                    tooltip: 'Toggle Flash Torch',
                    onPressed: cameraService.toggleFlash,
                  ),
                  const SizedBox(width: 8),
                  ControlButton(
                    icon: Icons.flip_camera_ios_rounded,
                    tooltip: 'Switch Camera',
                    onPressed: cameraService.switchCamera,
                  ),
                  const SizedBox(width: 8),
                  ControlButton(
                    icon: Icons.photo_library_rounded,
                    tooltip: 'Analyze Image from Gallery',
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          if (context.mounted) {
                            await context
                                .read<DetectionController>()
                                .analyzeImageBytes(bytes);
                          }
                        }
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveDetectionsChipHUD() {
    return Positioned(
      top: 75,
      left: 16,
      right: 16,
      child: Consumer<DetectionController>(
        builder: (context, controller, child) {
          final results = controller.currentResults;
          if (!controller.isDetecting &&
              !controller.hasActiveHazard &&
              controller.searchTarget == null) {
            return const SizedBox.shrink();
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.hasActiveHazard)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '🚨 SAFETY ALERT: ${controller.activeHazardLabel?.toUpperCase()} DETECTED',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (controller.searchTarget != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.isTargetFound
                        ? const Color(0xFF00E676).withValues(alpha: 0.9)
                        : AppColors.cardBackground.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.isTargetFound
                          ? const Color(0xFF00E676)
                          : AppColors.neonAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isTargetFound
                            ? Icons.check_circle_rounded
                            : Icons.radar_rounded,
                        color: controller.isTargetFound
                            ? Colors.black
                            : AppColors.neonAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isTargetFound
                            ? 'TARGET FOUND: "${controller.searchTarget!.toUpperCase()}" IN VIEW'
                            : 'SEARCHING FOR: "${controller.searchTarget!.toUpperCase()}"...',
                        style: TextStyle(
                          color: controller.isTargetFound
                              ? Colors.black
                              : AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (controller.isDetecting && results.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final r = results[idx];
                      final conf = (r.confidence * 100).toStringAsFixed(0);
                      final distStr = r.distanceM != null
                          ? ' • ${r.distanceM!.toStringAsFixed(1)}m'
                          : '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: r.isHazard
                              ? const Color(0xFFFF1744).withValues(alpha: 0.25)
                              : AppColors.cardBackground
                                  .withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: r.isHazard
                                ? const Color(0xFFFF1744)
                                : AppColors.neonAccent.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              r.isHazard
                                  ? Icons.warning_rounded
                                  : Icons.blur_on_rounded,
                              size: 14,
                              color: r.isHazard
                                  ? const Color(0xFFFF8A80)
                                  : AppColors.neonAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${r.label.toUpperCase()} $conf%$distStr',
                              style: TextStyle(
                                color: r.isHazard
                                    ? const Color(0xFFFF8A80)
                                    : AppColors.primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, CameraService cameraService) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom Level Slider
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out_rounded,
                        color: AppColors.secondaryText, size: 18),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          activeTrackColor: AppColors.neonAccent,
                          inactiveTrackColor:
                              AppColors.primaryViolet.withValues(alpha: 0.25),
                          thumbColor: AppColors.neonAccent,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayColor:
                              AppColors.neonAccent.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: cameraService.currentZoomLevel,
                          min: cameraService.minZoomLevel,
                          max: cameraService.maxZoomLevel,
                          onChanged: (value) =>
                              cameraService.setZoomLevel(value),
                        ),
                      ),
                    ),
                    const Icon(Icons.zoom_in_rounded,
                        color: AppColors.secondaryText, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${cameraService.currentZoomLevel.toStringAsFixed(1)}x',
                      style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Futuristic Central Trigger Control
              Consumer<DetectionController>(
                builder: (context, controller, child) {
                  final isDetecting = controller.isDetecting;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: controller.toggleDetection,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDetecting
                                  ? [AppColors.error, const Color(0xFFDC2626)]
                                  : [
                                      AppColors.primaryViolet,
                                      AppColors.deepViolet
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isDetecting
                                  ? AppColors.error
                                  : AppColors.neonAccent,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDetecting
                                        ? AppColors.error
                                        : AppColors.neonAccent)
                                    .withValues(alpha: 0.45),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isDetecting
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // Label under button
              Consumer<DetectionController>(
                builder: (context, controller, child) {
                  return Text(
                    controller.isDetecting
                        ? 'TAP TO STOP DETECTION'
                        : 'TAP TO START DETECTION',
                    style: TextStyle(
                      color: controller.isDetecting
                          ? AppColors.error
                          : AppColors.brightViolet,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(CameraService cameraService) {
    return Container(
      color: AppColors.primaryBackground,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  size: 56, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'SmartVision requires access to your camera to detect and classify objects in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: cameraService.requestPermission,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Grant Camera Access'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Use Dashboard with Sample Scenes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPermanentlyDenied() {
    return Container(
      color: AppColors.primaryBackground,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_photography_outlined,
                  size: 56, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              'Permission Permanently Denied',
              style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera permission is permanently denied on this device. Please open application settings to allow camera permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open System Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
