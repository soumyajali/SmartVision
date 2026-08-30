import 'package:flutter/material.dart';
import '../../services/document_screening_service.dart';
import '../../core/constants/app_colors.dart';

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
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.card,
                  ),
                  child: const Icon(Icons.badge_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('ID & Document Screening', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                    Text('Automated border control verification (TFLite Edge Processing)', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content (Dual Input)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildInputCard('Passport / ID Document', Icons.document_scanner),
                              const SizedBox(width: 24),
                              _buildInputCard('Live Person Capture', Icons.face),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _startVerification,
                            icon: _isProcessing 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.verified_user, color: Colors.white),
                            label: Text(_isProcessing ? 'Verifying Identity...' : 'Start AI Verification', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Results Panel
                  Expanded(
                    flex: 1,
                    child: _buildResultsPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String title, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textMain)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, size: 48, color: AppColors.border),
                    const SizedBox(height: 16),
                    const Text('Upload or Capture', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.textMain,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.border),
                        )
                      ),
                      child: const Text('Select Source'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Text('Verification Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          ),
          
          if (_result == null && !_isProcessing)
            const Expanded(
              child: Center(
                child: Text('Run verification to see results.', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ),
            
          if (_isProcessing)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing Security Features...', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            
          if (_result != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Master Status
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: _result!.isPass ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _result!.isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              _result!.isPass ? Icons.check_circle : Icons.cancel,
                              color: _result!.isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _result!.isPass ? 'CLEAR TO PASS' : 'FRAUD DETECTED',
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: _result!.isPass ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Checklist
                    _buildChecklistItem('MRZ Checksum', _result!.mrzValid, _result!.mrzDetail),
                    const SizedBox(height: 16),
                    _buildChecklistItem('Face Match', _result!.faceMatch, _result!.faceMatchDetail),
                    const SizedBox(height: 16),
                    _buildChecklistItem('Document Expiry', _result!.expiryValid, _result!.expiryDetail),
                    const SizedBox(height: 16),
                    _buildChecklistItem('Tamper Check', _result!.tamperCheckPass, _result!.tamperDetail),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
  
  Widget _buildChecklistItem(String title, bool pass, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          pass ? Icons.check_circle : Icons.error,
          color: pass ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        )
      ],
    );
  }
}
