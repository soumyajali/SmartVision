import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../services/camera_service.dart';
import '../../services/document_screening_service.dart';
import '../../services/smartvision_api_service.dart';
import '../../services/speech_service.dart';

class DocumentScreeningScreen extends StatefulWidget {
  const DocumentScreeningScreen({super.key});

  @override
  State<DocumentScreeningScreen> createState() => _DocumentScreeningScreenState();
}

class _DocumentScreeningScreenState extends State<DocumentScreeningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SmartVisionApiService _apiService = SmartVisionApiService();
  final DocumentScreeningService _screeningService = DocumentScreeningService();

  // OCR state
  bool _isOcrProcessing = false;
  String _extractedText = "";
  String _selectedLanguage = "Hindi";
  String _translatedText = "";
  bool _isTranslating = false;
  String _summaryText = "";
  bool _isSummarizing = false;

  final List<String> _languages = [
    "Hindi",
    "Kannada",
    "Telugu",
    "Tamil",
    "Malayalam",
    "Marathi",
    "Bengali",
    "Gujarati",
    "Punjabi",
    "Spanish",
    "French",
    "German",
    "Chinese (simplified)",
    "Japanese",
    "Russian",
    "Arabic",
  ];

  // Screening state
  bool _isProcessingScreening = false;
  ScreeningResult? _screeningResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _screeningService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _extractTextFromSource(String source) async {
    setState(() {
      _isOcrProcessing = true;
      _extractedText = "";
      _translatedText = "";
      _summaryText = "";
    });

    try {
      String b64Image = "";
      if (source == 'Camera') {
        final cameraService = context.read<CameraService>();
        if (cameraService.controller != null && cameraService.isInitialized) {
          final xfile = await cameraService.controller!.takePicture();
          final bytes = await xfile.readAsBytes();
          b64Image = base64Encode(bytes);
        } else {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.camera);
          if (picked == null) {
            setState(() => _isOcrProcessing = false);
            return;
          }
          final bytes = await picked.readAsBytes();
          b64Image = base64Encode(bytes);
        }
      } else if (source == 'Upload') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          setState(() => _isOcrProcessing = false);
          return;
        }
        final bytes = await picked.readAsBytes();
        b64Image = base64Encode(bytes);
      } else {
        final bytes = await rootBundle.load('assets/samples/document.png');
        b64Image = base64Encode(bytes.buffer.asUint8List());
      }

      final result = await _apiService.extractOCR(base64Image: b64Image);
      final List texts = result['texts'] ?? [];
      String joined = texts.map((t) => t['text'] ?? '').where((s) => s.isNotEmpty).join('\n');
      if (joined.isEmpty) {
        joined = "No legible text was found in this document. Please ensure good lighting and text focus.";
      }

      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _extractedText = joined;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _extractedText = "Error during OCR processing: $e";
        });
      }
    }
  }

  Future<void> _runTranslation() async {
    if (_extractedText.isEmpty) return;
    setState(() => _isTranslating = true);

    try {
      final res = await _apiService.translateText(
        text: _extractedText,
        targetLang: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedText = res;
        });
        context.read<SpeechService>().speak('Translation to $_selectedLanguage complete.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Translation error: $e')));
      }
    }
  }

  Future<void> _runSummarization() async {
    if (_extractedText.isEmpty) return;
    setState(() => _isSummarizing = true);

    try {
      final res = await _apiService.summarizeText(
        text: _extractedText,
        maxSentences: 3,
      );
      if (mounted) {
        setState(() {
          _isSummarizing = false;
          _summaryText = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSummarizing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Summarization error: $e')));
      }
    }
  }

  void _runDocumentVerification() {
    setState(() => _isProcessingScreening = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final textToScreen = _extractedText.isNotEmpty
          ? _extractedText
          : "SMART VISION AI SYSTEM\nGOVERNMENT OF KARNATAKA / AIET\nIDENTITY DOCUMENT AUTHENTICATED";
      final result = _screeningService.screenDocument(textToScreen);
      setState(() {
        _isProcessingScreening = false;
        _screeningResult = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('OCR & Document Processing'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonAccent,
          labelColor: AppColors.neonAccent,
          unselectedLabelColor: AppColors.secondaryText,
          tabs: const [
            Tab(icon: Icon(Icons.document_scanner_rounded), text: 'OCR & Translation'),
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Document Screening'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOcrAndTranslationTab(),
          _buildScreeningTab(),
        ],
      ),
    );
  }

  Widget _buildOcrAndTranslationTab() {
    final speechService = context.read<SpeechService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Source Selector Card
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
              const Text('Select Input Media for OCR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Camera', style: TextStyle(fontSize: 12)),
                      onPressed: _isOcrProcessing ? null : () => _extractTextFromSource('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.elevatedSurface,
                        foregroundColor: AppColors.neonAccent,
                        side: const BorderSide(color: AppColors.neonAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('Upload', style: TextStyle(fontSize: 12)),
                      onPressed: _isOcrProcessing ? null : () => _extractTextFromSource('Upload'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text('Sample ID', style: TextStyle(fontSize: 12)),
                      onPressed: _isOcrProcessing ? null : () => _extractTextFromSource('Sample'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Extracted Text Card
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
                  const Text('Extracted Text (EasyOCR)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  if (_extractedText.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.neonAccent, size: 20),
                      tooltip: 'Read text aloud',
                      onPressed: () => speechService.speak(_extractedText),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isOcrProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: AppColors.neonAccent),
                  ),
                )
              else if (_extractedText.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No text extracted yet. Choose an image above.', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                )
              else
                SelectableText(
                  _extractedText,
                  style: const TextStyle(fontSize: 13, color: AppColors.primaryText, height: 1.4, fontFamily: 'monospace'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Translation Card
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
              const Text('Multi-Language Translation (18 Languages)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      dropdownColor: AppColors.elevatedSurface,
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.elevatedSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (_extractedText.isEmpty || _isTranslating) ? null : _runTranslation,
                    child: _isTranslating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Translate', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_translatedText.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_selectedLanguage Translation:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonAccent)),
                      const SizedBox(height: 6),
                      SelectableText(
                        _translatedText,
                        style: const TextStyle(fontSize: 13, color: AppColors.primaryText, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Summarization Card
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
                  const Text('Document Summarization', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.elevatedSurface,
                      foregroundColor: AppColors.neonAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.neonAccent),
                      ),
                    ),
                    icon: _isSummarizing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonAccent))
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Summarize', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: (_extractedText.isEmpty || _isSummarizing) ? null : _runSummarization,
                  ),
                ],
              ),
              if (_summaryText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _summaryText,
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryText, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScreeningTab() {
    return ListView(
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
              const Text('Identity & Document Authenticator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 6),
              const Text('Screens documents against regulatory patterns, valid IDs, expiration dates, and security seals.', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isProcessingScreening
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_rounded, size: 20),
                label: const Text('Run Document Screening'),
                onPressed: _isProcessingScreening ? null : _runDocumentVerification,
              ),
            ],
          ),
        ),
        if (_screeningResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _screeningResult!.isPass ? const Color(0xFF10B981) : AppColors.error,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _screeningResult!.isPass ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: _screeningResult!.isPass ? const Color(0xFF10B981) : AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _screeningResult!.isPass ? 'VERIFIED VALID DOCUMENT' : 'DOCUMENT FLAGGED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _screeningResult!.isPass ? const Color(0xFF10B981) : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Checksum: ${_screeningResult!.mrzDetail}', style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Biometrics: ${_screeningResult!.faceMatchDetail}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
