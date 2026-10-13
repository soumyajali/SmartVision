import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/detection_settings.dart';
import '../../services/camera_service.dart';
import '../../services/database_service.dart';
import '../../services/speech_service.dart';
import '../../services/tflite_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('System Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Voice & Speech Synthesis Section
          _buildSectionHeader('Voice & Audio Telemetry', Icons.record_voice_over_rounded),
          const SizedBox(height: 10),
          _buildVoiceSettingsCard(context),
          const SizedBox(height: 24),

          // 2. Detection & Inference Engine Section
          _buildSectionHeader('Neural Perception Engine', Icons.model_training_rounded),
          const SizedBox(height: 10),
          _buildDetectionSettingsCard(context),
          const SizedBox(height: 24),

          // 3. Database & Storage Management
          _buildSectionHeader('Storage & Audit Records', Icons.storage_rounded),
          const SizedBox(height: 10),
          _buildStorageCard(context),
          const SizedBox(height: 24),

          // 4. Hardware & System Status
          _buildSectionHeader('Device & Camera Permissions', Icons.perm_device_information_rounded),
          const SizedBox(height: 10),
          _buildSystemCard(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonAccent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSettingsCard(BuildContext context) {
    return Consumer<SpeechService>(
      builder: (context, speechService, child) {
        final settings = speechService.settings;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Voice Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText)),
                subtitle: const Text('Announce detected objects and threats via text-to-speech', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                value: settings.enabled,
                activeTrackColor: AppColors.neonAccent,
                onChanged: (val) {
                  speechService.toggleVoice(val);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (settings.enabled ? AppColors.neonAccent : AppColors.mutedText).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    settings.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: settings.enabled ? AppColors.neonAccent : AppColors.mutedText,
                    size: 20,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speech Rate', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${(settings.speechRate * 100).toInt()}%', style: const TextStyle(color: AppColors.brightViolet, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    Slider(
                      value: settings.speechRate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: settings.enabled
                          ? (val) {
                              speechService.updateSettings(settings.copyWith(speechRate: val));
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speech Volume', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${(settings.volume * 100).toInt()}%', style: const TextStyle(color: AppColors.brightViolet, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    Slider(
                      value: settings.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: settings.enabled
                          ? (val) {
                              speechService.updateSettings(settings.copyWith(volume: val));
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: settings.enabled
                          ? () => speechService.speak('SmartVision audio notification test successful.')
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Test Voice Output', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetectionSettingsCard(BuildContext context) {
    return Consumer<DetectionController>(
      builder: (context, controller, child) {
        final currentConfidence = controller.settings.minimumConfidence;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confidence Filter Threshold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText)),
                      SizedBox(height: 2),
                      Text('Detections below this score are filtered out', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${(currentConfidence * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.neonAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: currentConfidence,
                min: 0.20,
                max: 0.90,
                divisions: 14,
                onChanged: (val) {
                  controller.updateSettings(DetectionSettings(minimumConfidence: val));
                },
              ),
              const SizedBox(height: 8),
              Consumer<TFLiteService>(
                builder: (context, tflite, child) {
                  return Row(
                    children: [
                      Icon(
                        tflite.isInitialized ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 16,
                        color: tflite.isInitialized ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COCO Class Labels: ${tflite.labels.length} classes loaded',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorageCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SQLite Local Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText)),
                  SizedBox(height: 2),
                  Text('On-device persistent event records', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardBackground,
                      title: const Text('Purge Database', style: TextStyle(color: AppColors.primaryText)),
                      content: const Text('Clear all historical detection entries from SQLite storage?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () {
                            context.read<DatabaseService>().clearHistory();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Database history cleared successfully')),
                            );
                          },
                          child: const Text('Confirm Purge'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                label: const Text('Purge All', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context) {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        final perm = cameraService.permissionStatus;
        final isGranted = perm == CameraPermissionStatus.granted;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Camera Optical Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText)),
                      const SizedBox(height: 2),
                      Text(
                        isGranted ? 'Permission Granted • Ready' : 'Permission Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: isGranted ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    onPressed: isGranted ? cameraService.switchCamera : openAppSettings,
                    child: Text(isGranted ? 'Flip Cam' : 'Open Settings', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
