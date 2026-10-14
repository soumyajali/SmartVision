import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../services/on_device_ai_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final OnDeviceAiService _aiService = OnDeviceAiService.instance;
  bool _hasConsent = false;
  bool _isScanning = false;
  Uint8List? _imageBytes;
  int? _facesDetected;
  String? _error;

  Future<void> _detectFaces(ImageSource source) async {
    if (!_hasConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consent is required before processing face images.'),
        ),
      );
      return;
    }
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null || !mounted) return;
      setState(() {
        _isScanning = true;
        _error = null;
        _facesDetected = null;
        _imageBytes = null;
      });
      final bytes = await image.readAsBytes();
      final faces = await _aiService.detectFacesFromBytes(bytes);
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _imageBytes = bytes;
        _facesDetected = faces.length;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _error = 'On-device face detection failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(title: const Text('Face Recognition')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotice(
            Icons.privacy_tip_outlined,
            'Face data stays on this device. Confirm you have the subject’s '
            'consent before selecting or capturing an image.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _hasConsent,
            onChanged: (value) => setState(() => _hasConsent = value ?? false),
            activeColor: AppColors.primaryViolet,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text(
              'I have consent to process this face image',
              style: TextStyle(color: AppColors.primaryText, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          if (_imageBytes case final bytes?)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                bytes,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Could not display the selected image.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                ),
              ),
            ),
          if (_facesDetected case final count?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildNotice(
                count == 0 ? Icons.face_retouching_off : Icons.face_rounded,
                count == 0
                    ? 'No face was detected in this image.'
                    : '$count face(s) detected locally. No identity match was made.',
              ),
            ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildNotice(Icons.error_outline, error, isError: true),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _isScanning ? null : () => _detectFaces(ImageSource.camera),
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(_isScanning ? 'Analyzing on device…' : 'Capture image'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:
                _isScanning ? null : () => _detectFaces(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose image'),
          ),
          const SizedBox(height: 16),
          _buildNotice(
            Icons.info_outline,
            'Identity recognition and enrollment are disabled: this project '
            'does not include a trained face-embedding model. A face detector '
            'alone cannot identify a person, so the app will not claim a match.',
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(IconData icon, String message, {bool isError = false}) {
    final color = isError ? AppColors.error : AppColors.secondaryText;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isError ? AppColors.error : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isError ? AppColors.error : AppColors.neonAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
