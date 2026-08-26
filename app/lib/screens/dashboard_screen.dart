import 'package:flutter/material.dart';
import '../services/feature_manager.dart';
import 'feature_selection_screen.dart';
import 'camera_detection_screen.dart';

class DashboardScreen extends StatefulWidget {
  final FeatureManager featureManager;

  const DashboardScreen({Key? key, required this.featureManager}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.featureManager.addListener(_onFeatureConfigChanged);
  }

  @override
  void dispose() {
    widget.featureManager.removeListener(_onFeatureConfigChanged);
    super.dispose();
  }

  void _onFeatureConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.featureManager.config;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('SMART VISION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Center(child: Text("See. Understand. Act.", style: TextStyle(color: Colors.grey, fontSize: 16))),
          const SizedBox(height: 24),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildActiveFeaturesCard(config),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF00FFC2),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraDetectionScreen()));
            },
            child: const Text('START SMART SCAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 16),
          _buildQuickModes(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x801A1D24), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SYSTEM STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          _statusRow('Camera', 'READY', Colors.green),
          _statusRow('AI Model', 'READY', Colors.green),
          _statusRow('Backend', 'ONLINE', Colors.green),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x801A1D24), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TODAY'S ACTIVITY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Objects', '128'),
              _statItem('Alerts', '6'),
              _statItem('OCR', '14'),
              _statItem('Faces', '9'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActiveFeaturesCard(config) {
    List<String> active = [];
    if (config.objectDetection) active.add('Detection');
    if (config.objectTracking) active.add('Tracking');
    if (config.ocr) active.add('OCR');
    if (config.faceRecognition) active.add('Face');
    if (config.voiceAssistant) active.add('Voice');
    if (config.alerts) active.add('Alerts');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x801A1D24), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE FEATURES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FeatureSelectionScreen(featureManager: widget.featureManager)));
                },
                child: const Text('EDIT', style: TextStyle(color: Color(0xFF00FFC2))),
              )
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: active.map((f) => Chip(
              label: Text(f),
              backgroundColor: const Color(0xFF00FFC2).withOpacity(0.2),
              side: BorderSide.none,
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildQuickModes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK MODES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(label: const Text('Quick Scan'), onPressed: () => widget.featureManager.applyPreset('Quick Scan')),
            ActionChip(label: const Text('Read Mode'), onPressed: () => widget.featureManager.applyPreset('Read Mode')),
            ActionChip(label: const Text('People Mode'), onPressed: () => widget.featureManager.applyPreset('People Mode')),
            ActionChip(label: const Text('Safety Mode'), onPressed: () => widget.featureManager.applyPreset('Safety Mode')),
          ],
        )
      ],
    );
  }
}
