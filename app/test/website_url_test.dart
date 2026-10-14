import 'package:flutter_test/flutter_test.dart';
import 'package:smart_vision/screens/website_screen.dart';

void main() {
  group('parseSmartVisionWebsiteUrl', () {
    test('accepts a local HTTP address with a port', () {
      expect(
        parseSmartVisionWebsiteUrl(' http://192.168.1.20:8501 '),
        Uri(scheme: 'http', host: '192.168.1.20', port: 8501),
      );
    });

    test('accepts HTTPS addresses', () {
      expect(
        parseSmartVisionWebsiteUrl('https://smartvision.example/app'),
        Uri(scheme: 'https', host: 'smartvision.example', path: '/app'),
      );
    });

    test('rejects addresses without an HTTP scheme or host', () {
      expect(parseSmartVisionWebsiteUrl('localhost:8501'), isNull);
      expect(parseSmartVisionWebsiteUrl('http:///missing-host'), isNull);
      expect(parseSmartVisionWebsiteUrl('ftp://192.168.1.20:8501'), isNull);
    });

    test('rejects URLs containing credentials', () {
      expect(
        parseSmartVisionWebsiteUrl('http://user@192.168.1.20:8501'),
        isNull,
      );
    });
  });
}
