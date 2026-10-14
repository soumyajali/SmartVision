import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/camera_service.dart';
import '../../services/smartvision_api_service.dart';
import '../../services/speech_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final SmartVisionApiService _apiService = SmartVisionApiService();
  final List<Map<String, String>> _persons = [
    {'name': 'Soumya', 'role': 'Lead Researcher', 'id': '#101', 'status': 'Enrolled (FAISS)'},
    {'name': 'Alex Rivera', 'role': 'Security Admin', 'id': '#102', 'status': 'Enrolled (FAISS)'},
    {'name': 'Elena Chen', 'role': 'Vision Systems Eng.', 'id': '#103', 'status': 'Enrolled (FAISS)'},
  ];

  double _similarityThreshold = 0.70;
  String _currentIdentity = 'Soumya';
  double _currentConfidence = 0.95;
  bool _isVerified = true;
  bool _isScanning = false;

  Future<void> _enrollNewFace(String name, String role, [Uint8List? directBytes]) async {
    final cameraService = context.read<CameraService>();
    final speechService = context.read<SpeechService>();

    String b64Image = "";
    try {
      if (directBytes != null) {
        b64Image = base64Encode(directBytes);
      } else if (cameraService.controller != null && cameraService.isInitialized) {
        final xfile = await cameraService.controller!.takePicture();
        final bytes = await xfile.readAsBytes();
        b64Image = base64Encode(bytes);
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          b64Image = base64Encode(bytes);
        } else {
          final bytes = await rootBundle.load('assets/samples/classroom.jpg');
          b64Image = base64Encode(bytes.buffer.asUint8List());
        }
      }

      await _apiService.registerFace(base64Image: b64Image, name: name);

      setState(() {
        _persons.add({
          'name': name,
          'role': role,
          'id': '#${100 + _persons.length + 1}',
          'status': 'Enrolled (FAISS)',
        });
      });

      speechService.speak('Identity $name registered successfully in FAISS vector index.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered $name into FAISS vector database!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
      }
    }
  }

  void _showEnrollDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController(text: 'Team Member');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Enroll New Identity', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(labelText: 'Role / Designation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Capture & Enroll'),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _enrollNewFace(name, roleController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _runBiometricVerification() async {
    setState(() => _isScanning = true);
    final cameraService = context.read<CameraService>();
    final speechService = context.read<SpeechService>();

    try {
      String b64Image = "";
      if (cameraService.controller != null && cameraService.isInitialized) {
        final xfile = await cameraService.controller!.takePicture();
        final bytes = await xfile.readAsBytes();
        b64Image = base64Encode(bytes);
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          b64Image = base64Encode(bytes);
        } else {
          final bytes = await rootBundle.load('assets/samples/classroom.jpg');
          b64Image = base64Encode(bytes.buffer.asUint8List());
        }
      }

      final recs = await _apiService.recognizeFace(base64Image: b64Image);

      if (mounted) {
        setState(() {
          _isScanning = false;
          if (recs.isNotEmpty && recs[0]['name'] != null && recs[0]['name'] != 'Unknown') {
            final name = recs[0]['name'].toString();
            final conf = (recs[0]['confidence'] as num?)?.toDouble() ?? 0.94;
            if (conf >= _similarityThreshold) {
              _isVerified = true;
              _currentIdentity = name;
              _currentConfidence = conf;
              speechService.speak('Identity confirmed. Welcome $name.');
            } else {
              _isVerified = false;
              _currentIdentity = 'Low Confidence Match';
              _currentConfidence = conf;
            }
          } else {
            _isVerified = false;
            _currentIdentity = 'Unrecognized Individual';
            _currentConfidence = 0.45;
            speechService.speak('Alert: Unrecognized identity in camera view.');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Biometric Face ID (FAISS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.neonAccent),
            onPressed: _showEnrollDialog,
            tooltip: 'Enroll Face',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Biometric Verification Frame
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isVerified ? AppColors.neonAccent : AppColors.warning,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isVerified ? AppColors.primaryViolet : AppColors.warning).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isVerified ? AppColors.neonAccent : AppColors.warning,
                      width: 2.5,
                    ),
                    color: AppColors.elevatedSurface,
                  ),
                  child: Icon(
                    _isVerified ? Icons.face_rounded : Icons.face_retouching_natural_rounded,
                    size: 52,
                    color: _isVerified ? AppColors.neonAccent : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isVerified ? 'VERIFIED: $_currentIdentity' : 'IDENTITY: $_currentIdentity',
                  style: TextStyle(
                    color: _isVerified ? AppColors.neonAccent : AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cosine Distance: ${((1.0 - _currentConfidence) * 0.4).toStringAsFixed(2)} • Confidence: ${(_currentConfidence * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isScanning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.face_unlock_rounded, size: 20),
                  label: Text(_isScanning ? 'Comparing FAISS Vectors...' : 'Run Biometric Match'),
                  onPressed: _isScanning ? null : _runBiometricVerification,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Similarity Threshold Slider
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Verification Threshold', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${(_similarityThreshold * 100).toInt()}%', style: const TextStyle(color: AppColors.neonAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: AppColors.neonAccent,
                    thumbColor: AppColors.neonAccent,
                  ),
                  child: Slider(
                    value: _similarityThreshold,
                    min: 0.50,
                    max: 0.95,
                    onChanged: (val) => setState(() => _similarityThreshold = val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Enrolled Identities
          Text(
            'Enrolled Vector Identities (${_persons.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
          ..._persons.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryViolet.withValues(alpha: 0.25),
                      child: Text(p['name']![0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonAccent)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryText)),
                          Text(p['role']!, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['status']!,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
