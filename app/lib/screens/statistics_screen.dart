import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64),
          SizedBox(height: 12),
          Text('Statistics'),
          SizedBox(height: 8),
          Text('Detection analytics will be displayed here.'),
        ],
      ),
    );
  }
}
