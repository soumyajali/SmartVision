import 'dart:typed_data';

class FaceEmbedding {
  final int? id;
  final int personId;
  final String personName;
  final List<double> embedding; // 512 dimensions
  final String imagePath;
  final String createdAt;

  FaceEmbedding({
    this.id,
    required this.personId,
    required this.personName,
    required this.embedding,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personId': personId,
      // SQLite does not support lists directly, so we store embedding as binary blob
      'embedding': Float32List.fromList(embedding).buffer.asUint8List(),
      'imagePath': imagePath,
    };
  }

  factory FaceEmbedding.fromMap(Map<String, dynamic> map, String personName) {
    final blob = map['embedding'] as Uint8List;
    final floatList = blob.buffer.asFloat32List();
    
    return FaceEmbedding(
      id: map['id'],
      personId: map['personId'],
      personName: personName,
      embedding: floatList.toList(),
      imagePath: map['imagePath'],
      createdAt: DateTime.now().toIso8601String(), // Or fetch from a joined query
    );
  }
}
