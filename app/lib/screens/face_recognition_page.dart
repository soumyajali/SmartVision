import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../face_recognition/services/face_database_service.dart';
import '../face_recognition/services/voice_service.dart';

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  final FaceDatabaseService _dbService = FaceDatabaseService();
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _picker = ImagePicker();
  List<Person> _persons = [];
  bool _isLoading = true;
  double _similarityThreshold = 0.70;
  
  // Demonstration verified face simulation
  String _currentIdentity = 'Soumya';
  double _currentConfidence = 0.96;
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _loadEnrolledFaces();
  }

  Future<void> _loadEnrolledFaces() async {
    try {
      final list = await _dbService.getAllPersons();
      setState(() {
        _persons = list;
        _isLoading = false;
      });
      // If empty in demo database, seed default identities
      if (_persons.isEmpty) {
        await _dbService.addPerson("Soumya", metadata: '{"role": "Administrator"}');
        await _dbService.addPerson("Alex Rivera", metadata: '{"role": "Security Lead"}');
        await _dbService.addPerson("Elena Chen", metadata: '{"role": "Staff"}');
        final updated = await _dbService.getAllPersons();
        setState(() => _persons = updated);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showEnrollDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController(text: 'Member');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Enroll New Identity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Role / Designation',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFC2),
              foregroundColor: Colors.black,
            ),
            child: const Text('Save & Capture', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await _dbService.addPerson(name, metadata: '{"role": "${roleController.text.trim()}"}');
                _voiceService.speak("Enrolled $name successfully.");
                Navigator.pop(ctx);
                _loadEnrolledFaces();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: const Text('BIOMETRICS', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Face ID & Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF00FFC2)),
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
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isVerified ? const Color(0xFF00FFC2) : Colors.orangeAccent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isVerified ? const Color(0xFF00FFC2) : Colors.orangeAccent,
                            width: 3,
                          ),
                          color: Colors.white10,
                        ),
                        child: Icon(
                          _isVerified ? Icons.face : Icons.face_retouching_natural,
                          size: 50,
                          color: _isVerified ? const Color(0xFF00FFC2) : Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isVerified ? 'VERIFIED: $_currentIdentity' : 'UNKNOWN IDENTITY',
                        style: TextStyle(
                          color: _isVerified ? const Color(0xFF00FFC2) : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(_currentConfidence * 100).toInt()}% • Distance: 0.24',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF21262D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          setState(() {
                            _isVerified = !_isVerified;
                            if (!_isVerified) {
                              _currentIdentity = "Unknown";
                              _currentConfidence = 0.45;
                              _voiceService.speak("Unrecognized person detected.");
                            } else {
                              _currentIdentity = "Soumya";
                              _currentConfidence = 0.96;
                              _voiceService.speak("Identity confirmed. Soumya detected.");
                            }
                          });
                        },
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Simulate Scan', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Matching Threshold Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recognition Threshold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${(_similarityThreshold * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00FFC2), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00FFC2),
              thumbColor: const Color(0xFF00FFC2),
            ),
            child: Slider(
              value: _similarityThreshold,
              min: 0.50,
              max: 0.95,
              divisions: 9,
              onChanged: (val) => setState(() => _similarityThreshold = val),
            ),
          ),

          const SizedBox(height: 20),

          // Enrolled Identities Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enrolled Faces (${_persons.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                onPressed: _showEnrollDialog,
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF00FFC2)),
                label: const Text('Add Face', style: TextStyle(color: Color(0xFF00FFC2), fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: _persons.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF21262D),
                          child: Text(
                            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF00FFC2), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: #${p.id} • Registered Member", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Colors.white54, size: 20),
                              onPressed: () => _voiceService.speak("Face database identity: ${p.name}"),
                            ),
                          ],
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
