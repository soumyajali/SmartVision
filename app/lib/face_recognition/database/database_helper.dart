import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // Avoid sqflite crash on Web without ffi setup
    if (_database != null) return _database!;
    _database = await _initDB('faces.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';
    const floatType = 'REAL NOT NULL';
    const blobType = 'BLOB NOT NULL';

    await db.execute('''
CREATE TABLE KnownPersons (
  id $idType,
  name $textType,
  createdAt $textType,
  metadata $textType
)
''');

    await db.execute('''
CREATE TABLE FaceEmbeddings (
  id $idType,
  personId INTEGER NOT NULL,
  embedding $blobType,
  imagePath $textType,
  FOREIGN KEY (personId) REFERENCES KnownPersons (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE RecognitionHistory (
  id $idType,
  personId INTEGER,
  confidence $floatType,
  timestamp $textType,
  FOREIGN KEY (personId) REFERENCES KnownPersons (id) ON DELETE SET NULL
)
''');

    await db.execute('''
CREATE TABLE RecognitionStatistics (
  id $idType,
  totalRecognitions INTEGER NOT NULL,
  totalUnknowns INTEGER NOT NULL,
  lastUpdated $textType
)
''');

    await db.execute('''
CREATE TABLE Detections (
  id $idType,
  timestamp $textType,
  classId INTEGER,
  className $textType,
  confidence $floatType,
  x1 $floatType,
  y1 $floatType,
  x2 $floatType,
  y2 $floatType,
  trackId INTEGER,
  source $textType
)
''');

    await db.execute('''
CREATE TABLE Events (
  id $idType,
  timestamp $textType,
  type $textType,
  title $textType,
  message $textType,
  severity $textType,
  objectClass $textType,
  trackId INTEGER,
  metadata $textType
)
''');

    await db.execute('''
CREATE TABLE OcrResults (
  id $idType,
  timestamp $textType,
  text $textType,
  confidence $floatType,
  x1 $floatType,
  y1 $floatType,
  x2 $floatType,
  y2 $floatType
)
''');

    await db.execute('''
CREATE TABLE Sessions (
  id $idType,
  startedAt $textType,
  endedAt $textType,
  detectionCount INTEGER,
  eventCount INTEGER
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    if (db != null) await db.close();
  }
}
