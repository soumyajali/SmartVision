import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/detection_result.dart';
import '../services/image_processor.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final Size screenSize;
  final Color? boxColor;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.screenSize,
    this.boxColor,
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
        primaryColor: boxColor ?? AppColors.neonAccent,
        deepViolet: AppColors.deepViolet,
      ),
    );
  }
}

class DetectionBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Color primaryColor;
  final Color deepViolet;

  DetectionBoxPainter({
    required this.detections,
    required this.primaryColor,
    required this.deepViolet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double modelInputSize = ImageProcessor.modelInputSize.toDouble();
    if (modelInputSize <= 0) return;

    final double scaleX = size.width / modelInputSize;
    final double scaleY = size.height / modelInputSize;

    // Text tag background
    final tagBgPaint = Paint()
      ..color = AppColors.cardBackground.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    for (final detection in detections) {
      final rect = detection.boundingBox;

      // Check if coordinates are normalized (0.0 to 1.0) or pixel-based
      final bool isNormalized = rect.right <= 1.5 && rect.bottom <= 1.5;
      final Rect scaledRect = isNormalized
          ? Rect.fromLTRB(
              rect.left * size.width,
              rect.top * size.height,
              rect.right * size.width,
              rect.bottom * size.height,
            )
          : Rect.fromLTRB(
              rect.left * scaleX,
              rect.top * scaleY,
              rect.right * scaleX,
              rect.bottom * scaleY,
            );

      final Color effectiveColor = detection.isHazard
          ? const Color(0xFFFF1744) // Neon Red for Danger
          : primaryColor;

      final dynamicBoxPaint = Paint()
        ..color = effectiveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = detection.isHazard ? 3.0 : 2.0;

      final dynamicGlowPaint = Paint()
        ..color = effectiveColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = detection.isHazard ? 8.0 : 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final dynamicCornerPaint = Paint()
        ..color = effectiveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final rrect = RRect.fromRectAndRadius(scaledRect, const Radius.circular(8));

      // Draw subtle glow
      canvas.drawRRect(rrect, dynamicGlowPaint);
      // Draw primary box
      canvas.drawRRect(rrect, dynamicBoxPaint);

      // Draw futuristic corner brackets / reticles
      final double cornerLen = (scaledRect.width * 0.15).clamp(10.0, 24.0);
      // Top-Left
      canvas.drawLine(Offset(scaledRect.left, scaledRect.top + cornerLen), Offset(scaledRect.left, scaledRect.top), dynamicCornerPaint);
      canvas.drawLine(Offset(scaledRect.left, scaledRect.top), Offset(scaledRect.left + cornerLen, scaledRect.top), dynamicCornerPaint);
      // Top-Right
      canvas.drawLine(Offset(scaledRect.right - cornerLen, scaledRect.top), Offset(scaledRect.right, scaledRect.top), dynamicCornerPaint);
      canvas.drawLine(Offset(scaledRect.right, scaledRect.top), Offset(scaledRect.right, scaledRect.top + cornerLen), dynamicCornerPaint);
      // Bottom-Left
      canvas.drawLine(Offset(scaledRect.left, scaledRect.bottom - cornerLen), Offset(scaledRect.left, scaledRect.bottom), dynamicCornerPaint);
      canvas.drawLine(Offset(scaledRect.left, scaledRect.bottom), Offset(scaledRect.left + cornerLen, scaledRect.bottom), dynamicCornerPaint);
      // Bottom-Right
      canvas.drawLine(Offset(scaledRect.right - cornerLen, scaledRect.bottom), Offset(scaledRect.right, scaledRect.bottom), dynamicCornerPaint);
      canvas.drawLine(Offset(scaledRect.right, scaledRect.bottom), Offset(scaledRect.right, scaledRect.bottom - cornerLen), dynamicCornerPaint);

      // Format label text with distance and hazard
      final percentage = (detection.confidence * 100).toStringAsFixed(0);
      String labelText = '${detection.label.toUpperCase()} $percentage%';
      if (detection.distanceM != null) {
        labelText += ' • ${detection.distanceM!.toStringAsFixed(2)}m';
      }
      if (detection.isHazard) {
        labelText = '⚠️ $labelText [HAZARD]';
      }

      final textSpan = TextSpan(
        text: labelText,
        style: TextStyle(
          color: detection.isHazard ? const Color(0xFFFF8A80) : AppColors.primaryText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position the tag above the bounding box if space permits, else inside
      final double tagHeight = textPainter.height + 8;
      final double tagWidth = textPainter.width + 16;
      final double tagTop = (scaledRect.top - tagHeight >= 4)
          ? scaledRect.top - tagHeight
          : scaledRect.top + 4;
      final double tagLeft = scaledRect.left;

      final tagRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tagLeft, tagTop, tagWidth, tagHeight),
        const Radius.circular(6),
      );

      canvas.drawRRect(tagRRect, tagBgPaint);
      final tagBorderPaint = Paint()
        ..color = effectiveColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(tagRRect, tagBorderPaint);

      // Draw dot indicator inside tag
      final dotPaint = Paint()
        ..color = effectiveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tagLeft + 8, tagTop + tagHeight / 2), 3, dotPaint);

      // Paint text
      textPainter.paint(
        canvas,
        Offset(tagLeft + 14, tagTop + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DetectionBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.deepViolet != deepViolet;
  }
}
