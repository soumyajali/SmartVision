class DetectionSettings {
  final double minimumConfidence;
  final double iouThreshold;
  final int maximumDetections;

  const DetectionSettings({
    this.minimumConfidence = 0.25,
    this.iouThreshold = 0.45,
    this.maximumDetections = 100,
  });

  DetectionSettings copyWith({
    double? minimumConfidence,
    double? iouThreshold,
    int? maximumDetections,
  }) {
    return DetectionSettings(
      minimumConfidence: minimumConfidence ?? this.minimumConfidence,
      iouThreshold: iouThreshold ?? this.iouThreshold,
      maximumDetections: maximumDetections ?? this.maximumDetections,
    );
  }
}
