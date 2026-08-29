import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;

class ImageProcessor {
  // Model input size (YOLOv8 typically uses 640x640)
  static const int modelInputSize = 640;

  /// Converts a CameraImage to an image_lib.Image, resizes it, and returns it.
  static image_lib.Image? processCameraImage(CameraImage cameraImage) {
    try {
      image_lib.Image? img;
      
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        img = _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        img = _convertBGRA8888ToImage(cameraImage);
      }

      if (img == null) return null;

      // Resize the image to match the model's expected input shape
      return image_lib.copyResize(
        img,
        width: modelInputSize,
        height: modelInputSize,
        interpolation: image_lib.Interpolation.linear,
      );
    } catch (e) {
      return null;
    }
  }

  static image_lib.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    return image_lib.Image.fromBytes(
      cameraImage.width,
      cameraImage.height,
      cameraImage.planes[0].bytes,
      format: image_lib.Format.bgra,
    );
  }

  static image_lib.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = image_lib.Image(width, height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        // Convert YUV to RGB
        int r = (y + v * 1436 / 1024 - 179).round();
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
        int b = (y + u * 1814 / 1024 - 227).round();

        // Clamp values
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixel(w, h, image_lib.getColor(r, g, b));
      }
    }
    return image;
  }
}
