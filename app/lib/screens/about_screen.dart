import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Vision',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Real-time object detection built with Flutter, YOLOv8, and TensorFlow Lite.'),
            SizedBox(height: 12),
            Text('This starter foundation includes the complete screen structure and app entry flow.'),
          ],
        ),
      ),
    );
  }
}
