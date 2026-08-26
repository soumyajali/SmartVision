import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/face_database_service.dart';
import '../services/face_recognition_service.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FaceDatabaseService _dbService = FaceDatabaseService();
  final FaceRecognitionService _recognitionService = FaceRecognitionService();

  XFile? _selectedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _recognitionService.loadModel();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _registerPerson() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and select an image.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Load image
      final bytes = await _selectedImage!.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) throw Exception("Failed to decode image.");

      // In a real implementation, we would pass this to RetinaFace to get the crop.
      // For this step, we assume the user took a clear portrait and we pass the image 
      // directly to the aligner and embedder.
      final aligned = await _recognitionService.alignFace(decodedImage);
      final preprocessed = await _recognitionService.preprocessFace(aligned);
      final embedding = await _recognitionService.generateEmbedding(preprocessed);

      // Save to SQLite
      final personId = await _dbService.addPerson(name);
      await _dbService.addFaceEmbedding(personId, embedding, _selectedImage!.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name registered successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Person")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb 
                          ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                    )
                  : const Center(child: Text("No Image Selected")),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _registerPerson,
                child: _isProcessing 
                    ? const CircularProgressIndicator()
                    : const Text("Register Face", style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
