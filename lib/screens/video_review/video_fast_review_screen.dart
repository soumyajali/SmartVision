import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/smartvision_api_service.dart';

class VideoFastReviewScreen extends StatefulWidget {
  const VideoFastReviewScreen({super.key});

  @override
  State<VideoFastReviewScreen> createState() => _VideoFastReviewScreenState();
}

class _VideoFastReviewScreenState extends State<VideoFastReviewScreen> {
  final SmartVisionApiService _apiService = SmartVisionApiService();
  String _selectedTarget = 'person';
  double _minConfidence = 0.25;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _reviewResults;

  final List<String> _targetClasses = [
    'person',
    'cell phone',
    'laptop',
    'bottle',
    'backpack',
    'chair',
    'car',
    'knife',
    'scissors',
    'dog',
    'cat',
    'book',
  ];

  Future<void> _startVideoReview() async {
    setState(() {
      _isAnalyzing = true;
      _reviewResults = null;
    });

    try {
      // Ingest test video asset 'dummy.mp4' from root/assets
      String videoBase64 = "";
      try {
        final bytes = await rootBundle.load('dummy.mp4');
        videoBase64 = base64Encode(bytes.buffer.asUint8List());
      } catch (_) {
        videoBase64 = base64Encode(List.filled(1024, 0));
      }

      final results = await _apiService.reviewVideo(
        videoBase64: videoBase64,
        targetObject: _selectedTarget,
        minConfidence: _minConfidence,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _reviewResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video review failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Video Fast Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.movie_filter_rounded, color: AppColors.neonAccent, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Automated Video Scanner',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan video feeds automatically to find every exact timestamp where a target appears.',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),

                // Target Object Selector
                const Text('Search Target Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTarget,
                  dropdownColor: AppColors.elevatedSurface,
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.elevatedSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: _targetClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTarget = val);
                  },
                ),

                const SizedBox(height: 14),

                // Confidence Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Confidence Threshold', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                    Text('${(_minConfidence * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonAccent)),
                  ],
                ),
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: AppColors.neonAccent,
                    thumbColor: AppColors.neonAccent,
                  ),
                  child: Slider(
                    value: _minConfidence,
                    min: 0.15,
                    max: 0.85,
                    onChanged: (val) => setState(() => _minConfidence = val),
                  ),
                ),

                const SizedBox(height: 10),

                // Scan Trigger Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isAnalyzing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, size: 20),
                  label: Text(_isAnalyzing ? 'Scanning Video Timeline...' : 'Scan Video for $_selectedTarget'),
                  onPressed: _isAnalyzing ? null : _startVideoReview,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Timeline Events
          if (_reviewResults != null) ...[
            Text(
              'Timeline Occurrences (${_reviewResults!['total_events']} found)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
            const SizedBox(height: 10),
            ...(_reviewResults!['timeline'] as List? ?? []).map((ev) {
              final String time = ev['timestamp'] ?? '00:00';
              final List dets = ev['detections'] ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.neonAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonAccent, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: dets.map<Widget>((d) {
                          final label = (d['label'] ?? '').toString().toUpperCase();
                          final conf = ((d['confidence'] as num?)?.toDouble() ?? 0.0) * 100;
                          return Text(
                            '$label detected (${conf.toStringAsFixed(0)}% confidence)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                          );
                        }).toList(),
                      ),
                    ),
                    const Icon(Icons.play_circle_fill_rounded, color: AppColors.neonAccent, size: 24),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
