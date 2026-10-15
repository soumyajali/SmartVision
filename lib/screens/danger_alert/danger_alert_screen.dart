import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../services/speech_service.dart';

class DangerAlertScreen extends StatefulWidget {
  const DangerAlertScreen({super.key});

  @override
  State<DangerAlertScreen> createState() => _DangerAlertScreenState();
}

class _DangerAlertScreenState extends State<DangerAlertScreen>
    with SingleTickerProviderStateMixin {
  bool _sirenActive = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleThreatAnnouncement(String threatName) {
    final speechService = context.read<SpeechService>();
    if (_sirenActive) {
      speechService.stop();
      setState(() => _sirenActive = false);
    } else {
      setState(() => _sirenActive = true);
      speechService.speak('Warning. Hazard detected: $threatName.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectionCtrl = context.watch<DetectionController>();
    final hazards = detectionCtrl.currentResults
        .where((result) => result.isHazard)
        .toList();
    final activeHazard = hazards.firstOrNull;
    final isThreatActive = activeHazard != null;
    final threatName = activeHazard?.label.toUpperCase() ?? '';
    final threatConfidence = activeHazard?.confidence ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Threat & Hazard Sentinel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Threat Banner with pulsing animation
          if (isThreatActive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glow = _sirenActive ? _pulseController.value : 0.35;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                        AppColors.error.withValues(alpha: 0.12 + (glow * 0.12)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          AppColors.error.withValues(alpha: 0.6 + (glow * 0.4)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: glow * 0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: AppColors.error, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HAZARD DETECTED',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$threatName · ${(threatConfidence * 100).toStringAsFixed(1)}% confidence',
                                  style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _sirenActive
                                    ? AppColors.warning
                                    : AppColors.error,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () =>
                                  _toggleThreatAnnouncement(threatName),
                              icon: Icon(
                                  _sirenActive
                                      ? Icons.stop_circle_outlined
                                      : Icons.campaign_rounded,
                                  size: 20),
                              label: Text(
                                _sirenActive
                                    ? 'STOP ANNOUNCEMENT'
                                    : 'ANNOUNCE HAZARD',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (detectionCtrl.isDetecting
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      detectionCtrl.isDetecting
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: detectionCtrl.isDetecting
                          ? AppColors.success
                          : AppColors.warning,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detectionCtrl.isDetecting
                            ? 'No hazard in latest frame'
                            : 'Monitoring is stopped',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primaryText),
                      ),
                      Text(
                        detectionCtrl.isDetecting
                            ? 'No hazardous detections in the most recent analysis.'
                            : 'Start live detection before relying on hazard monitoring.',
                        style: const TextStyle(
                            color: AppColors.secondaryText, fontSize: 12),
                      ),
                    ],
                  )),
                ],
              ),
            ),

          const SizedBox(height: 20),

          if (!detectionCtrl.isDetecting)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/camera_detection'),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Open live camera detection'),
              ),
            ),

          // Monitored Hazards Categories
          const Text(
            'Hazards in Latest Analysis',
            style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (hazards.isEmpty)
            const Text(
              'No hazard labels are present in the current results.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hazards.map((result) {
                final confidence = (result.confidence * 100).toStringAsFixed(1);
                return _buildHazardChip('${result.label} · $confidence%', true);
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Emergency Dispatch Actions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alert Controls',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                SizedBox(height: 12),
                Text(
                  'This app can announce detected hazards using device text-to-speech. No security dispatch or emergency calling service is configured.',
                  style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Incident Log History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Hazard Results',
                  style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text('${hazards.length} detected',
                  style: const TextStyle(
                      color: AppColors.mutedText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: hazards.isEmpty
                  ? const [
                      ListTile(
                        leading: Icon(Icons.shield_outlined,
                            color: AppColors.mutedText),
                        title: Text('No current hazard results',
                            style: TextStyle(
                                color: AppColors.secondaryText, fontSize: 13)),
                      ),
                    ]
                  : hazards.map((result) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ),
                        title: Text(result.label,
                            style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        subtitle: Text(
                            'Latest analysis · ${(result.confidence * 100).toStringAsFixed(1)}% confidence',
                            style: const TextStyle(
                                color: AppColors.secondaryText, fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${(result.confidence * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: AppColors.neonAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardChip(String label, bool isTriggered) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isTriggered
            ? AppColors.error.withValues(alpha: 0.18)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTriggered ? AppColors.error : AppColors.border,
          width: isTriggered ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isTriggered ? AppColors.error : AppColors.secondaryText,
          fontSize: 12,
          fontWeight: isTriggered ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
