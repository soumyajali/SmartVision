import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/face_database_service.dart';

class RecognitionHistoryScreen extends StatefulWidget {
  const RecognitionHistoryScreen({super.key});

  @override
  State<RecognitionHistoryScreen> createState() => _RecognitionHistoryScreenState();
}

class _RecognitionHistoryScreenState extends State<RecognitionHistoryScreen> {
  final FaceDatabaseService _dbService = FaceDatabaseService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) {
      setState(() {
        _history = [];
        _isLoading = false;
      });
      return;
    }
    // Join with KnownPersons to get the name
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT h.id, h.confidence, h.timestamp, p.name 
      FROM RecognitionHistory h
      LEFT JOIN KnownPersons p ON h.personId = p.id
      ORDER BY h.timestamp DESC
      LIMIT 100
    ''');
    
    setState(() {
      _history = maps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recognition History")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text("No recognitions logged yet."))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final h = _history[index];
                    final String name = h['name'] ?? "Unknown Person";
                    final double conf = h['confidence'];
                    final String time = h['timestamp'].toString().split('.').first;
                    
                    return ListTile(
                      leading: Icon(
                        name == "Unknown Person" ? Icons.warning : Icons.check_circle,
                        color: name == "Unknown Person" ? Colors.orange : Colors.green,
                      ),
                      title: Text(name),
                      subtitle: Text("Confidence: ${(conf * 100).toStringAsFixed(1)}%"),
                      trailing: Text(
                        time.split('T').last, // Just the time part
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}
