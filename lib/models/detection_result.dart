import 'package:flutter/material.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  DetectionResult copyWith({
    String? label,
    double? confidence,
    Rect? boundingBox,
  }) {
    return DetectionResult(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }

  @override
  String toString() {
    return '$label ${(confidence * 100).toStringAsFixed(0)}%';
  }
}

