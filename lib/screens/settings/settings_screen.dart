import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/speech_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SpeechService>(
        builder: (context, speechService, child) {
          final settings = speechService.settings;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text('Voice Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Voice Alerts'),
                subtitle: const Text('Announce detected objects verbally.'),
                value: settings.enabled,
                onChanged: (val) {
                  speechService.toggleVoice(val);
                },
                secondary: Icon(settings.enabled ? Icons.volume_up : Icons.volume_off),
              ),
              const Divider(),
              ListTile(
                title: const Text('Speech Rate'),
                subtitle: Slider(
                  value: settings.speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: settings.speechRate.toString(),
                  onChanged: settings.enabled
                      ? (val) {
                          speechService.updateSettings(settings.copyWith(speechRate: val));
                        }
                      : null,
                ),
              ),
              ListTile(
                title: const Text('Volume'),
                subtitle: Slider(
                  value: settings.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: settings.volume.toString(),
                  onChanged: settings.enabled
                      ? (val) {
                          speechService.updateSettings(settings.copyWith(volume: val));
                        }
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

