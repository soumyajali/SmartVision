import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_vision/app.dart';
import 'package:smart_vision/controllers/detection_controller.dart';
import 'package:smart_vision/controllers/statistics_controller.dart';
import 'package:smart_vision/services/camera_service.dart';
import 'package:smart_vision/services/database_service.dart';
import 'package:smart_vision/services/on_device_ai_service.dart';
import 'package:smart_vision/services/speech_service.dart';
import 'package:smart_vision/services/statistics_service.dart';

void main() {
  testWidgets('SmartVision AI smoke test', (WidgetTester tester) async {
    final camera = CameraService();
    final speech = SpeechService();
    final localAi = OnDeviceAiService.instance;
    final db = DatabaseService();
    final stats = StatisticsService(db);
    final statsCtrl = StatisticsController(stats);
    final detectionCtrl = DetectionController(camera, speech, db);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: camera),
          ChangeNotifierProvider.value(value: localAi),
          ChangeNotifierProvider.value(value: speech),
          Provider.value(value: db),
          Provider.value(value: stats),
          ChangeNotifierProvider.value(value: statsCtrl),
          ChangeNotifierProvider.value(value: detectionCtrl),
        ],
        child: const SmartVisionApp(),
      ),
    );

    // Initial frame loads SplashScreen
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('SmartVision AI'), findsOneWidget);

    // Advance time past splash timer to navigate to Home
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verify Home loaded
    expect(find.text('SmartVision AI Sentinel'), findsOneWidget);
    // Verify Vision Chatbot present in sidebar and dashboard card
    expect(find.text('Vision Chatbot'), findsAtLeastNWidgets(1));
    // Verify OCR & Translate Card
    expect(find.text('OCR & Translate'), findsAtLeastNWidgets(1));
  });

  test('DetectionController target lock and hazard logic', () {
    final camera = CameraService();
    final speech = SpeechService();
    final db = DatabaseService();
    final ctrl = DetectionController(camera, speech, db);

    // Test target search lock
    ctrl.setSearchTarget('bottle');
    expect(ctrl.searchTarget, 'bottle');
    expect(ctrl.isTargetFound, isFalse);

    // Test hazard tracking
    expect(ctrl.hasActiveHazard, isFalse);
  });
}
