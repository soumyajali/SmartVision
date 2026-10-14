import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/detection_history.dart';
import '../../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<DetectionHistory>> _historyFuture;
  late Future<List<Map<String, dynamic>>> _analysisHistoryFuture;
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    final dbService = context.read<DatabaseService>();
    setState(() {
      if (_filterQuery.isEmpty) {
        _historyFuture = dbService.getDetectionHistory();
      } else {
        _historyFuture = dbService.searchDetection(_filterQuery);
      }
      _analysisHistoryFuture = dbService.getAnalysisHistory(limit: 3);
    });
  }

  void _clearHistory() async {
    final dbService = context.read<DatabaseService>();
    await dbService.clearHistory();
    _loadHistory();
  }

  void _deleteRecord(int id) async {
    final dbService = context.read<DatabaseService>();
    await dbService.deleteDetection(id);
    _loadHistory();
  }

  void _showAnalysisDetails(Map<String, dynamic> record) {
    final details = record['details'];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record['analysis_type']?.toString() ?? 'Analysis',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record['summary']?.toString() ?? '',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(details),
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetectionDetails(DetectionHistory record) {
    final dateStr =
        DateFormat('MMMM dd, yyyy – HH:mm:ss').format(record.timestamp);
    final conf = (record.confidence * 100).toStringAsFixed(1);
    final bbox = record.boundingBox;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.objectName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonAccent),
                  ),
                  child: Text(
                    '$conf% MATCH',
                    style: const TextStyle(
                      color: AppColors.neonAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Timestamp', dateStr, Icons.access_time_rounded),
            const SizedBox(height: 8),
            _buildDetailRow('Database Record ID', '#${record.id ?? "N/A"}',
                Icons.tag_rounded),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Bounding Box',
              'X: ${bbox.left.toStringAsFixed(0)}, Y: ${bbox.top.toStringAsFixed(0)} (W: ${bbox.width.toStringAsFixed(0)}, H: ${bbox.height.toStringAsFixed(0)})',
              Icons.crop_free_rounded,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (record.id != null) {
                    _deleteRecord(record.id!);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete This Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brightViolet),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.secondaryText, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            tooltip: 'Clear All Records',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: const Text('Clear All History',
                      style: TextStyle(color: AppColors.primaryText)),
                  content: const Text(
                    'Are you sure you want to permanently erase all saved detection and media analysis records?',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      child: const Text('Erase All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Filter detections by label...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.neonAccent),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: AppColors.mutedText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filterQuery = '';
                            _loadHistory();
                          });
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _filterQuery = val.trim();
                  _loadHistory();
                });
              },
            ),
          ),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _analysisHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Could not load media analysis history: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }
              final analyses = snapshot.data ?? const [];
              if (analyses.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Recent Media Analyses',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...analyses.map((record) {
                      final timestamp = DateTime.tryParse(
                          record['timestamp']?.toString() ?? '');
                      return Card(
                        color: AppColors.cardBackground,
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.analytics_outlined,
                            color: AppColors.neonAccent,
                          ),
                          title: Text(
                            record['analysis_type']?.toString() ?? 'Analysis',
                            style:
                                const TextStyle(color: AppColors.primaryText),
                          ),
                          subtitle: Text(
                            '${record['summary'] ?? ''}'
                            '${timestamp == null ? '' : ' · ${DateFormat('MMM dd, HH:mm').format(timestamp)}'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(color: AppColors.secondaryText),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.mutedText,
                          ),
                          onTap: () => _showAnalysisDetails(record),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // Detection List
          Expanded(
            child: FutureBuilder<List<DetectionHistory>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading history: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error)),
                  );
                }

                final history = snapshot.data ?? [];

                if (history.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.history_toggle_off_rounded,
                                size: 48, color: AppColors.mutedText),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Detection Records Found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Detected objects will automatically appear here once real-time tracking is active.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    final dateString = DateFormat('MMM dd, yyyy • HH:mm:ss')
                        .format(record.timestamp);
                    final confidence =
                        (record.confidence * 100).toStringAsFixed(1);

                    return Dismissible(
                      key: Key('record_${record.id}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_forever_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text('DELETE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        if (record.id != null) {
                          _deleteRecord(record.id!);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          onTap: () => _showDetectionDetails(record),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryViolet
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.center_focus_strong_rounded,
                                color: AppColors.neonAccent, size: 22),
                          ),
                          title: Text(
                            record.objectName.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryText),
                          ),
                          subtitle: Text(dateString,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
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
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
