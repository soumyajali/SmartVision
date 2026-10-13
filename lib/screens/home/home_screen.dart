import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/statistics_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/detection_history.dart';
import '../../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<DetectionHistory>>? _recentHistoryFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsController>().refreshData();
      _loadRecentHistory();
    });
  }

  void _loadRecentHistory() {
    final db = context.read<DatabaseService>();
    setState(() {
      _recentHistoryFuture = db.getDetectionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: RefreshIndicator(
        color: AppColors.neonAccent,
        backgroundColor: AppColors.elevatedSurface,
        onRefresh: () async {
          await context.read<StatisticsController>().refreshData();
          _loadRecentHistory();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          children: [
            // Welcome & System Status Bar
            _buildHeader(),
            const SizedBox(height: 18),

            // Prominent Hero Live Vision Scanner Card
            _buildHeroScannerCard(context),
            const SizedBox(height: 24),

            // Quick Access Modules Section
            _buildSectionHeader('AI Vision Modules', 'Core recognition engines'),
            const SizedBox(height: 12),
            _buildModuleGrid(context),
            const SizedBox(height: 24),

            // Real SQLite Statistics
            _buildSectionHeader('Neural Telemetry', 'SQLite database metrics'),
            const SizedBox(height: 12),
            _buildTelemetryCards(context),
            const SizedBox(height: 24),

            // Recent Detections Activity Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Recent Detection Feed', 'Latest logged occurrences'),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('View All', style: TextStyle(color: AppColors.brightViolet, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentDetectionsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              gradient: const LinearGradient(
                colors: [AppColors.primaryViolet, AppColors.deepViolet],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartVision AI Sentinel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Real-time multi-class perception engine',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScannerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C164D), Color(0xFF160E26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryViolet.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/camera_detection'),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.neonAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, color: AppColors.neonAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'LIVE INFERENCE',
                            style: TextStyle(
                              color: AppColors.neonAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.neonAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Launch Real-Time Camera',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Stream camera feed with on-device YOLO bounding boxes, confidence telemetry, and speech announcements.',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => context.push('/camera_detection'),
                    icon: const Icon(Icons.videocam_rounded, size: 20),
                    label: const Text(
                      'START DETECTION SCANNER',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
        ),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildModuleCard(
          context,
          title: 'ID Screening',
          subtitle: 'MRZ & anti-tamper',
          icon: Icons.badge_outlined,
          color: AppColors.brightViolet,
          route: '/document_screening',
        ),
        _buildModuleCard(
          context,
          title: 'Find Object',
          subtitle: 'Target lock-on search',
          icon: Icons.search_rounded,
          color: AppColors.neonAccent,
          route: '/find_object',
        ),
        _buildModuleCard(
          context,
          title: 'Threat Alerts',
          subtitle: 'Weapon & hazard guard',
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          route: '/alerts',
        ),
        _buildModuleCard(
          context,
          title: 'Face Biometrics',
          subtitle: 'Identity verification',
          icon: Icons.face_rounded,
          color: AppColors.success,
          route: '/face_id',
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(route),
          splashColor: color.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.mutedText),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCards(BuildContext context) {
    return Consumer<StatisticsController>(
      builder: (context, controller, child) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildStatItem('Total Detections', controller.totalDetections.toString(), Icons.analytics_outlined, AppColors.primaryViolet),
            _buildStatItem('Today\'s Activity', controller.todayDetections.toString(), Icons.today_rounded, AppColors.neonAccent),
            _buildStatItem('Unique Classes', controller.uniqueObjects.toString(), Icons.category_rounded, AppColors.brightViolet),
            _buildStatItem('Top Detected', controller.mostDetected, Icons.star_rounded, AppColors.warning),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDetectionsList() {
    return FutureBuilder<List<DetectionHistory>>(
      future: _recentHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 36, color: AppColors.mutedText),
                  SizedBox(height: 8),
                  Text('No detection logs recorded yet', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Point your camera at objects to populate neural history.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        // Show latest 3
        final previewItems = items.take(3).toList();
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: previewItems.map((record) {
              final dateStr = DateFormat('MMM d, HH:mm').format(record.timestamp);
              final confidence = (record.confidence * 100).toStringAsFixed(0);

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.center_focus_strong_rounded, color: AppColors.neonAccent, size: 18),
                ),
                title: Text(
                  record.objectName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryText),
                ),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$confidence%',
                    style: const TextStyle(
                      color: AppColors.neonAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
