import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../camera/camera_service.dart';
import '../ai/model_service.dart';
import '../face_recognition/services/voice_service.dart';

class LiveDetectionPage extends StatefulWidget {
  const LiveDetectionPage({super.key});

  @override
  State<LiveDetectionPage> createState() => _LiveDetectionPageState();
}

class _LiveDetectionPageState extends State<LiveDetectionPage> {
  double _confidenceThreshold = 0.50;
  bool _searchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _picker = ImagePicker();
  bool _isPaused = false;
  
  // Simulated or active detections list for interactive demonstration
  List<Map<String, dynamic>> _mockDetections = [
    {'label': 'person', 'confidence': 0.94, 'rect': const Rect.fromLTWH(0.25, 0.18, 0.50, 0.65)},
    {'label': 'cell phone', 'confidence': 0.88, 'rect': const Rect.fromLTWH(0.68, 0.55, 0.22, 0.28)},
    {'label': 'laptop', 'confidence': 0.82, 'rect': const Rect.fromLTWH(0.12, 0.60, 0.45, 0.30)},
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearchCheck(String query) {
    if (query.trim().isEmpty) return;
    final queryLower = query.toLowerCase().trim();
    final found = _mockDetections.any((d) => (d['label'] as String).toLowerCase().contains(queryLower));
    if (found) {
      _voiceService.announceFound(query);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black),
              const SizedBox(width: 8),
              Text('FOUND: "$query" detected in scene!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else {
      _voiceService.speak("Searching for $query");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = Provider.of<CameraService>(context);
    final modelService = Provider.of<ModelService>(context);

    // Filter detections based on confidence slider
    final activeDetections = _mockDetections.where((d) => (d['confidence'] as double) >= _confidenceThreshold).toList();

    // Calculate counts
    final Map<String, int> counts = {};
    for (var d in activeDetections) {
      final label = d['label'] as String;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFC2).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00FFC2)),
              ),
              child: const Text('YOLOv8', style: TextStyle(color: Color(0xFF00FFC2), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Live Object Detection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(cameraService.flashEnabled ? Icons.flash_on : Icons.flash_off, color: Colors.white70),
            onPressed: () => cameraService.toggleFlash(),
            tooltip: 'Flash',
          ),
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white70),
            onPressed: () => setState(() => _isPaused = !_isPaused),
            tooltip: _isPaused ? 'Resume' : 'Pause',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera / Viewfinder
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview or Fallback Viewfinder
                Container(
                  color: Colors.black,
                  child: cameraService.isCameraReady && cameraService.controller != null && !_isPaused
                      ? ClipRect(child: CameraPreview(cameraService.controller!))
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isPaused ? Icons.pause_circle_outline : Icons.videocam, size: 64, color: Colors.white24),
                              const SizedBox(height: 12),
                              Text(
                                _isPaused ? 'Feed Paused' : 'YOLOv8 Neural Stream Active',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                ),

                // Bounding Boxes Overlay
                ...activeDetections.map((d) {
                  final rect = d['rect'] as Rect;
                  final label = d['label'] as String;
                  final conf = (d['confidence'] as double);
                  final isTarget = _searchMode && _searchQuery.isNotEmpty && label.toLowerCase().contains(_searchQuery.toLowerCase());

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final left = rect.left * constraints.maxWidth;
                      final top = rect.top * constraints.maxHeight;
                      final width = rect.width * constraints.maxWidth;
                      final height = rect.height * constraints.maxHeight;

                      return Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isTarget ? const Color(0xFF00FFC2) : Colors.amberAccent,
                              width: isTarget ? 3 : 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: isTarget ? const Color(0xFF00FFC2) : Colors.amberAccent,
                              child: Text(
                                '$label ${(conf * 100).toInt()}%',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),

                // Top HUD: FPS & Object Counter
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00FFC2), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('32 FPS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${activeDetections.length} Objects Detected',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Object Counts Chips
          if (counts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF161B22),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: counts.entries.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Text(e.key.toUpperCase(), style: const TextStyle(color: Color(0xFF00FFC2), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                            child: Text('${e.value}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Controls & Tuning Panel (Matching Streamlit sidebar controls)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0D1117),
              child: ListView(
                children: [
                  // Confidence Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Confidence Threshold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${(_confidenceThreshold * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00FFC2), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00FFC2),
                      thumbColor: const Color(0xFF00FFC2),
                    ),
                    child: Slider(
                      value: _confidenceThreshold,
                      min: 0.10,
                      max: 0.95,
                      divisions: 17,
                      onChanged: (val) => setState(() => _confidenceThreshold = val),
                    ),
                  ),

                  // Object Search Mode ("Find My Item")
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.search, size: 18, color: Color(0xFF00FFC2)),
                                SizedBox(width: 6),
                                Text('Object Search Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Switch(
                              value: _searchMode,
                              activeColor: const Color(0xFF00FFC2),
                              onChanged: (val) {
                                setState(() => _searchMode = val);
                                if (val && _searchQuery.isNotEmpty) _triggerSearchCheck(_searchQuery);
                              },
                            ),
                          ],
                        ),
                        if (_searchMode) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter item to search (e.g. bottle, keys, laptop)...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF21262D),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.volume_up, color: Color(0xFF00FFC2)),
                                onPressed: () {
                                  _searchQuery = _searchController.text;
                                  _triggerSearchCheck(_searchQuery);
                                },
                              ),
                            ),
                            onSubmitted: (val) {
                              setState(() => _searchQuery = val);
                              _triggerSearchCheck(val);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Snapshot & Gallery Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final image = await _picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              modelService.simulateStaticInference();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Processing selected photo with YOLOv8...')),
                              );
                            }
                          },
                          icon: const Icon(Icons.photo_library, size: 16),
                          label: const Text('Pick Image'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FFC2),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _voiceService.speak("${activeDetections.length} objects visible in view");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Frame captured & logged to detections history')),
                            );
                          },
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('Capture Log', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
