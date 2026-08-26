import 'package:flutter/material.dart';

class DetectionHistoryScreen extends StatelessWidget {
  const DetectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64),
          SizedBox(height: 12),
          Text('Detection History'),
          SizedBox(height: 8),
          Text('SQLite history and search records will be shown here.'),
        ],
      ),
    );
  }
}
