import 'package:flutter/material.dart';

class RecognitionSettingsScreen extends StatefulWidget {
  const RecognitionSettingsScreen({super.key});

  @override
  State<RecognitionSettingsScreen> createState() => _RecognitionSettingsScreenState();
}

class _RecognitionSettingsScreenState extends State<RecognitionSettingsScreen> {
  double _threshold = 0.75;
  bool _enableTts = true;
  bool _enableUnknowns = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recognition Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Cosine Similarity Threshold", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const SizedBox(height: 8),
          Text(
            "Higher threshold means stricter matching. Lower threshold may cause false positives.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Slider(
            value: _threshold,
            min: 0.65,
            max: 0.85,
            divisions: 20,
            label: _threshold.toStringAsFixed(2),
            onChanged: (value) {
              setState(() => _threshold = value);
              // In a full implementation, you'd save this to SharedPreferences 
              // and update FaceRecognitionService.setThreshold()
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Enable TTS Announcements"),
            subtitle: const Text("Audibly announce known names"),
            value: _enableTts,
            onChanged: (val) => setState(() => _enableTts = val),
          ),
          SwitchListTile(
            title: const Text("Log Unknown Persons"),
            subtitle: const Text("Save unknown faces to history"),
            value: _enableUnknowns,
            onChanged: (val) => setState(() => _enableUnknowns = val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("View Recognition History"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/recognition_history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Manage Known Persons DB"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/known_persons');
            },
          ),
        ],
      ),
    );
  }
}
