import 'dart:developer';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/detection_history.dart';
import '../models/search_history.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_vision.db');

    log('Initializing SQLite Database at $path');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAnalysisHistoryTable(db);
        }
        if (oldVersion < 3) {
          await _createAppSettingsTable(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    log('Creating SQLite tables...');
    await db.execute('''
      CREATE TABLE detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        object_name TEXT,
        confidence REAL,
        x_position REAL,
        y_position REAL,
        width REAL,
        height REAL,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_object TEXT,
        found INTEGER,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        object_name TEXT,
        count INTEGER,
        date TEXT
      )
    ''');
    await _createAnalysisHistoryTable(db);
    await _createAppSettingsTable(db);
    log('SQLite tables created successfully.');
  }

  Future<void> _createAnalysisHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE analysis_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_type TEXT NOT NULL,
        summary TEXT NOT NULL,
        details_json TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');
  }

  // --- Detection History ---

  Future<void> insertDetection(DetectionHistory detection) async {
    try {
      final db = await database;
      await db.insert(
        'detections',
        detection.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _updateStatistics(detection.objectName, detection.timestamp);
    } catch (e) {
      log('Error inserting detection: $e');
    }
  }

  Future<List<DetectionHistory>> getDetectionHistory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'detections',
        orderBy: 'timestamp DESC',
      );
      return List.generate(
          maps.length, (i) => DetectionHistory.fromMap(maps[i]));
    } catch (e) {
      log('Error fetching detection history: $e');
      return [];
    }
  }

  Future<void> deleteDetection(int id) async {
    try {
      final db = await database;
      await db.delete(
        'detections',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      log('Error deleting detection: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete('detections');
      await db.delete('analysis_history');
    } catch (e) {
      log('Error clearing history: $e');
    }
  }

  Future<void> insertAnalysisHistory({
    required String analysisType,
    required String summary,
    required Map<String, dynamic> details,
  }) async {
    final db = await database;
    await db.insert('analysis_history', {
      'analysis_type': analysisType,
      'summary': summary,
      'details_json': jsonEncode(details),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAnalysisHistory({
    int limit = 50,
  }) async {
    final db = await database;
    final rows = await db.query(
      'analysis_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map((row) {
      final item = Map<String, dynamic>.from(row);
      item['details'] = jsonDecode(item.remove('details_json') as String);
      return item;
    }).toList();
  }

  Future<String?> getAppSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['setting_value'] as String?;
  }

  Future<void> setAppSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'setting_key': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DetectionHistory>> searchDetection(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'detections',
        where: 'object_name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'timestamp DESC',
      );
      return List.generate(
          maps.length, (i) => DetectionHistory.fromMap(maps[i]));
    } catch (e) {
      log('Error searching detection: $e');
      return [];
    }
  }

  // --- Search History (For Target Object Finding) ---

  Future<void> insertSearchHistory(SearchHistory search) async {
    try {
      final db = await database;
      await db.insert('search_history', search.toMap());
    } catch (e) {
      log('Error inserting search history: $e');
    }
  }

  Future<List<SearchHistory>> getSearchHistory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'search_history',
        orderBy: 'timestamp DESC',
      );
      return List.generate(maps.length, (i) => SearchHistory.fromMap(maps[i]));
    } catch (e) {
      log('Error fetching search history: $e');
      return [];
    }
  }

  // --- Statistics Helpers ---

  Future<void> _updateStatistics(String objectName, DateTime timestamp) async {
    try {
      final db = await database;
      final date = timestamp.toIso8601String().split('T').first; // YYYY-MM-DD

      final List<Map<String, dynamic>> existing = await db.query(
        'statistics',
        where: 'object_name = ? AND date = ?',
        whereArgs: [objectName, date],
      );

      if (existing.isNotEmpty) {
        final id = existing.first['id'] as int;
        final count = existing.first['count'] as int;
        await db.update(
          'statistics',
          {'count': count + 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.insert('statistics', {
          'object_name': objectName,
          'count': 1,
          'date': date,
        });
      }
    } catch (e) {
      log('Error updating statistics: $e');
    }
  }
}
