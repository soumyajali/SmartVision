import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_vision/services/feature_manager.dart';
import 'package:smart_vision/screens/home_screen.dart';
import 'package:smart_vision/screens/dashboard_screen.dart';
import 'package:smart_vision/screens/find_object_screen.dart';
import 'package:smart_vision/screens/detection_history_screen.dart';
import 'package:smart_vision/screens/statistics_screen.dart';
import 'package:smart_vision/screens/settings_screen.dart';
import 'package:smart_vision/screens/camera_detection_screen.dart';
import 'package:smart_vision/ai/model_service.dart';
import 'package:smart_vision/camera/camera_service.dart';

Widget createTestApp({Widget? child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FeatureManager>(create: (_) => FeatureManager()..init()),
      ChangeNotifierProvider<ModelService>(create: (_) => ModelService()),
      ChangeNotifierProvider<CameraService>(create: (_) => CameraService()),
    ],
    child: MaterialApp(
      home: child ?? const HomeScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Vision Flutter App Tests', () {
    testWidgets('1. App launches and renders HomeScreen with Bottom Navigation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      // Verify App Bar
      expect(find.text('Smart Vision'), findsOneWidget);

      // Verify all 5 navigation destinations exist
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify initial Dashboard is active
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('See. Understand. Act.'), findsOneWidget);
    });

    testWidgets('2. Bottom Navigation switches between all 5 screens (working & placeholders)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      // Navigate to History (Index 1 - Placeholder)
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.byType(DetectionHistoryScreen), findsOneWidget);
      expect(find.text('SQLite history and search records will be shown here.'), findsOneWidget);

      // Navigate to Stats (Index 2 - Placeholder)
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      expect(find.text('Detection analytics will be displayed here.'), findsOneWidget);

      // Navigate to Chat / Find Object (Index 3 - Placeholder)
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(FindObjectScreen), findsOneWidget);
      expect(find.text('Voice-guided object lookup will be added here.'), findsOneWidget);

      // Navigate to Settings (Index 4 - Partial)
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Flashlight settings'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Offline mode'), findsOneWidget);

      // Navigate back to Dashboard (Index 0 - Working)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('3. CameraDetectionScreen renders waiting/placeholder when camera is not attached', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const CameraDetectionScreen()));
      await tester.pump();

      // Without physical camera hardware, CameraService is not ready -> CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Flashlight Off'), findsOneWidget);
      expect(find.text('Zoom (1.0x)'), findsOneWidget);
      expect(find.text('SMART SCAN'), findsOneWidget);
    });

    testWidgets('4. BoundingBoxPainter paints bounding boxes and labels for mock detections', (WidgetTester tester) async {
      final mockDetections = [
        Detection(const Rect.fromLTWH(0.1, 0.1, 0.4, 0.4), "person", 0.94),
        Detection(const Rect.fromLTWH(0.6, 0.6, 0.3, 0.3), "bottle", 0.88),
      ];

      final painter = BoundingBoxPainter(mockDetections);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 400),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
      expect(painter.shouldRepaint(painter), isTrue);
    });

    testWidgets('5. ModelService mock detection contains person label and confidence', (WidgetTester tester) async {
      final modelService = ModelService();
      final featureManager = FeatureManager()..init();
      modelService.updateFeatureManager(featureManager);

      expect(modelService.recognitions, isEmpty);
      await modelService.simulateStaticInference();
      
      expect(modelService.recognitions.isNotEmpty, isTrue);
      expect(modelService.recognitions.first.label, equals('person'));
      expect(modelService.recognitions.first.confidence, equals(0.95));
    });
  });
}
