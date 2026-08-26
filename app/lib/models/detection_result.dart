class DetectionResult {
  final String label;
  final double confidence;
  final double left;
  final double top;
  final double width;
  final double height;
  final DateTime detectedAt;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.detectedAt,
  });
}
