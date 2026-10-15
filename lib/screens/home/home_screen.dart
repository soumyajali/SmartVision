import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/detection_controller.dart';
import '../../controllers/statistics_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/detection_history.dart';
import '../../services/camera_service.dart';
import '../../services/database_service.dart';
import '../../services/on_device_ai_service.dart';
import '../../widgets/camera_preview_widget.dart';
import '../../widgets/detection_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _inputSource = 'Live Camera';
  int _rotationQuarterTurns = 0;
  bool _flipHorizontally = false;
  Uint8List? _customImageBytes;
  Future<List<DetectionHistory>>? _recentHistoryFuture;

  final Map<String, String> _sampleSceneAssets = {
    'Test Scene: Classroom': 'assets/samples/classroom.jpg',
    'Test Scene: Office': 'assets/samples/office.jpg',
    'Test Scene: Safety Hazard': 'assets/samples/danger.png',
    'Test Scene: Identity Permit': 'assets/samples/document.png',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraService>().initialize();
      context.read<StatisticsController>().refreshData();
      _loadRecentHistory();
    });
  }

  void _loadRecentHistory() {
    final db = context.read<DatabaseService>();
    setState(() {
      _recentHistoryFuture = db.getDetectionHistory();
    });
  }

  Future<void> _processSampleScene(String assetPath) async {
    final controller = context.read<DetectionController>();
    try {
      final bytes = await rootBundle.load(assetPath);
      final u8list = bytes.buffer.asUint8List();
      final b64 = base64Encode(u8list);
      await controller.analyzeImageBase64(b64);
      _loadRecentHistory();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image analysis failed: $error')),
      );
    }
  }

  Future<void> _pickAndProcessCustomImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _customImageBytes = bytes;
          _inputSource = 'Uploaded Image';
        });
        final controller = context.read<DetectionController>();
        await controller.analyzeImageBytes(bytes);
        _loadRecentHistory();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not analyze the selected image: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: RefreshIndicator(
        color: AppColors.neonAccent,
        backgroundColor: AppColors.elevatedSurface,
        onRefresh: () async {
          await context.read<StatisticsController>().refreshData();
          _loadRecentHistory();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          children: [
            // 1. Website-Identical Dashboard Header Bar
            _buildTopHeader(),
            const SizedBox(height: 12),

            // Quick Access Navigation Pills
            _buildQuickAccessPills(context),
            const SizedBox(height: 14),

            // 2. Main Media Stage & Side Stats
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildMediaStage(context)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildSideStats(context)),
                ],
              )
            else ...[
              _buildMediaStage(context),
              const SizedBox(height: 16),
              _buildSideStats(context),
            ],

            const SizedBox(height: 20),

            // 3. Recent Detections Carousel (matching website)
            _buildRecentDetectionsHeader(),
            const SizedBox(height: 10),
            _buildRecentDetectionsCarousel(),

            const SizedBox(height: 24),

            // 4. Quick Access AI Modules Grid
            _buildSectionHeader(
                'AI Vision Modules', 'All smart neural tools & pipelines'),
            const SizedBox(height: 12),
            _buildModuleGrid(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessPills(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.auto_awesome,
                size: 14, color: AppColors.neonAccent),
            label: const Text('Vision Chatbot',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/chatbot'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.document_scanner_rounded,
                size: 14, color: Colors.amberAccent),
            label: const Text('OCR & Translate',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/document_screening'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.radar_rounded,
                size: 14, color: AppColors.brightViolet),
            label: const Text('Target Search',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/find_object'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.movie_filter_rounded,
                size: 14, color: Colors.tealAccent),
            label: const Text('Video Review',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/video_review'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.face_rounded,
                size: 14, color: Colors.cyanAccent),
            label: const Text('Face ID',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/face_id'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.warning_amber_rounded,
                size: 14, color: AppColors.error),
            label: const Text('Threat Alerts',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/alerts'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.remove_red_eye_outlined,
                size: 14, color: Colors.cyanAccent),
            label: const Text('Drowsiness Monitor',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText)),
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => context.push('/drowsiness'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    final detectionCtrl = context.watch<DetectionController>();
    final aiService = context.watch<OnDeviceAiService>();
    final cameraController = context.watch<CameraService>().controller;
    final previewSize = cameraController?.value.previewSize;
    final resolution = previewSize == null
        ? 'Unavailable'
        : '${previewSize.width.round()} x ${previewSize.height.round()}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/logo.png',
                    width: 36, height: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SmartVision AI Sentinel',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText),
                  ),
                  Text(
                    'Real-time object detection and tracking',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ],
          ),

          // Show only telemetry the client can observe accurately.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTelemetryBadge(
                    'Status',
                    detectionCtrl.isDetecting ? 'Scanning' : 'Standby',
                    detectionCtrl.isDetecting
                        ? AppColors.success
                        : AppColors.warning),
                const SizedBox(width: 10),
                _buildTelemetryBadge(
                    'On-device AI',
                    aiService.isModelLoaded
                        ? 'Ready'
                        : aiService.isLoading
                            ? 'Loading'
                            : 'Unavailable',
                    aiService.isModelLoaded
                        ? AppColors.success
                        : AppColors.warning),
                const SizedBox(width: 10),
                _buildTelemetryBadge(
                    'Resolution', resolution, AppColors.primaryText),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _inputSource,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.neonAccent, size: 18),
                      items: [
                        'Live Camera',
                        'Upload Image / Gallery',
                        if (_inputSource == 'Uploaded Image') 'Uploaded Image',
                        'Test Scene: Classroom',
                        'Test Scene: Office',
                        'Test Scene: Safety Hazard',
                        'Test Scene: Identity Permit',
                      ]
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          if (val == 'Upload Image / Gallery') {
                            _pickAndProcessCustomImage();
                          } else {
                            setState(() => _inputSource = val);
                            if (val != 'Live Camera' &&
                                val != 'Uploaded Image') {
                              _processSampleScene(_sampleSceneAssets[val]!);
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildMediaStage(BuildContext context) {
    final cameraService = context.watch<CameraService>();
    final detectionCtrl = context.watch<DetectionController>();
    final isDetecting = detectionCtrl.isDetecting;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Media Viewport with Detection Overlays
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RotatedBox(
                  quarterTurns: _rotationQuarterTurns,
                  child: Transform.scale(
                    scaleX: _flipHorizontally ? -1 : 1,
                    child: _buildMediaFeed(cameraService),
                  ),
                ),

                // Bounding Box Overlays
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DetectionOverlay(
                      detections: detectionCtrl.currentResults,
                      screenSize:
                          Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),

                // Live Tracking Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDetecting
                          ? AppColors.neonAccent
                          : Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isDetecting ? '● TRACKING ACTIVE' : '○ STANDBY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDetecting ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orientation Controls & Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.cardBackground,
            child: Column(
              children: [
                // Rotation & Flip Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.rotate_right_rounded,
                              size: 20, color: AppColors.primaryText),
                          tooltip: 'Rotate 90° Clockwise',
                          onPressed: () {
                            setState(() => _rotationQuarterTurns =
                                (_rotationQuarterTurns + 1) % 4);
                          },
                        ),
                        Text(
                          '${_rotationQuarterTurns * 90}°',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _flipHorizontally
                                ? Icons.flip_rounded
                                : Icons.flip_rounded,
                            size: 20,
                            color: _flipHorizontally
                                ? AppColors.neonAccent
                                : AppColors.secondaryText,
                          ),
                          tooltip: 'Flip Horizontally',
                          onPressed: () {
                            setState(
                                () => _flipHorizontally = !_flipHorizontally);
                          },
                        ),
                      ],
                    ),
                    if (_inputSource != 'Live Camera')
                      TextButton.icon(
                        icon: const Icon(Icons.refresh,
                            size: 16, color: AppColors.neonAccent),
                        label: const Text('Re-run Inference',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.neonAccent)),
                        onPressed: () => _processSampleScene(
                            _sampleSceneAssets[_inputSource]!),
                      ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),

                // Button Row matching website: Start / Stop / Capture / Fullscreen
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDetecting
                              ? AppColors.error
                              : AppColors.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(
                            isDetecting
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 20),
                        label: Text(
                          isDetecting ? 'Stop Detection' : 'Start Detection',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          if (_inputSource == 'Live Camera') {
                            detectionCtrl.toggleDetection();
                          } else {
                            _processSampleScene(
                                _sampleSceneAssets[_inputSource]!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryText,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Capture',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          if (_inputSource == 'Live Camera' &&
                              cameraService.controller != null) {
                            try {
                              final xfile =
                                  await cameraService.controller!.takePicture();
                              final bytes = await xfile.readAsBytes();
                              await detectionCtrl.analyzeImageBytes(bytes);
                              _loadRecentHistory();
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Unable to capture or analyze this frame. Check camera access and the on-device model.')),
                                );
                              }
                            }
                          } else if (_inputSource != 'Live Camera') {
                            _processSampleScene(
                                _sampleSceneAssets[_inputSource]!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: AppColors.neonAccent),
                      tooltip: 'Fullscreen Scanner',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.elevatedSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onPressed: () => context.push('/camera_detection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaFeed(CameraService cameraService) {
    if (_inputSource == 'Uploaded Image' && _customImageBytes != null) {
      return Image.memory(_customImageBytes!, fit: BoxFit.cover);
    }

    if (_inputSource != 'Live Camera') {
      final path =
          _sampleSceneAssets[_inputSource] ?? 'assets/samples/classroom.jpg';
      return Image.asset(path, fit: BoxFit.cover);
    }

    if (cameraService.isInitialized && cameraService.controller != null) {
      return CameraPreviewWidget(controller: cameraService.controller!);
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_outlined,
                color: AppColors.mutedText, size: 40),
            const SizedBox(height: 8),
            const Text('Camera initializing…',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => cameraService.initialize(),
              child: const Text('Enable Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideStats(BuildContext context) {
    final detectionCtrl = context.watch<DetectionController>();
    final counts = detectionCtrl.objectCounts;
    final total = detectionCtrl.totalDetectionsCount;

    return Column(
      children: [
        // Real-Time Detections KPI Card (matching website)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Real-time Detections',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText)),
                  const SizedBox(height: 4),
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonAccent)),
                  const Text('Objects currently detected',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    ),
                    child: const Icon(Icons.radar_rounded,
                        size: 16, color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Detected Objects Breakdown Card (matching website)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detected Objects',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText)),
              const SizedBox(height: 12),
              if (counts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('No objects currently in view.',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.mutedText)),
                )
              else
                ...counts.entries.map((e) {
                  final pct = total > 0 ? (e.value / total) * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText)),
                            Text('${e.value} (${pct.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.neonAccent)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: total > 0 ? (e.value / total) : 0,
                          backgroundColor: AppColors.elevatedSurface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.neonAccent),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Detection Settings Panel right on Dashboard (matching website)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detection Settings',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Confidence Threshold',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.secondaryText)),
                  Text(
                      '${(detectionCtrl.settings.minimumConfidence * 100).toInt()}%',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonAccent)),
                ],
              ),
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: AppColors.neonAccent,
                  inactiveTrackColor: AppColors.elevatedSurface,
                  thumbColor: AppColors.neonAccent,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: detectionCtrl.settings.minimumConfidence,
                  min: 0.10,
                  max: 0.95,
                  onChanged: (val) {
                    detectionCtrl.updateSettings(
                      detectionCtrl.settings.copyWith(minimumConfidence: val),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDetectionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Detections',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText),
        ),
        TextButton(
          onPressed: () => context.push('/history'),
          child: const Text('View All',
              style: TextStyle(
                  color: AppColors.neonAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRecentDetectionsCarousel() {
    return FutureBuilder<List<DetectionHistory>>(
      future: _recentHistoryFuture,
      builder: (context, snapshot) {
        final list = (snapshot.data != null && snapshot.data!.isNotEmpty)
            ? snapshot.data!.take(5).toList()
            : const <DetectionHistory>[];

        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final item = list[idx];
              final conf = (item.confidence * 100).toInt();
              return Container(
                width: 130,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.objectName.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primaryText),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('$conf% Confidence',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.neonAccent)),
                    const SizedBox(height: 2),
                    Text(
                        '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.mutedText)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText)),
        Text(subtitle,
            style:
                const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      {
        'title': 'Vision Chatbot',
        'desc': 'Multimodal AI assistant with camera view',
        'icon': Icons.smart_toy_outlined,
        'route': '/chatbot',
        'color': AppColors.neonAccent
      },
      {
        'title': 'Target Lookup',
        'desc': 'Search and track specific objects in scene',
        'icon': Icons.radar_rounded,
        'route': '/find_object',
        'color': AppColors.brightViolet
      },
      {
        'title': 'Threat Sentinel',
        'desc': 'Hazard alarms for weapons and danger items',
        'icon': Icons.security_rounded,
        'route': '/alerts',
        'color': AppColors.error
      },
      {
        'title': 'Biometric Face ID',
        'desc': 'FAISS vector identity verification',
        'icon': Icons.face_retouching_natural_rounded,
        'route': '/face_id',
        'color': Colors.cyanAccent
      },
      {
        'title': 'OCR & Translate',
        'desc': 'Text extraction, 18-language translation',
        'icon': Icons.document_scanner_rounded,
        'route': '/document_screening',
        'color': Colors.amberAccent
      },
      {
        'title': 'Video Review',
        'desc': 'Automated video timeline object search',
        'icon': Icons.movie_filter_rounded,
        'route': '/video_review',
        'color': Colors.tealAccent
      },
      {
        'title': 'Telemetry & Research',
        'desc': 'mAP, accuracy curves & SQLite logs',
        'icon': Icons.analytics_outlined,
        'route': '/statistics',
        'color': Colors.lightGreenAccent
      },
      {
        'title': 'System Settings',
        'desc': 'Configure server IP, sirens & voice TTS',
        'icon': Icons.tune_rounded,
        'route': '/settings',
        'color': Colors.deepOrangeAccent
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, idx) {
        final m = modules[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(m['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m['icon'] as IconData,
                    color: m['color'] as Color, size: 22),
                const SizedBox(height: 6),
                Text(m['title'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text(m['desc'] as String,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.secondaryText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}
