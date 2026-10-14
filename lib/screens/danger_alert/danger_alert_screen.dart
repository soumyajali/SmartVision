import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../services/speech_service.dart';

class DangerAlertScreen extends StatefulWidget {
  const DangerAlertScreen({super.key});

  @override
  State<DangerAlertScreen> createState() => _DangerAlertScreenState();
}

class _DangerAlertScreenState extends State<DangerAlertScreen> with SingleTickerProviderStateMixin {
  bool _sirenActive = false;
  bool _threatDetected = true;
  final String _detectedThreat = 'Knife';
  final double _threatConfidence = 0.94;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _hazardLogs = [
    {'time': '22:14:08', 'type': 'Knife / Blade', 'confidence': '94%', 'location': 'Main Camera View', 'severity': 'CRITICAL'},
    {'time': '21:45:20', 'type': 'Scissors / Sharp', 'confidence': '85%', 'location': 'Table Surface', 'severity': 'MEDIUM'},
    {'time': '18:12:05', 'type': 'Fire / Smoke', 'confidence': '89%', 'location': 'Hazard Zone B', 'severity': 'CRITICAL'},
    {'time': '14:02:11', 'type': 'Gas Cylinder', 'confidence': '92%', 'location': 'Perimeter Scan', 'severity': 'HIGH'},
  ];

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

  void _triggerSirenAlarm() {
    final speechService = context.read<SpeechService>();
    setState(() => _sirenActive = !_sirenActive);
    if (_sirenActive) {
      speechService.speak('Warning! Critical threat detected: $_detectedThreat. Please take caution immediately.');
    } else {
      speechService.speak('Alarm silenced.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectionCtrl = context.watch<DetectionController>();
    final isThreatActive = detectionCtrl.hasActiveHazard || _threatDetected;
    final threatName = detectionCtrl.activeHazardLabel?.toUpperCase() ?? _detectedThreat;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Threat & Hazard Sentinel'),
        actions: [
          IconButton(
            icon: Icon(isThreatActive ? Icons.security_rounded : Icons.shield_outlined, color: AppColors.neonAccent),
            tooltip: 'Toggle Threat Status',
            onPressed: () {
              setState(() => _threatDetected = !_threatDetected);
            },
          ),
        ],
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
                    color: AppColors.error.withValues(alpha: 0.12 + (glow * 0.12)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.6 + (glow * 0.4)),
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
                            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CRITICAL THREAT DETECTED',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dangerous Object: $threatName (${(_threatConfidence * 100).toInt()}% confidence)',
                                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
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
                                backgroundColor: _sirenActive ? AppColors.warning : AppColors.error,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _triggerSirenAlarm,
                              icon: Icon(_sirenActive ? Icons.volume_off : Icons.campaign_rounded, size: 20),
                              label: Text(
                                _sirenActive ? 'SILENCE SIREN' : 'SOUND SIREN ALARM',
                                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Area Secure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText)),
                      Text('No active hazardous objects detected in feed', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Monitored Hazards Categories
          const Text(
            'Monitored Hazard Categories',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHazardChip('🔪 Knife / Blade', true),
              _buildHazardChip('✂️ Scissors', false),
              _buildHazardChip('🔥 Fire / Flame', false),
              _buildHazardChip('🔫 Weapon / Gun', false),
              _buildHazardChip('🛢️ Gas Cylinder', false),
              _buildHazardChip('⚠️ Suspicious Bag', false),
            ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emergency Protocol', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dispatched security alert broadcast notification')),
                          );
                        },
                        icon: const Icon(Icons.notifications_active_rounded, size: 18),
                        label: const Text('Broadcast Alert'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          context.read<SpeechService>().speak('Connecting emergency security dispatch.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Security response team notified')),
                          );
                        },
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        label: const Text('Call Security'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Incident Log History
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Threat Incidents', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Security Audit Log', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
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
              children: _hazardLogs.map((log) {
                final isCritical = log['severity'] == 'CRITICAL';
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: isCritical ? AppColors.error : AppColors.warning,
                      size: 18,
                    ),
                  ),
                  title: Text(log['type'], style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${log['location']} • ${log['time']}", style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      log['confidence'],
                      style: const TextStyle(color: AppColors.neonAccent, fontSize: 12, fontWeight: FontWeight.bold),
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
        color: isTriggered ? AppColors.error.withValues(alpha: 0.18) : AppColors.cardBackground,
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
