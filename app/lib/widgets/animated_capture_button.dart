import 'package:flutter/material.dart';

class AnimatedCaptureButton extends StatelessWidget {
  const AnimatedCaptureButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Detect'),
    );
  }
}
