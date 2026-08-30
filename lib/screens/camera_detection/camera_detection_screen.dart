import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  bool isDetecting = false;
  double confidenceThreshold = 0.5;
  double iouThreshold = 0.45;
  double maxDetections = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0), // ~24-32px page padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Live Video Detection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                    Text('Real-time object tracking and analysis', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Camera Active', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain)),
                      const SizedBox(width: 16),
                      const Icon(Icons.settings_input_component, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('Default Cam', style: TextStyle(color: AppColors.textSecondary)),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            // Main Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Video & Controls
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        // Video Container
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A), // Dark only inside video area
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Stack(
                              children: [
                                // Mock Bounding Box for Person (Green)
                                if (isDetecting)
                                  Positioned(
                                    top: 100, left: 150,
                                    child: Container(
                                      width: 200, height: 300,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.primary, width: 2),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(
                                          color: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: const Text('Person 98%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Mock Bounding Box for Vehicle (Blue)
                                if (isDetecting)
                                  Positioned(
                                    top: 250, left: 450,
                                    child: Container(
                                      width: 150, height: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.secondary, width: 2),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(
                                          color: AppColors.secondary,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: const Text('Car 89%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Top Overlays
                                Positioned(
                                  top: 16, left: 16, right: 16,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                                            SizedBox(width: 6),
                                            Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          _buildVideoBadge('FPS: 30.1'),
                                          const SizedBox(width: 8),
                                          _buildVideoBadge('1920x1080'),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                if (!isDetecting)
                                  const Center(
                                    child: Text('Press Start to Begin Detection', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Controls
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() { isDetecting = true; });
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Detection', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() { isDetecting = false; });
                                },
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop Detection', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildSecondaryButton(Icons.camera_alt, 'Capture'),
                            const SizedBox(width: 16),
                            _buildSecondaryButton(Icons.videocam, 'Record'),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 24), // 24px spacing
                  
                  // Right Column: Settings & KPIs
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // KPI Stats Card
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Statistics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textMain)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildStatItem('Objects Detected', '12', Icons.category, AppColors.primary)),
                                  Expanded(child: _buildStatItem('Accuracy', '94.8%', Icons.analytics, AppColors.secondary)),
                                ],
                              ),
                            ],
                          )
                        ),
                        const SizedBox(height: 16),
                        
                        // Detected Objects Panel
                        Expanded(
                          child: _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Detected Objects', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textMain)),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      _buildObjectRow(Icons.person, 'Person', '8', '60%', AppColors.primary),
                                      _buildObjectRow(Icons.directions_car, 'Vehicle', '3', '25%', AppColors.secondary),
                                      _buildObjectRow(Icons.backpack, 'Backpack', '1', '15%', AppColors.aiFeature),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Settings Card
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Detection Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textMain)),
                              const SizedBox(height: 16),
                              _buildSliderRow('Confidence', confidenceThreshold, (v) => setState(() => confidenceThreshold = v)),
                              _buildSliderRow('IoU Threshold', iouThreshold, (v) => setState(() => iouThreshold = v)),
                            ],
                          )
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: child,
    );
  }

  Widget _buildSecondaryButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildVideoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )
      ],
    );
  }

  Widget _buildObjectRow(IconData icon, String name, String count, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textMain))),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(width: 16),
          SizedBox(
            width: 40,
            child: Text(percentage, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
