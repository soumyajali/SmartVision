import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supported_languages.dart';
import '../../services/camera_service.dart';
import '../../services/database_service.dart';
import '../../services/on_device_ai_service.dart';
import '../../services/speech_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Hindi';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final saved = await context
          .read<DatabaseService>()
          .getAppSetting('translation_language');
      if (saved != null &&
          supportedTranslationLanguages.contains(saved) &&
          mounted) {
        setState(() => _selectedLanguage = saved);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load language preference: $error')),
        );
      }
    }
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _selectedLanguage = language);
    try {
      await context
          .read<DatabaseService>()
          .setAppSetting('translation_language', language);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save language preference: $error')),
      );
    }
  }

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
          _buildSectionHeader(
              'Voice & Audio Telemetry', Icons.record_voice_over_rounded),
          const SizedBox(height: 10),
          _buildVoiceSettingsCard(context),
          const SizedBox(height: 24),

          // 2. Detection & Inference Engine Section
          _buildSectionHeader(
              'Neural Perception Engine', Icons.model_training_rounded),
          const SizedBox(height: 10),
          _buildDetectionSettingsCard(context),
          const SizedBox(height: 24),

          _buildLanguageSettingsCard(),
          const SizedBox(height: 24),

          // 3. On-device AI section
          _buildSectionHeader('On-device AI', Icons.phone_android_rounded),
          const SizedBox(height: 10),
          _buildOnDeviceModelCard(),
          const SizedBox(height: 24),

          // 4. Database & Storage Management
          _buildSectionHeader('Storage & Audit Records', Icons.storage_rounded),
          const SizedBox(height: 10),
          _buildStorageCard(context),
          const SizedBox(height: 24),

          // 4. Hardware & System Status
          _buildSectionHeader('Device & Camera Permissions',
              Icons.perm_device_information_rounded),
          const SizedBox(height: 10),
          _buildSystemCard(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLanguageSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferred Translation Language',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Saved locally and used by OCR translation',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: AppColors.elevatedSurface,
            items: supportedTranslationLanguages
                .map((language) => DropdownMenuItem(
                      value: language,
                      child: Text(language),
                    ))
                .toList(),
            onChanged: (language) {
              if (language != null) _setLanguage(language);
            },
          ),
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
                title: const Text('Voice Announcements',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryText)),
                subtitle: const Text(
                    'Announce detected objects and threats via text-to-speech',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.secondaryText)),
                value: settings.enabled,
                activeTrackColor: AppColors.neonAccent,
                onChanged: (val) {
                  speechService.toggleVoice(val);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (settings.enabled
                            ? AppColors.neonAccent
                            : AppColors.mutedText)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    settings.enabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: settings.enabled
                        ? AppColors.neonAccent
                        : AppColors.mutedText,
                    size: 20,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speech Rate',
                            style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text('${(settings.speechRate * 100).toInt()}%',
                            style: const TextStyle(
                                color: AppColors.brightViolet,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    Slider(
                      value: settings.speechRate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: settings.enabled
                          ? (val) {
                              speechService.updateSettings(
                                  settings.copyWith(speechRate: val));
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speech Volume',
                            style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text('${(settings.volume * 100).toInt()}%',
                            style: const TextStyle(
                                color: AppColors.brightViolet,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    Slider(
                      value: settings.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: settings.enabled
                          ? (val) {
                              speechService.updateSettings(
                                  settings.copyWith(volume: val));
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      onPressed: settings.enabled
                          ? () => speechService.speak(
                              'SmartVision audio notification test successful.')
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Test Voice Output',
                          style: TextStyle(fontSize: 12)),
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
        final currentIou = controller.settings.iouThreshold;
        final currentMaxDetections = controller.settings.maximumDetections;

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
                      Text('Confidence Filter Threshold',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primaryText)),
                      SizedBox(height: 2),
                      Text('Detections below this score are filtered out',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${(currentConfidence * 100).toInt()}%',
                      style: const TextStyle(
                          color: AppColors.neonAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
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
                  controller.updateSettings(
                      controller.settings.copyWith(minimumConfidence: val));
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IoU / NMS Threshold',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primaryText)),
                      SizedBox(height: 2),
                      Text('Controls overlap suppression in YOLO inference',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ),
                  Text('${(currentIou * 100).round()}%',
                      style: const TextStyle(
                          color: AppColors.neonAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: currentIou,
                min: 0.10,
                max: 0.90,
                divisions: 16,
                onChanged: (value) {
                  controller.updateSettings(
                      controller.settings.copyWith(iouThreshold: value));
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Maximum Detections',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryText)),
                        SizedBox(height: 2),
                        Text('Maximum boxes requested per analyzed frame',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: currentMaxDetections,
                    dropdownColor: AppColors.elevatedSurface,
                    items: const [10, 25, 50, 100, 200]
                        .map((value) => DropdownMenuItem(
                            value: value, child: Text('$value')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateSettings(controller.settings
                            .copyWith(maximumDetections: value));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.cloud_outlined,
                      size: 16, color: AppColors.brightViolet),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inference runs locally with the bundled YOLOv8n TFLite model. Images are not sent to a server.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ),
                ],
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
                  Text('SQLite Local Database',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primaryText)),
                  SizedBox(height: 2),
                  Text('On-device persistent event records',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.secondaryText)),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardBackground,
                      title: const Text('Purge Database',
                          style: TextStyle(color: AppColors.primaryText)),
                      content: const Text(
                          'Clear all detection and media-analysis entries from local SQLite storage?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          onPressed: () {
                            context.read<DatabaseService>().clearHistory();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Database history cleared successfully')),
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
                      const Text('Camera Optical Sensor',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primaryText)),
                      const SizedBox(height: 2),
                      Text(
                        isGranted
                            ? 'Permission Granted • Ready'
                            : 'Permission Required',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isGranted ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6)),
                    onPressed: isGranted
                        ? cameraService.switchCamera
                        : openAppSettings,
                    child: Text(isGranted ? 'Flip Cam' : 'Open Settings',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnDeviceModelCard() {
    return Consumer<OnDeviceAiService>(
      builder: (context, ai, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ai.modelName,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ai.modelError ??
                  (ai.isModelLoaded
                      ? 'Ready. Images are analyzed on this device.'
                      : ai.isLoading
                          ? 'Loading the bundled model…'
                          : 'Model is not ready.'),
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
            if (!ai.isModelLoaded && !ai.isLoading)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: ai.initialize,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry loading'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
