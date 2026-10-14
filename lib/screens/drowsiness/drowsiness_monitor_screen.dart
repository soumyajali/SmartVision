import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../services/camera_service.dart';
import '../../services/database_service.dart';
import '../../services/on_device_ai_service.dart';
import '../../services/speech_service.dart';
import '../../widgets/camera_preview_widget.dart';

class DrowsinessMonitorScreen extends StatefulWidget {
  const DrowsinessMonitorScreen({super.key});

  @override
  State<DrowsinessMonitorScreen> createState() =>
      _DrowsinessMonitorScreenState();
}

class _DrowsinessMonitorScreenState extends State<DrowsinessMonitorScreen> {
  final OnDeviceAiService _aiService = OnDeviceAiService.instance;
  bool _isMonitoring = false;
  bool _isAnalyzingVideo = false;
  bool _requestInProgress = false;
  double _closedEyeThreshold = 0.25;
  int _consecutiveFrames = 15;
  String? _error;
  Map<String, dynamic>? _liveResult;
  Map<String, dynamic>? _videoResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CameraService>().initialize();
    });
  }

  @override
  void dispose() {
    _isMonitoring = false;
    super.dispose();
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      setState(() {
        _isMonitoring = false;
      });
      return;
    }
    final camera = context.read<CameraService>();
    if (!camera.isInitialized || camera.controller == null) {
      setState(
          () => _error = 'Camera is not ready. Grant camera access and retry.');
      return;
    }
    setState(() {
      _error = null;
      _liveResult = null;
      _isMonitoring = true;
    });
    _aiService.resetDrowsinessSession();
    await _monitorFrames();
  }

  Future<void> _monitorFrames() async {
    final speechService = context.read<SpeechService>();
    final camera = context.read<CameraService>();
    while (_isMonitoring && mounted) {
      if (!_requestInProgress) {
        _requestInProgress = true;
        try {
          final file = await camera.controller!.takePicture();
          final bytes = await file.readAsBytes();
          await File(file.path).delete();
          final result = await _aiService.analyzeDrowsinessImage(
            bytes,
            closedEyeProbabilityThreshold: _closedEyeThreshold,
            consecutiveFrames: _consecutiveFrames,
          );
          if (!mounted) return;
          final wasDrowsy = _liveResult?['drowsy'] == true;
          setState(() {
            _liveResult = result;
            _error = null;
          });
          if (result['drowsy'] == true && !wasDrowsy) {
            await speechService.speak('Drowsiness alert. Please take a break.');
          }
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _error = 'Live drowsiness analysis failed: $error';
            _isMonitoring = false;
          });
        } finally {
          _requestInProgress = false;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _analyzeVideo(ImageSource source) async {
    if (_isAnalyzingVideo) return;
    final database = context.read<DatabaseService>();
    try {
      final video = await ImagePicker().pickVideo(source: source);
      if (video == null || !mounted) return;
      setState(() {
        _isAnalyzingVideo = true;
        _videoResult = null;
        _error = null;
      });
      final result = await _aiService.analyzeDrowsinessVideo(
        path: video.path,
        closedEyeProbabilityThreshold: _closedEyeThreshold,
        consecutiveFrames: _consecutiveFrames,
      );
      try {
        await database.insertAnalysisHistory(
          analysisType: 'Drowsiness Video',
          summary: '${result['total_incidents'] ?? 0} drowsiness alert(s)',
          details: {'video': video.name, ...result},
        );
      } catch (storageError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Analysis completed, but history save failed: $storageError')),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _videoResult = result;
        _isAnalyzingVideo = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingVideo = false;
        _error = 'Video drowsiness analysis failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(title: const Text('Drowsiness Monitoring')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPrivacyNotice(),
          const SizedBox(height: 12),
          _buildLivePanel(),
          const SizedBox(height: 12),
          _buildThresholdControls(),
          const SizedBox(height: 12),
          _buildVideoPanel(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.elevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Eye-open probabilities are measured on this device with the platform face detector. Images and videos are not uploaded; drowsiness monitoring does not identify or register faces.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      );

  Widget _buildLivePanel() {
    return Consumer<CameraService>(
      builder: (context, camera, _) {
        final cameraController = camera.controller;
        final ready = camera.isInitialized &&
            cameraController != null &&
            cameraController.value.isInitialized;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (ready)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: CameraPreviewWidget(controller: cameraController),
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      camera.initializationError ??
                          'Waiting for camera permission and initialization…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                ),
              if (!ready &&
                  camera.permissionStatus == CameraPermissionStatus.denied)
                TextButton.icon(
                  onPressed: camera.requestPermission,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Grant camera access'),
                ),
              if (!ready &&
                  camera.permissionStatus ==
                      CameraPermissionStatus.permanentlyDenied)
                const Text(
                  'Camera access is blocked. Enable it in the device app settings.',
                  style: TextStyle(color: AppColors.warning),
                  textAlign: TextAlign.center,
                ),
              if (!ready && camera.initializationError != null)
                TextButton.icon(
                  onPressed: camera.initialize,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry camera access'),
                ),
              const SizedBox(height: 12),
              if (_liveResult != null) _buildLiveResult(_liveResult!),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ready ? _toggleMonitoring : null,
                  icon: Icon(
                    _isMonitoring ? Icons.stop_circle_outlined : Icons.radar,
                  ),
                  label: Text(
                    _isMonitoring
                        ? 'Stop Live Monitoring'
                        : 'Start Live Monitoring',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveResult(Map<String, dynamic> result) {
    final drowsy = result['drowsy'] == true;
    final faceDetected = result['face_detected'] == true;
    final eyeOpenProbability =
        (result['eye_open_probability'] as num?)?.toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (drowsy ? AppColors.error : AppColors.elevatedSurface)
            .withValues(alpha: drowsy ? 0.16 : 1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: drowsy ? AppColors.error : AppColors.border),
      ),
      child: Text(
        '${drowsy ? 'DROWSINESS ALERT' : faceDetected ? 'Monitoring' : 'No face detected'}'
        '${eyeOpenProbability == null ? '' : ' · Eye-open probability ${eyeOpenProbability.toStringAsFixed(2)}'}'
        ' · Closed frames ${result['closed_frames'] ?? 0}'
        ' · Alerts ${result['incidents'] ?? 0}',
        style: TextStyle(
          color: drowsy ? AppColors.error : AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThresholdControls() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Closed-eye probability threshold',
                  style: TextStyle(color: AppColors.primaryText),
                ),
                Text(
                  _closedEyeThreshold.toStringAsFixed(2),
                  style: const TextStyle(color: AppColors.neonAccent),
                ),
              ],
            ),
            Slider(
              value: _closedEyeThreshold,
              min: 0.1,
              max: 0.6,
              divisions: 20,
              onChanged: _isMonitoring
                  ? null
                  : (value) => setState(() => _closedEyeThreshold = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Consecutive closed-eye frames',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                ),
                DropdownButton<int>(
                  value: _consecutiveFrames,
                  dropdownColor: AppColors.elevatedSurface,
                  items: const [5, 10, 15, 20, 30, 50]
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ))
                      .toList(),
                  onChanged: _isMonitoring
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _consecutiveFrames = value);
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildVideoPanel() {
    final result = _videoResult;
    final incidents = result?['incidents'] as List? ?? const [];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyze a Recorded Video',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isAnalyzingVideo
                ? null
                : () => _analyzeVideo(ImageSource.gallery),
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Choose video'),
          ),
          OutlinedButton.icon(
            onPressed: _isAnalyzingVideo
                ? null
                : () => _analyzeVideo(ImageSource.camera),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Record video'),
          ),
          if (_isAnalyzingVideo)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.neonAccent),
              ),
            ),
          if (result != null) ...[
            Text(
              'Analyzed ${result['frames_analyzed'] ?? 0} frames · ${result['total_incidents'] ?? incidents.length} alert(s)',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            for (final item in incidents)
              if (item is Map)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Drowsiness alert at ${item['timestamp'] ?? 'unknown time'}',
                    style: const TextStyle(color: AppColors.primaryText),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
