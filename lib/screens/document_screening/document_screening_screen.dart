import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/document_screening_service.dart';

class DocumentScreeningScreen extends StatefulWidget {
  const DocumentScreeningScreen({super.key});

  @override
  State<DocumentScreeningScreen> createState() => _DocumentScreeningScreenState();
}

class _DocumentScreeningScreenState extends State<DocumentScreeningScreen> {
  final DocumentScreeningService _screeningService = DocumentScreeningService();

  bool _isProcessing = false;
  ScreeningResult? _result;

  @override
  void initState() {
    super.initState();
    _screeningService.initialize();
  }

  Future<void> _startVerification() async {
    setState(() {
      _isProcessing = true;
      _result = null;
    });

    final result = await _screeningService.verifyIdentity(null, null);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('ID & Document Screening'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.neonAccent),
            tooltip: 'Reset Screening',
            onPressed: () {
              setState(() {
                _result = null;
                _isProcessing = false;
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 700;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header description banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryViolet.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.badge_outlined, color: AppColors.neonAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Automated Document Verification',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'MRZ checksum analysis, face matching & tamper detection',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Inputs (Responsive: Row on desktop, Column on mobile)
              if (isSmall) ...[
                _buildInputCard('Passport / ID Document', Icons.document_scanner_rounded),
                const SizedBox(height: 12),
                _buildInputCard('Live Person Face Capture', Icons.face_rounded),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildInputCard('Passport / ID Document', Icons.document_scanner_rounded)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputCard('Live Person Face Capture', Icons.face_rounded)),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Verification Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _startVerification,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_rounded, color: Colors.white),
                  label: Text(
                    _isProcessing ? 'ANALYZING SECURITY FEATURES...' : 'START AI VERIFICATION',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Verification Results Section
              _buildResultsPanel(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputCard(String title, IconData icon) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: AppColors.neonAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryText),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.brightViolet.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture or Select Source',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document source selected')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Select Input', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.fact_check_outlined, color: AppColors.neonAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Verification Assessment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText),
                ),
              ],
            ),
          ),

          if (_result == null && !_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 36, color: AppColors.mutedText),
                    SizedBox(height: 8),
                    Text(
                      'Ready to Screen',
                      style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Run verification above to execute MRZ parsing and neural face matching.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.neonAccent),
                    SizedBox(height: 16),
                    Text(
                      'Extracting security features & matching biometric vectors...',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          if (_result != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // Master Result Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _result!.isPass
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _result!.isPass ? AppColors.success : AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            _result!.isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: _result!.isPass ? AppColors.success : AppColors.error,
                            size: 44,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.isPass ? 'CLEAR TO PASS' : 'FRAUD DETECTED',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: _result!.isPass ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detail Checklist
                  _buildChecklistItem('MRZ Checksum', _result!.mrzValid, _result!.mrzDetail),
                  const SizedBox(height: 12),
                  _buildChecklistItem('Face Match', _result!.faceMatch, _result!.faceMatchDetail),
                  const SizedBox(height: 12),
                  _buildChecklistItem('Document Expiry', _result!.expiryValid, _result!.expiryDetail),
                  const SizedBox(height: 12),
                  _buildChecklistItem('Tamper Check', _result!.tamperCheckPass, _result!.tamperDetail),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool pass, String detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pass ? Icons.check_circle_rounded : Icons.error_rounded,
            color: pass ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
