import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smart_vision/face_recognition/database/database_helper.dart';

class Person {
  final int? id;
  final String name;
  final String createdAt;
  final String metadata;

  Person({this.id, required this.name, required this.createdAt, required this.metadata});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }
}

class FaceEmbedding {
  final int? id;
  final int personId;
  final List<double> embedding;
  final String imagePath;

  FaceEmbedding({this.id, required this.personId, required this.embedding, required this.imagePath});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personId': personId,
      // Store embedding as binary blob
      'embedding': Float32List.fromList(embedding).buffer.asUint8List(),
      'imagePath': imagePath,
    };
  }
}

class FaceDatabaseService {
  final dbHelper = DatabaseHelper.instance;

  Future<int> addPerson(String name, {String metadata = "{}"}) async {
    final db = await dbHelper.database;
    if (db == null) return -1;
    final person = Person(
      name: name,
      createdAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );
    return await db.insert('KnownPersons', person.toMap());
  }

  Future<int> addFaceEmbedding(int personId, List<double> embedding, String imagePath) async {
    final db = await dbHelper.database;
    if (db == null) return -1;
    final face = FaceEmbedding(
      personId: personId,
      embedding: embedding,
      imagePath: imagePath,
    );
    return await db.insert('FaceEmbeddings', face.toMap());
  }

  Future<List<Person>> getAllPersons() async {
    final db = await dbHelper.database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('KnownPersons');
    
    return List.generate(maps.length, (i) {
      return Person(
        id: maps[i]['id'],
        name: maps[i]['name'],
        createdAt: maps[i]['createdAt'],
        metadata: maps[i]['metadata'],
      );
    });
  }

  Future<List<FaceEmbedding>> getEmbeddingsForPerson(int personId) async {
    final db = await dbHelper.database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'FaceEmbeddings',
      where: 'personId = ?',
      whereArgs: [personId],
    );

    return List.generate(maps.length, (i) {
      final blob = maps[i]['embedding'] as Uint8List;
      final floatList = blob.buffer.asFloat32List();
      
      return FaceEmbedding(
        id: maps[i]['id'],
        personId: maps[i]['personId'],
        embedding: floatList.toList(),
        imagePath: maps[i]['imagePath'],
      );
    });
  }

  Future<void> recordRecognition(int? personId, double confidence) async {
    final db = await dbHelper.database;
    if (db == null) return;
    await db.insert('RecognitionHistory', {
      'personId': personId,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
