import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../services/image_processor.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final Size screenSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: screenSize,
      painter: DetectionBoxPainter(
        detections: detections,
        primaryColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class DetectionBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Color primaryColor;

  DetectionBoxPainter({
    required this.detections,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final bgPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // YOLO model input size is typically 640x640
    const double modelInputSize = ImageProcessor.modelInputSize.toDouble();
    
    // Calculate scale factors to map model coordinates to screen coordinates
    // Assuming the camera preview uses BoxFit.cover and fills the screen,
    // the aspect ratio of the model (1:1) differs from the screen aspect ratio.
    // The image was resized to 640x640 (which stretches it if aspect ratios don't match,
    // or crops it depending on how the camera frame is fed).
    // Standard approach: scale X and Y independently if the camera frame was squash-resized.
    final double scaleX = size.width / modelInputSize;
    final double scaleY = size.height / modelInputSize;

    for (final detection in detections) {
      // Scale bounding box from model coordinates to screen coordinates
      final rect = detection.boundingBox;
      
      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(scaledRect, boxPaint);

      // Draw label text
      final textSpan = TextSpan(
        text: detection.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw background for text
      final bgRect = Rect.fromLTWH(
        scaledRect.left,
        scaledRect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(bgRect, bgPaint);

      // Draw text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DetectionBoxPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.primaryColor != primaryColor;
  }
}
