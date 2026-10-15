import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/supported_languages.dart';
import '../../services/camera_service.dart';
import '../../services/database_service.dart';
import '../../services/on_device_ai_service.dart';
import '../../services/speech_service.dart';

class DocumentScreeningScreen extends StatefulWidget {
  const DocumentScreeningScreen({super.key});

  @override
  State<DocumentScreeningScreen> createState() =>
      _DocumentScreeningScreenState();
}

class _DocumentScreeningScreenState extends State<DocumentScreeningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OnDeviceAiService _aiService = OnDeviceAiService.instance;

  // OCR state
  bool _isOcrProcessing = false;
  bool _isVideoOcrProcessing = false;
  String _extractedText = "";
  final TextEditingController _extractedTextController =
      TextEditingController();
  String _selectedLanguage = "Hindi";
  String _translatedText = "";
  bool _isTranslating = false;
  String _summaryText = "";
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final saved = await context
          .read<DatabaseService>()
          .getAppSetting('translation_language');
      if (saved != null &&
          supportedTranslationLanguages.contains(saved) &&
          mounted) {
        setState(() => _selectedLanguage = saved);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load language preference: $error')),
      );
    }
  }

  Future<void> _selectLanguage(String language) async {
    setState(() => _selectedLanguage = language);
    try {
      await context
          .read<DatabaseService>()
          .setAppSetting('translation_language', language);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save language preference: $error')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _extractedTextController.dispose();
    super.dispose();
  }

  Future<void> _extractTextFromSource(String source) async {
    final database = context.read<DatabaseService>();
    setState(() {
      _isOcrProcessing = true;
      _extractedText = "";
      _extractedTextController.clear();
      _translatedText = "";
      _summaryText = "";
    });

    try {
      Uint8List imageBytes;
      if (source == 'Camera') {
        final cameraService = context.read<CameraService>();
        if (cameraService.controller != null && cameraService.isInitialized) {
          final xfile = await cameraService.controller!.takePicture();
          imageBytes = await xfile.readAsBytes();
          await File(xfile.path).delete();
        } else {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.camera);
          if (picked == null) {
            setState(() => _isOcrProcessing = false);
            return;
          }
          imageBytes = await picked.readAsBytes();
        }
      } else if (source == 'Upload') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          setState(() => _isOcrProcessing = false);
          return;
        }
        imageBytes = await picked.readAsBytes();
      } else {
        final bytes = await rootBundle.load('assets/samples/document.png');
        imageBytes = bytes.buffer.asUint8List();
      }

      final joined = await _aiService.recognizeTextFromBytes(imageBytes);
      final textLines =
          joined.split('\n').where((line) => line.trim().isNotEmpty).length;
      if (joined.isEmpty) {
        throw StateError(
          'No readable text was found. Try a sharper image with better lighting.',
        );
      }
      try {
        await database.insertAnalysisHistory(
          analysisType: 'Image OCR',
          summary: '$textLines text line(s) recognized on device',
          details: {'text': joined},
        );
      } catch (storageError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'OCR completed, but history save failed: $storageError')),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _extractedText = joined;
          _extractedTextController.text = joined;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _extractedText = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e')),
        );
      }
    }
  }

  Future<void> _runVideoOcr(ImageSource source) async {
    if (_isVideoOcrProcessing) return;
    final database = context.read<DatabaseService>();
    try {
      final video = await ImagePicker().pickVideo(source: source);
      if (video == null || !mounted) return;
      setState(() {
        _isVideoOcrProcessing = true;
        _isOcrProcessing = false;
        _extractedText = '';
        _extractedTextController.clear();
        _translatedText = '';
        _summaryText = '';
      });
      final result = await _aiService.recognizeTextFromVideo(video.path);
      final extracted = result['full_text']?.toString() ?? '';
      try {
        await database.insertAnalysisHistory(
          analysisType: 'Video OCR',
          summary:
              '${result['total_frames_processed'] ?? 0} frames processed · '
              '${extracted.isEmpty ? 'No text found' : 'Text extracted'}',
          details: {
            'video': video.name,
            ...result,
          },
        );
      } catch (storageError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Video OCR completed, but history save failed: $storageError')),
          );
        }
      }
      if (mounted) {
        setState(() {
          _isVideoOcrProcessing = false;
          _extractedText = extracted;
          _extractedTextController.text = extracted;
        });
        if (extracted.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No readable text was detected in the video.')),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isVideoOcrProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video OCR failed: $error')),
      );
    }
  }

  Future<void> _runTranslation() async {
    if (_extractedText.isEmpty) return;
    setState(() => _isTranslating = true);

    try {
      final res = await _aiService.translateText(
        text: _extractedText,
        targetLanguage: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedText = res;
        });
        context
            .read<SpeechService>()
            .speak('Translation to $_selectedLanguage complete.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Translation error: $e')));
      }
    }
  }

  Future<void> _runSummarization() async {
    if (_extractedText.isEmpty) return;
    setState(() => _isSummarizing = true);

    try {
      final res = _aiService.summarizeText(_extractedText, maxSentences: 3);
      if (mounted) {
        setState(() {
          _isSummarizing = false;
          _summaryText = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSummarizing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Summarization error: $e')));
      }
    }
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
            Tab(
                icon: Icon(Icons.document_scanner_rounded),
                text: 'OCR & Translation'),
            Tab(
                icon: Icon(Icons.verified_user_rounded),
                text: 'Document Screening'),
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
              const Text('Select Input Media for OCR',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label:
                          const Text('Camera', style: TextStyle(fontSize: 12)),
                      onPressed: _isOcrProcessing
                          ? null
                          : () => _extractTextFromSource('Camera'),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label:
                          const Text('Upload', style: TextStyle(fontSize: 12)),
                      onPressed: _isOcrProcessing
                          ? null
                          : () => _extractTextFromSource('Upload'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text('Sample ID',
                          style: TextStyle(fontSize: 12)),
                      onPressed: _isOcrProcessing
                          ? null
                          : () => _extractTextFromSource('Sample'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isOcrProcessing || _isVideoOcrProcessing
                          ? null
                          : () => _runVideoOcr(ImageSource.gallery),
                      icon: const Icon(Icons.video_library_outlined, size: 16),
                      label: const Text('Video OCR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isOcrProcessing || _isVideoOcrProcessing
                          ? null
                          : () => _runVideoOcr(ImageSource.camera),
                      icon: const Icon(Icons.videocam_outlined, size: 16),
                      label: const Text('Record Video'),
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
                  const Text('Extracted Text (EasyOCR)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText)),
                  if (_extractedText.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: AppColors.neonAccent, size: 20),
                          tooltip: 'Copy extracted text',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _extractedText),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Text copied')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded,
                              color: AppColors.neonAccent, size: 20),
                          tooltip: 'Read text aloud',
                          onPressed: () => speechService.speak(_extractedText),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isOcrProcessing || _isVideoOcrProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child:
                        CircularProgressIndicator(color: AppColors.neonAccent),
                  ),
                )
              else if (_extractedText.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                      'No text extracted yet. Choose an image or video above.',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 12)),
                )
              else
                TextField(
                  controller: _extractedTextController,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (value) => _extractedText = value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryText,
                    height: 1.4,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Extracted text will appear here and can be edited.',
                    hintStyle: const TextStyle(color: AppColors.mutedText),
                    filled: true,
                    fillColor: AppColors.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
              const Text('Multi-Language Translation (18 Languages)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      dropdownColor: AppColors.elevatedSurface,
                      style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.elevatedSurface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                      items: supportedTranslationLanguages
                          .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _selectLanguage(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (_extractedText.isEmpty || _isTranslating)
                        ? null
                        : _runTranslation,
                    child: _isTranslating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Translate',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                    border: Border.all(
                        color: AppColors.neonAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_selectedLanguage Translation:',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonAccent)),
                      const SizedBox(height: 6),
                      SelectableText(
                        _translatedText,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryText,
                            height: 1.4),
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
                  const Text('Document Summarization',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText)),
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
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.neonAccent))
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Summarize',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: (_extractedText.isEmpty || _isSummarizing)
                        ? null
                        : _runSummarization,
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
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryText,
                        height: 1.4),
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
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Document authenticity checks are unavailable',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'On-device OCR extracts text only. It does not verify document authenticity, expiry, MRZ data, or tampering.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.secondaryText, height: 1.45),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Open OCR & Translation'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
