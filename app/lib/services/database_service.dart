import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'smart_vision.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE detections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT,
            confidence REAL,
            created_at TEXT
          )
        ''');
      },
    );

    return _database!;
  }
}
