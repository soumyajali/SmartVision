import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/speech_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final List<Map<String, String>> _persons = [
    {'name': 'Soumya', 'role': 'Lead Researcher', 'id': '#101', 'status': 'Authorized'},
    {'name': 'Alex Rivera', 'role': 'Security Admin', 'id': '#102', 'status': 'Authorized'},
    {'name': 'Elena Chen', 'role': 'Vision Systems Eng.', 'id': '#103', 'status': 'Authorized'},
    {'name': 'Marcus Vance', 'role': 'Operator', 'id': '#104', 'status': 'Authorized'},
  ];

  double _similarityThreshold = 0.75;
  String _currentIdentity = 'Soumya';
  double _currentConfidence = 0.96;
  bool _isVerified = true;

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
              decoration: const InputDecoration(
                labelText: 'Full Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(
                labelText: 'Role / Designation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Save & Enroll'),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _persons.add({
                    'name': name,
                    'role': roleController.text.trim(),
                    'id': '#${100 + _persons.length + 1}',
                    'status': 'Authorized',
                  });
                });
                context.read<SpeechService>().speak('Enrolled $name successfully.');
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speechService = context.read<SpeechService>();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Biometric Face ID'),
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
                  _isVerified ? 'VERIFIED: $_currentIdentity' : 'UNRECOGNIZED IDENTITY',
                  style: TextStyle(
                    color: _isVerified ? AppColors.neonAccent : AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(_currentConfidence * 100).toInt()}% • Cosine Distance: 0.22',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.elevatedSurface,
                        foregroundColor: AppColors.primaryText,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        setState(() {
                          _isVerified = !_isVerified;
                          if (!_isVerified) {
                            _currentIdentity = 'Unknown';
                            _currentConfidence = 0.45;
                            speechService.speak('Unrecognized person in camera view.');
                          } else {
                            _currentIdentity = 'Soumya';
                            _currentConfidence = 0.96;
                            speechService.speak('Identity confirmed. Soumya detected.');
                          }
                        });
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.neonAccent),
                      label: const Text('Simulate Verification', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                    const Text('Recognition Threshold', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      '${(_similarityThreshold * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.neonAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Slider(
                  value: _similarityThreshold,
                  min: 0.50,
                  max: 0.95,
                  divisions: 9,
                  onChanged: (val) => setState(() => _similarityThreshold = val),
                ),
                const Text(
                  'Vectors with cosine similarity above threshold are classified as positive match.',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Enrolled Identities Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enrolled Identities (${_persons.length})', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                onPressed: _showEnrollDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Face'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Column(
            children: _persons.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.elevatedSurface,
                    child: Text(
                      p['name']!.isNotEmpty ? p['name']![0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.neonAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(p['name']!, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                  subtitle: Text("${p['id']} • ${p['role']}", style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.brightViolet, size: 20),
                    tooltip: 'Announce Name',
                    onPressed: () => speechService.speak('Identity profile: ${p['name']}'),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
