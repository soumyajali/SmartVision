import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.flashlight_on),
          title: Text('Flashlight settings'),
          subtitle: Text('Toggle quick camera flash controls'),
        ),
        ListTile(
          leading: Icon(Icons.dark_mode),
          title: Text('Dark mode'),
          subtitle: Text('Material 3 ready theme support'),
        ),
        ListTile(
          leading: Icon(Icons.offline_bolt),
          title: Text('Offline mode'),
          subtitle: Text('Run detection without internet dependency'),
        ),
      ],
    );
  }
}
