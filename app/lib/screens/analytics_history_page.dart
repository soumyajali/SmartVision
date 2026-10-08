import 'package:flutter/material.dart';

class AnalyticsHistoryPage extends StatefulWidget {
  const AnalyticsHistoryPage({super.key});

  @override
  State<AnalyticsHistoryPage> createState() => _AnalyticsHistoryPageState();
}

class _AnalyticsHistoryPageState extends State<AnalyticsHistoryPage> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _historyLogs = [
    {'id': 101, 'name': 'Person', 'confidence': 0.95, 'time': '22:12:15', 'category': 'Human'},
    {'id': 102, 'name': 'Cell phone', 'confidence': 0.89, 'time': '22:10:40', 'category': 'Electronic'},
    {'id': 103, 'name': 'Laptop', 'confidence': 0.92, 'time': '22:08:12', 'category': 'Electronic'},
    {'id': 104, 'name': 'Bottle', 'confidence': 0.84, 'time': '21:55:04', 'category': 'Object'},
    {'id': 105, 'name': 'Knife', 'confidence': 0.91, 'time': '21:40:22', 'category': 'Hazard'},
    {'id': 106, 'name': 'Chair', 'confidence': 0.78, 'time': '21:22:19', 'category': 'Furniture'},
    {'id': 107, 'name': 'Backpack', 'confidence': 0.86, 'time': '20:15:33', 'category': 'Accessory'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _historyLogs.where((log) {
      if (_searchQuery.isEmpty) return true;
      return (log['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (log['category'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
                color: Colors.tealAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.tealAccent),
              ),
              child: const Text('ANALYTICS', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Metrics & History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 4 Executive KPI Cards (Matching Streamlit metrics)
          Row(
            children: [
              _buildMetricCard('Total Detections', '1,428', '+12%', const Color(0xFF00FFC2)),
              const SizedBox(width: 10),
              _buildMetricCard("Today's Count", '142', '+8 today', Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricCard('Hazard Alerts', '9', '2 active', Colors.redAccent),
              const SizedBox(width: 10),
              _buildMetricCard('Avg Confidence', '89.4%', 'High precision', Colors.amberAccent),
            ],
          ),

          const SizedBox(height: 24),

          // Object Distribution Chart Breakdown (Matching Streamlit plotly bars)
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
                const Text('Top Detected Classes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 14),
                _buildBarProgress('Person', 0.45, '45%', const Color(0xFF00FFC2)),
                _buildBarProgress('Cell Phone', 0.25, '25%', Colors.blueAccent),
                _buildBarProgress('Laptop', 0.15, '15%', Colors.purpleAccent),
                _buildBarProgress('Bottle', 0.10, '10%', Colors.amberAccent),
                _buildBarProgress('Hazards (Knife/Fire)', 0.05, '5%', Colors.redAccent),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search and History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Detection Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {
                  setState(() => _historyLogs.clear());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared history logs')));
                },
                child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Filter by object name or category...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
              filled: true,
              fillColor: const Color(0xFF161B22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 10),

          // History Log Items
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No matching records found.', style: TextStyle(color: Colors.white38))),
            )
          else
            Column(
              children: filtered.map((log) {
                final isHazard = log['category'] == 'Hazard';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isHazard ? Colors.redAccent.withOpacity(0.5) : Colors.white12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isHazard ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF21262D),
                      child: Icon(
                        isHazard ? Icons.warning : Icons.remove_red_eye,
                        color: isHazard ? Colors.redAccent : const Color(0xFF00FFC2),
                        size: 18,
                      ),
                    ),
                    title: Text(log['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("${log['category']} • ${log['time']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF21262D), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            "${((log['confidence'] as double) * 100).toInt()}%",
                            style: TextStyle(
                              color: isHazard ? Colors.redAccent : const Color(0xFF00FFC2),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
                          onPressed: () {
                            setState(() => _historyLogs.removeWhere((item) => item['id'] == log['id']));
                          },
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

  Widget _buildMetricCard(String title, String value, String change, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(change, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarProgress(String label, double percent, String percentText, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(percentText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFF21262D),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
