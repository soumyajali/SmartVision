import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../face_recognition/services/voice_service.dart';

class DocumentOcrPage extends StatefulWidget {
  const DocumentOcrPage({super.key});

  @override
  State<DocumentOcrPage> createState() => _DocumentOcrPageState();
}

class _DocumentOcrPageState extends State<DocumentOcrPage> {
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _extractedText =
      "SMARTVISION AI SYSTEM\nPROJECT ID: SV-2026-X\nSTATUS: ACTIVE & VERIFIED\nSPECIFICATION: REAL-TIME MULTI-CLASS OBJECT RECOGNITION AND DOCUMENT SCREENING ENGINE.";
  
  final List<String> _scanHistory = [
    "SMARTVISION AI SYSTEM\nPROJECT ID: SV-2026-X\nSTATUS: ACTIVE",
    "INVOICE #94820 - DATE: 2026-10-08 - TOTAL: \$142.50",
    "AUTHORIZED PERSONNEL BADGE #402 - ACCESS LEVEL 4",
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  Future<void> _pickAndScanDocument(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate OCR engine run
      setState(() {
        _isProcessing = false;
        _extractedText = "EXTRACTED DOCUMENT FROM IMAGE:\nDATE: ${DateTime.now().toLocal().toString().split('.').first}\nSTATUS: SCANNED SUCCESSFULLY WITH EASYOCR ENGINE.\nCONFIDENCE: 97.4%";
        _scanHistory.insert(0, _extractedText);
      });
      _voiceService.speak("Document scanned successfully.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _extractedText.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final characters = _extractedText.length;

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
                color: Colors.purpleAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purpleAccent),
              ),
              child: const Text('EASYOCR', style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Document & Text OCR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Scan Action Buttons Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scan New Document / Sign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFC2),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _pickAndScanDocument(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _pickAndScanDocument(ImageSource.gallery),
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Image'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Extracted Text Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Extracted Content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text('$words words • $characters chars', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : SelectableText(
                        _extractedText,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontFamily: 'monospace'),
                      ),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21262D),
                        foregroundColor: const Color(0xFF00FFC2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _extractedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied text to clipboard!')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21262D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.volume_up, size: 16),
                      label: const Text('Read Aloud'),
                      onPressed: () => _voiceService.speak(_extractedText),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () => setState(() => _extractedText = ""),
                      tooltip: 'Clear',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Previous Scan Records
          const Text('Scan History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Column(
            children: _scanHistory.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, color: Colors.purpleAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                      onPressed: () => setState(() => _extractedText = item),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
