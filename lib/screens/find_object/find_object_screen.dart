import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/search_history.dart';
import '../../services/database_service.dart';

class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({super.key});

  @override
  State<FindObjectScreen> createState() => _FindObjectScreenState();
}

class _FindObjectScreenState extends State<FindObjectScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTarget = 'person';
  Future<List<SearchHistory>>? _searchHistoryFuture;

  final List<String> _quickTargets = [
    'person',
    'cell phone',
    'backpack',
    'bottle',
    'laptop',
    'cup',
    'book',
    'chair',
    'car',
    'dog',
    'cat',
    'umbrella',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSearchHistory() {
    final db = context.read<DatabaseService>();
    setState(() {
      _searchHistoryFuture = db.getSearchHistory();
    });
  }

  Future<void> _launchTargetSearch(String target) async {
    final cleanTarget = target.trim().toLowerCase();
    if (cleanTarget.isEmpty) return;

    final db = context.read<DatabaseService>();
    final detectionCtrl = context.read<DetectionController>();

    // Set active target in controller
    detectionCtrl.setSearchTarget(cleanTarget);

    // Save to SQLite
    final entry = SearchHistory(
      targetObject: cleanTarget,
      found: false,
      timestamp: DateTime.now(),
    );
    await db.insertSearchHistory(entry);

    if (mounted) {
      context.push('/camera_detection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Target Object Lookup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Search & Filter Box
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
                const Text(
                  'Search Target Item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: InputDecoration(
                          hintText: 'Enter object (e.g. cell phone, backpack)...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neonAccent),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.mutedText, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val.trim().isNotEmpty) {
                              _selectedTarget = val.trim().toLowerCase();
                            }
                          });
                        },
                        onSubmitted: (val) => _launchTargetSearch(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      ),
                      onPressed: () => _launchTargetSearch(_selectedTarget),
                      child: const Icon(Icons.radar_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Presets
          const Text(
            'Quick Preset Targets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTargets.map((target) {
              final isSelected = _selectedTarget == target;
              return ChoiceChip(
                label: Text(
                  target.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.secondaryText,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryViolet,
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.neonAccent : AppColors.border,
                  ),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedTarget = target;
                      _searchController.text = target;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Target Lock-On Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF261245), Color(0xFF140D24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neonAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gps_fixed_rounded, color: AppColors.neonAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Target Selection', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                          Text(
                            _selectedTarget.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.neonAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'When camera detector identifies this object, high-priority audio alert and bounding reticles are activated.',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => _launchTargetSearch(_selectedTarget),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: const Text('LOCK TARGET & OPEN SCANNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Target Search History
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Search Query History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText)),
              Text('Stored in SQLite', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 10),
          _buildSearchHistoryList(),
        ],
      ),
    );
  }

  Widget _buildSearchHistoryList() {
    return FutureBuilder<List<SearchHistory>>(
      future: _searchHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No previous target searches yet.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: history.take(6).map((item) {
              final dateStr = DateFormat('MMM d, HH:mm').format(item.timestamp);
              return ListTile(
                leading: const Icon(Icons.saved_search_rounded, color: AppColors.brightViolet, size: 20),
                title: Text(item.targetObject.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryText)),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.neonAccent, size: 18),
                  tooltip: 'Search Again',
                  onPressed: () {
                    setState(() {
                      _selectedTarget = item.targetObject;
                      _searchController.text = item.targetObject;
                    });
                    _launchTargetSearch(item.targetObject);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
