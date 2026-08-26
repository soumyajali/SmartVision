import 'package:flutter/material.dart';
import '../services/feature_manager.dart';
import '../models/feature_configuration.dart';

class FeatureSelectionScreen extends StatefulWidget {
  final FeatureManager featureManager;

  const FeatureSelectionScreen({Key? key, required this.featureManager}) : super(key: key);

  @override
  State<FeatureSelectionScreen> createState() => _FeatureSelectionScreenState();
}

class _FeatureSelectionScreenState extends State<FeatureSelectionScreen> {
  late FeatureConfiguration _config;

  @override
  void initState() {
    super.initState();
    _config = widget.featureManager.config;
  }

  void _updateConfig(FeatureConfiguration newConfig) {
    widget.featureManager.updateConfig(newConfig);
    setState(() {
      _config = widget.featureManager.config; // Reload from manager to get dependency updates
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Selection')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('VISION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          SwitchListTile(
            title: const Text('Object Detection'),
            subtitle: const Text('Detect objects in real time'),
            value: _config.objectDetection,
            onChanged: (val) {
              if (!val && (_config.objectTracking || _config.objectSearch || _config.objectCounting)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot disable: Required by other enabled features (Tracking/Search/Counting)')),
                );
                return;
              }
              _updateConfig(_config.copyWith(objectDetection: val));
            },
          ),
          SwitchListTile(
            title: const Text('Object Tracking'),
            value: _config.objectTracking,
            onChanged: (val) => _updateConfig(_config.copyWith(objectTracking: val)),
          ),
          SwitchListTile(
            title: const Text('OCR'),
            subtitle: const Text('Read text from the camera'),
            value: _config.ocr,
            onChanged: (val) => _updateConfig(_config.copyWith(ocr: val)),
          ),
          SwitchListTile(
            title: const Text('Face Recognition'),
            value: _config.faceRecognition,
            onChanged: (val) => _updateConfig(_config.copyWith(faceRecognition: val)),
          ),
          const Divider(),
          const Text('INTELLIGENCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          SwitchListTile(
            title: const Text('Voice Assistant'),
            value: _config.voiceAssistant,
            onChanged: (val) => _updateConfig(_config.copyWith(voiceAssistant: val)),
          ),
          const Divider(),
          const Text('SAFETY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          SwitchListTile(
            title: const Text('Alerts'),
            value: _config.alerts,
            onChanged: (val) => _updateConfig(_config.copyWith(alerts: val)),
          ),
        ],
      ),
    );
  }
}
