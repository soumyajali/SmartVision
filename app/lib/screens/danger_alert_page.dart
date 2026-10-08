import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../face_recognition/services/voice_service.dart';

class DangerAlertPage extends StatefulWidget {
  const DangerAlertPage({super.key});

  @override
  State<DangerAlertPage> createState() => _DangerAlertPageState();
}

class _DangerAlertPageState extends State<DangerAlertPage> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  bool _sirenActive = false;
  bool _threatDetected = true;
  String _detectedThreat = 'Knife';
  double _threatConfidence = 0.92;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _hazardLogs = [
    {'time': '22:14:08', 'type': 'Knife', 'confidence': '92%', 'location': 'Main View', 'severity': 'HIGH'},
    {'time': '21:45:20', 'type': 'Scissors', 'confidence': '85%', 'location': 'Desk Area', 'severity': 'MEDIUM'},
    {'time': '18:12:05', 'type': 'Fire / Smoke', 'confidence': '89%', 'location': 'Kitchen Zone', 'severity': 'CRITICAL'},
    {'time': '14:02:11', 'type': 'Gas Cylinder', 'confidence': '94%', 'location': 'Storage Bay', 'severity': 'HIGH'},
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
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
    setState(() => _sirenActive = !_sirenActive);
    if (_sirenActive) {
      _voiceService.announceDanger(_detectedThreat);
    } else {
      _voiceService.speak("Alarm silenced.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Text('HAZARD GUARD', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Danger & Hazard Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Threat Banner (Matching Streamlit error banner)
          if (_threatDetected)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glow = _sirenActive ? _pulseController.value : 0.4;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15 + (glow * 0.15)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.6 + (glow * 0.4)), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(glow * 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CRITICAL THREAT DETECTED!',
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Dangerous Object: $_detectedThreat (${(_threatConfidence * 100).toInt()}% confidence)',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _sirenActive ? Colors.orange : Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _triggerSirenAlarm,
                              icon: Icon(_sirenActive ? Icons.volume_off : Icons.campaign, size: 20),
                              label: Text(_sirenActive ? 'SILENCE SIREN' : 'SOUND SIREN ALARM', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF21262D)),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () {
                              setState(() => _threatDetected = !_threatDetected);
                            },
                            tooltip: 'Toggle Demo Status',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Monitored Hazards Grid
          const Text('Monitored Dangerous Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildHazardChip('🔪 Knife / Blade', true),
              const SizedBox(width: 8),
              _buildHazardChip('✂️ Scissors', false),
              const SizedBox(width: 8),
              _buildHazardChip('🔥 Fire / Flame', false),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildHazardChip('🔫 Gun / Firearm', false),
              const SizedBox(width: 8),
              _buildHazardChip('🛢️ Gas Cylinder', false),
            ],
          ),

          const SizedBox(height: 24),

          // Emergency Actions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emergency Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dispatched security alert notification via Telegram & Email')),
                          );
                        },
                        icon: const Icon(Icons.notifications_active, color: Colors.orangeAccent),
                        label: const Text('Broadcast Alert'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          _voiceService.speak("Calling emergency hotline.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Emergency hotline triggered')),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Security'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Incident Log History Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Recent Threat Incidents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Auto-saved to SQLite', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: _hazardLogs.map((log) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: log['severity'] == 'CRITICAL'
                          ? Colors.red.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning,
                      color: log['severity'] == 'CRITICAL' ? Colors.redAccent : Colors.orangeAccent,
                      size: 18,
                    ),
                  ),
                  title: Text(log['type'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${log['location']} • ${log['time']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log['confidence'],
                      style: const TextStyle(color: Color(0xFF00FFC2), fontSize: 12, fontWeight: FontWeight.bold),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isTriggered ? Colors.red.withOpacity(0.2) : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isTriggered ? Colors.redAccent : Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isTriggered ? Colors.redAccent : Colors.white70,
              fontSize: 11,
              fontWeight: isTriggered ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
