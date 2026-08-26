import 'dart:developer';
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
      version: 1,
      onCreate: _createTables,
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
    log('SQLite tables created successfully.');
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
      return List.generate(maps.length, (i) => DetectionHistory.fromMap(maps[i]));
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
    } catch (e) {
      log('Error clearing history: $e');
    }
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
      return List.generate(maps.length, (i) => DetectionHistory.fromMap(maps[i]));
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
