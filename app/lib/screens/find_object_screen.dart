import 'package:flutter/material.dart';

class FindObjectScreen extends StatelessWidget {
  const FindObjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64),
          SizedBox(height: 12),
          Text('Find Object Screen'),
          SizedBox(height: 8),
          Text('Voice-guided object lookup will be added here.'),
        ],
      ),
    );
  }
}
