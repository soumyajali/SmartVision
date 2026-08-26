import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_vision/camera/camera_service.dart';
import 'package:smart_vision/ai/model_service.dart';
import 'package:smart_vision/services/feature_manager.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _processStaticImage(ImageSource source, ModelService ms, [CameraService? cs]) async {
    XFile? imageFile;
    if (source == ImageSource.camera && cs != null && cs.controller != null) {
      try {
        imageFile = await cs.controller!.takePicture();
      } catch (e) {
        debugPrint('Failed to take picture: $e');
      }
    } else {
      imageFile = await _picker.pickImage(source: source);
    }
    
    if (imageFile != null) {
      // In a real app we'd decode this into a CameraImage equivalent or adjust ModelService
      // For this prototype, we'll just show a snackbar and simulate a dummy detection 
      // since ModelService.runInference takes a CameraImage from the live stream.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing static image...')));
      ms.simulateStaticInference();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Consumer2<CameraService, ModelService>(
                  builder: (context, cameraService, modelService, child) {
                    if (!cameraService.isCameraReady || cameraService.controller == null) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Transform.scale(
                        scale: kIsWeb ? cameraService.zoomLevel : 1.0,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(cameraService.controller!),
                            CustomPaint(
                              painter: BoundingBoxPainter(modelService.recognitions),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  Consumer<CameraService>(
                    builder: (context, camera, child) => ActionChip(
                      label: Text(camera.flashEnabled ? 'Flashlight On' : 'Flashlight Off'),
                      avatar: Icon(camera.flashEnabled ? Icons.flash_on : Icons.flash_off, size: 16),
                      onPressed: () => camera.toggleFlash(),
                    ),
                  ),
                  Consumer<CameraService>(
                    builder: (context, camera, child) => ActionChip(
                      label: Text('Zoom (${camera.zoomLevel.toStringAsFixed(1)}x)'),
                      avatar: const Icon(Icons.zoom_in, size: 16),
                      onPressed: () {
                        double nextZoom = camera.zoomLevel >= 3.0 ? 1.0 : camera.zoomLevel + 1.0;
                        camera.setZoom(nextZoom);
                      },
                    ),
                  ),
                  if (kIsWeb) ...[
                    ActionChip(
                      label: const Text('Capture'),
                      avatar: const Icon(Icons.camera, size: 16),
                      onPressed: () => _processStaticImage(
                        ImageSource.camera, 
                        Provider.of<ModelService>(context, listen: false),
                        Provider.of<CameraService>(context, listen: false),
                      ),
                    ),
                    ActionChip(
                      label: const Text('Upload'),
                      avatar: const Icon(Icons.upload, size: 16),
                      onPressed: () => _processStaticImage(
                        ImageSource.gallery, 
                        Provider.of<ModelService>(context, listen: false),
                      ),
                    ),
                  ],
                  ActionChip(
                    label: const Text('Database'),
                    avatar: const Icon(Icons.people, size: 16),
                    onPressed: () {
                      Navigator.pushNamed(context, '/known_persons');
                    },
                  ),
                  ActionChip(
                    label: const Text('Settings'),
                    avatar: const Icon(Icons.settings, size: 16),
                    onPressed: () {
                      Navigator.pushNamed(context, '/recognition_settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFeatureHUD(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHUD(BuildContext context) {
    // We get the feature manager safely avoiding 'listen' in build where not needed,
    // but Consumer watches it for updates if we want reactive changes in camera.
    return Consumer<FeatureManager>(
      builder: (context, fm, child) {
        final config = fm.config;
        List<String> active = [];
        if (config.objectDetection) active.add('Detection');
        if (config.objectTracking) active.add('Tracking');
        if (config.ocr) active.add('OCR');
        if (config.faceRecognition) active.add('Face');
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SMART SCAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 12),
              ...active.map((f) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFF00FFC2)),
                    const SizedBox(width: 4),
                    Text(f, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> recognitions;

  BoundingBoxPainter(this.recognitions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var rec in recognitions) {
      final rect = Rect.fromLTRB(
        rec.rect.left * size.width,
        rec.rect.top * size.height,
        rec.rect.right * size.width,
        rec.rect.bottom * size.height,
      );
      canvas.drawRect(rect, paint);

      textPainter.text = TextSpan(
        text: '${rec.label} ${(rec.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
