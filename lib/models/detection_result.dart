import 'package:flutter/material.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final double? distanceM;
  final String? distanceStatus;
  final bool isHazard;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.distanceM,
    this.distanceStatus,
    this.isHazard = false,
  });

  DetectionResult copyWith({
    String? label,
    double? confidence,
    Rect? boundingBox,
    double? distanceM,
    String? distanceStatus,
    bool? isHazard,
  }) {
    return DetectionResult(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      distanceM: distanceM ?? this.distanceM,
      distanceStatus: distanceStatus ?? this.distanceStatus,
      isHazard: isHazard ?? this.isHazard,
    );
  }

  @override
  String toString() {
    return '$label ${(confidence * 100).toStringAsFixed(0)}%';
  }
}

