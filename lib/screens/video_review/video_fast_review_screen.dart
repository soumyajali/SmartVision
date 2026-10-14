import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/on_device_ai_service.dart';

class VideoFastReviewScreen extends StatefulWidget {
  const VideoFastReviewScreen({super.key});

  @override
  State<VideoFastReviewScreen> createState() => _VideoFastReviewScreenState();
}

class _VideoFastReviewScreenState extends State<VideoFastReviewScreen> {
  final OnDeviceAiService _aiService = OnDeviceAiService.instance;
  final List<String> _targetClasses = const [
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

  String _selectedTarget = 'person';
  double _minConfidence = 0.25;
  bool _isAnalyzing = false;
  bool _isPreparingVideo = false;
  Map<String, dynamic>? _reviewResults;
  XFile? _selectedVideo;
  VideoPlayerController? _videoController;
  int? _activeTimelineEventIndex;

  List<dynamic> get _timeline => _reviewResults?['timeline'] as List? ?? [];

  @override
  void dispose() {
    _videoController?.removeListener(_updateTimelineSelection);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickVideo(source: source);
      if (picked == null || !mounted) return;
      setState(() {
        _isPreparingVideo = true;
        _reviewResults = null;
        _activeTimelineEventIndex = null;
      });

      final previousController = _videoController;
      previousController?.removeListener(_updateTimelineSelection);
      await previousController?.dispose();
      final controller = VideoPlayerController.file(File(picked.path));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_updateTimelineSelection);
      setState(() {
        _selectedVideo = picked;
        _videoController = controller;
        _isPreparingVideo = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPreparingVideo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open selected video: $error')),
      );
    }
  }

  void _updateTimelineSelection() {
    final controller = _videoController;
    if (controller == null || _timeline.isEmpty || !mounted) return;
    final currentSeconds = controller.value.position.inMilliseconds / 1000;
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < _timeline.length; index++) {
      final event = _timeline[index];
      if (event is! Map) continue;
      final seconds = (event['seconds'] as num?)?.toDouble();
      if (seconds == null) continue;
      final distance = (seconds - currentSeconds).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }
    if (nearestDistance <= 1 && nearestIndex != _activeTimelineEventIndex) {
      setState(() => _activeTimelineEventIndex = nearestIndex);
    }
  }

  Future<void> _startVideoReview() async {
    final video = _selectedVideo;
    if (video == null) return;
    final database = context.read<DatabaseService>();
    final inferenceSettings = context.read<DetectionController>().settings;

    setState(() {
      _isAnalyzing = true;
      _reviewResults = null;
      _activeTimelineEventIndex = null;
    });
    try {
      final results = await _aiService.reviewVideo(
        path: video.path,
        targetObject: _selectedTarget,
        settings: inferenceSettings.copyWith(
          minimumConfidence: _minConfidence,
        ),
      );
      try {
        await database.insertAnalysisHistory(
          analysisType: 'Video Fast Review',
          summary:
              '${results['total_events'] ?? 0} target frame(s) found for $_selectedTarget',
          details: {'video': video.name, ...results},
        );
      } catch (storageError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Review completed, but history save failed: $storageError')),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _reviewResults = results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video review failed: $error')),
      );
    }
  }

  Future<void> _shareReport() async {
    final results = _reviewResults;
    if (results == null) return;
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/smartvision_video_review.json');
      final report = <String, dynamic>{
        'generated_at': DateTime.now().toIso8601String(),
        'video': _selectedVideo?.name,
        ...results,
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'SmartVision video review report',
          text: 'Analysis report for ${_selectedVideo?.name ?? 'video'}',
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export report: $error')),
      );
    }
  }

  Future<void> _seekToEvent(Map event, int index) async {
    final seconds = (event['seconds'] as num?)?.toDouble();
    if (seconds == null) return;
    setState(() => _activeTimelineEventIndex = index);
    await _videoController?.seekTo(
      Duration(milliseconds: (seconds * 1000).round()),
    );
    await _videoController?.play();
  }

  Widget _buildPlaybackPreview() {
    final controller = _videoController;
    if (_isPreparingVideo) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.neonAccent),
        ),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final event = _activeTimelineEventIndex != null &&
            _activeTimelineEventIndex! < _timeline.length &&
            _timeline[_activeTimelineEventIndex!] is Map
        ? _timeline[_activeTimelineEventIndex!] as Map
        : null;
    final detections = event?['detections'] as List? ?? const [];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(controller),
                if (event != null)
                  CustomPaint(
                    painter: _DetectionBoxesPainter(detections),
                  ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => controller.value.isPlaying
                  ? controller.pause()
                  : controller.play(),
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.neonAccent,
                  bufferedColor: AppColors.elevatedSurface,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
          ],
        ),
        if (event != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Overlay: ${event['timestamp'] ?? ''} · ${detections.length} detection(s)',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(title: const Text('Video Fast Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    Icon(
                      Icons.movie_filter_rounded,
                      color: AppColors.neonAccent,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Automated Video Scanner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Analyze one frame per second locally with the bundled YOLOv8n model. No video is uploaded.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isAnalyzing
                      ? null
                      : () => _pickVideo(ImageSource.gallery),
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(
                    _selectedVideo?.name ?? 'Choose a video',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isAnalyzing
                      ? null
                      : () => _pickVideo(ImageSource.camera),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Record a video'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                if (_selectedVideo != null) ...[
                  const SizedBox(height: 12),
                  _buildPlaybackPreview(),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Search Target Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTarget,
                  dropdownColor: AppColors.elevatedSurface,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _targetClasses
                      .map((target) => DropdownMenuItem(
                            value: target,
                            child: Text(target.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTarget = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confidence Threshold',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      '${(_minConfidence * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonAccent,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _minConfidence,
                  min: 0.15,
                  max: 0.85,
                  divisions: 14,
                  onChanged: (value) => setState(() => _minConfidence = value),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _selectedVideo == null || _isAnalyzing
                        ? null
                        : _startVideoReview,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.radar_rounded),
                    label: Text(
                      _isAnalyzing ? 'Analyzing video…' : 'Start Fast Review',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_reviewResults != null) ...[
            const SizedBox(height: 20),
            _buildTimeline(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final results = _reviewResults!;
    final timeline = _timeline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Timeline Occurrences (${results['total_events'] ?? timeline.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Export analysis report',
              onPressed: _shareReport,
              icon: const Icon(
                Icons.download_rounded,
                color: AppColors.neonAccent,
              ),
            ),
          ],
        ),
        if (timeline.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No matching frames were found by the on-device model.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
        ...timeline.indexed.map((entry) {
          final index = entry.$1;
          final value = entry.$2;
          if (value is! Map) return const SizedBox.shrink();
          final timestamp = value['timestamp']?.toString() ?? '00:00';
          final detections = value['detections'] as List? ?? const [];
          return InkWell(
            onTap: () => _seekToEvent(value, index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: index == _activeTimelineEventIndex
                    ? AppColors.elevatedSurface
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: index == _activeTimelineEventIndex
                      ? AppColors.neonAccent
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonAccent,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: detections.map<Widget>((item) {
                        if (item is! Map) return const SizedBox.shrink();
                        final label = item['label']?.toString() ?? 'Object';
                        final confidence =
                            ((item['confidence'] as num?)?.toDouble() ?? 0) *
                                100;
                        return Text(
                          '$label detected (${confidence.toStringAsFixed(0)}% confidence)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Text(
                    '${detections.length} objects',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DetectionBoxesPainter extends CustomPainter {
  const _DetectionBoxesPainter(this.detections);

  final List<dynamic> detections;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = AppColors.neonAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fillPaint = Paint()
      ..color = AppColors.neonAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (final value in detections) {
      if (value is! Map) continue;
      final coordinates = value['rect'];
      if (coordinates is! Map) continue;
      final left = (coordinates['left'] as num?)?.toDouble();
      final top = (coordinates['top'] as num?)?.toDouble();
      final right = (coordinates['right'] as num?)?.toDouble();
      final bottom = (coordinates['bottom'] as num?)?.toDouble();
      if (left == null || top == null || right == null || bottom == null) {
        continue;
      }

      final rect = Rect.fromLTRB(
        left.clamp(0.0, 1.0) * size.width,
        top.clamp(0.0, 1.0) * size.height,
        right.clamp(0.0, 1.0) * size.width,
        bottom.clamp(0.0, 1.0) * size.height,
      );
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, boxPaint);

      final confidence = ((value['confidence'] as num?)?.toDouble() ?? 0) * 100;
      final text = TextPainter(
        text: TextSpan(
          text:
              '${value['label'] ?? 'Object'} ${confidence.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final labelTop = (rect.top - text.height - 4).clamp(0.0, size.height);
      final labelRect = Rect.fromLTWH(
        rect.left.clamp(0.0, size.width),
        labelTop,
        text.width + 8,
        text.height + 4,
      );
      canvas.drawRect(labelRect, Paint()..color = AppColors.neonAccent);
      text.paint(canvas, Offset(labelRect.left + 4, labelRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionBoxesPainter oldDelegate) =>
      oldDelegate.detections != detections;
}
