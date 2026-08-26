import 'package:flutter/material.dart';

class DetectionHistory {
  final int? id;
  final String objectName;
  final double confidence;
  final DateTime timestamp;
  final Rect boundingBox;

  DetectionHistory({
    this.id,
    required this.objectName,
    required this.confidence,
    required this.timestamp,
    required this.boundingBox,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'object_name': objectName,
      'confidence': confidence,
      'x_position': boundingBox.left,
      'y_position': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DetectionHistory.fromMap(Map<String, dynamic> map) {
    return DetectionHistory(
      id: map['id'],
      objectName: map['object_name'],
      confidence: map['confidence'],
      timestamp: DateTime.parse(map['timestamp']),
      boundingBox: Rect.fromLTWH(
        map['x_position'],
        map['y_position'],
        map['width'],
        map['height'],
      ),
    );
  }
}
