import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('About SmartVision AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Header Logo & Version
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryViolet, AppColors.deepViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonAccent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.remove_red_eye_rounded, size: 48, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SmartVision AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Version 1.0.0+1 • Production Build',
                    style: TextStyle(fontSize: 11, color: AppColors.brightViolet, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Overview description card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'SmartVision AI is an intelligent real-time computer vision system integrating high-speed object detection, automated identity document screening, threat hazard sentinel alerts, and biometric face verification with synthesized speech announcements.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.5),
            ),
          ),

          const SizedBox(height: 24),

          // Core System Capabilities
          const Text(
            'Architectural Capabilities',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          ),
          const SizedBox(height: 12),
          _buildFeatureTile(
            Icons.center_focus_strong_rounded,
            'Real-Time Object Detection',
            'Ultralytics YOLOv8 & MobileNet inference pipeline detecting 80+ COCO classes.',
            AppColors.primaryViolet,
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            Icons.badge_outlined,
            'Automated ID Screening',
            'Machine Readable Zone (MRZ) validation with anti-tamper edge consistency checks.',
            AppColors.brightViolet,
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            Icons.warning_amber_rounded,
            'Threat & Hazard Sentinel',
            'Real-time blade, weapon, and fire detection with audio siren dispatch alarms.',
            AppColors.error,
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            Icons.face_rounded,
            'Biometric Face ID',
            'Face embedding extraction and vector cosine similarity verification.',
            AppColors.success,
          ),
          const SizedBox(height: 10),
          _buildFeatureTile(
            Icons.record_voice_over_rounded,
            'Speech Synthesis Feedback',
            'On-device text-to-speech audio announcements for accessibility.',
            AppColors.neonAccent,
          ),

          const SizedBox(height: 28),

          // System Status & Specs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'System Status: All Engines Operational',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Framework: Flutter 3.x (Dart null-safe)', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                const Text('Storage: SQLite with encrypted vector schemas', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                const Text('Audio: Native Android Text-to-Speech engine', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
