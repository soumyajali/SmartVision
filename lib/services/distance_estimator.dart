import 'dart:math' as math;

/// Physical dimension priors in meters (height, width)
class ObjectDimensionPrior {
  final double realHeightM;
  final double realWidthM;

  const ObjectDimensionPrior(this.realHeightM, this.realWidthM);
}

/// Calibrated Pinhole Distance Estimator for Monocular Camera Streams.
/// Mathematically matches core/distance_estimation.py in the Python system.
class DistanceEstimator {
  final double hfovDeg;
  final double vfovDeg;
  final double calibrationScale;
  final double minOperatingRangeM;
  final double maxOperatingRangeM;

  late final double _fNormX;
  late final double _fNormY;

  static const Map<String, ObjectDimensionPrior> defaultPriors = {
    'person': ObjectDimensionPrior(1.70, 0.45),
    'cell phone': ObjectDimensionPrior(0.15, 0.075),
    'phone': ObjectDimensionPrior(0.15, 0.075),
    'bottle': ObjectDimensionPrior(0.24, 0.08),
    'water bottle': ObjectDimensionPrior(0.24, 0.08),
    'cup': ObjectDimensionPrior(0.12, 0.09),
    'mug': ObjectDimensionPrior(0.12, 0.09),
    'laptop': ObjectDimensionPrior(0.23, 0.32),
    'computer': ObjectDimensionPrior(0.45, 0.50),
    'keyboard': ObjectDimensionPrior(0.14, 0.44),
    'mouse': ObjectDimensionPrior(0.04, 0.06),
    'monitor': ObjectDimensionPrior(0.35, 0.55),
    'book': ObjectDimensionPrior(0.24, 0.17),
    'backpack': ObjectDimensionPrior(0.45, 0.32),
    'handbag': ObjectDimensionPrior(0.30, 0.35),
    'chair': ObjectDimensionPrior(0.85, 0.50),
    'car': ObjectDimensionPrior(1.50, 1.80),
    'bicycle': ObjectDimensionPrior(1.00, 1.70),
    'motorcycle': ObjectDimensionPrior(1.10, 2.00),
    'dog': ObjectDimensionPrior(0.55, 0.75),
    'cat': ObjectDimensionPrior(0.25, 0.45),
    'knife': ObjectDimensionPrior(0.25, 0.04),
    'scissors': ObjectDimensionPrior(0.20, 0.08),
  };

  DistanceEstimator({
    this.hfovDeg = 65.0,
    this.vfovDeg = 48.0,
    this.calibrationScale = 1.0,
    this.minOperatingRangeM = 0.25,
    this.maxOperatingRangeM = 12.0,
  }) {
    _fNormX = (1.0 / (2.0 * math.tan((hfovDeg * math.pi / 180.0) / 2.0))) * calibrationScale;
    _fNormY = (1.0 / (2.0 * math.tan((vfovDeg * math.pi / 180.0) / 2.0))) * calibrationScale;
  }

  /// Calculates metric distance from normalized bounding box coords (0.0 to 1.0)
  DistanceResult estimateDistance({
    required String label,
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final cleanLabel = label.trim().toLowerCase();
    final prior = defaultPriors[cleanLabel] ?? const ObjectDimensionPrior(0.50, 0.40);

    final apparentWidth = (right - left).abs().clamp(0.01, 1.0);
    final apparentHeight = (bottom - top).abs().clamp(0.01, 1.0);

    // Height-based distance estimate
    final distH = (prior.realHeightM * _fNormY) / apparentHeight;
    // Width-based distance estimate
    final distW = (prior.realWidthM * _fNormX) / apparentWidth;

    // Weighting: Height is generally more stable than width for upright objects
    double distEstimate;
    if (cleanLabel == 'person' || cleanLabel == 'bottle') {
      distEstimate = distH * 0.75 + distW * 0.25;
    } else if (cleanLabel == 'laptop' || cleanLabel == 'keyboard') {
      distEstimate = distW * 0.70 + distH * 0.30;
    } else {
      distEstimate = distH * 0.50 + distW * 0.50;
    }

    final clampedDist = distEstimate.clamp(minOperatingRangeM, maxOperatingRangeM);
    final isBorderClipped = left <= 0.02 || top <= 0.02 || right >= 0.98 || bottom >= 0.98;

    return DistanceResult(
      distanceM: double.parse(clampedDist.toStringAsFixed(2)),
      isClipped: isBorderClipped,
      confidenceRange: '${(clampedDist * 0.9).toStringAsFixed(1)}-${(clampedDist * 1.1).toStringAsFixed(1)}m',
    );
  }
}

class DistanceResult {
  final double distanceM;
  final bool isClipped;
  final String confidenceRange;

  const DistanceResult({
    required this.distanceM,
    required this.isClipped,
    required this.confidenceRange,
  });
}
