import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_vision/screens/splash_screen.dart';
import 'package:smart_vision/camera/camera_service.dart';
import 'package:smart_vision/ai/model_service.dart';
import 'package:smart_vision/services/feature_manager.dart';
import 'package:smart_vision/face_recognition/screens/known_persons_screen.dart';
import 'package:smart_vision/face_recognition/screens/add_person_screen.dart';
import 'package:smart_vision/face_recognition/screens/person_details_screen.dart';
import 'package:smart_vision/face_recognition/screens/recognition_history_screen.dart';
import 'package:smart_vision/face_recognition/screens/recognition_settings_screen.dart';
import 'package:smart_vision/face_recognition/services/face_database_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeatureManager()..init()),
        ChangeNotifierProxyProvider<FeatureManager, ModelService>(
          create: (_) => ModelService()..loadModel(),
          update: (_, fm, ms) => ms!..updateFeatureManager(fm),
        ),
        ChangeNotifierProxyProvider<ModelService, CameraService>(
          create: (_) => CameraService(),
          update: (_, modelService, cameraService) {
            if (!cameraService!.isCameraReady && modelService.isModelLoaded) {
              cameraService.initialize(modelService: modelService);
            }
            return cameraService;
          },
        ),
      ],
      child: const SmartVisionApp(),
    ),
  );
}

class SmartVisionApp extends StatelessWidget {
  const SmartVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/known_persons': (context) => const KnownPersonsScreen(),
        '/add_person': (context) => const AddPersonScreen(),
        '/recognition_history': (context) => const RecognitionHistoryScreen(),
        '/recognition_settings': (context) => const RecognitionSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/person_details') {
          final person = settings.arguments as Person;
          return MaterialPageRoute(
            builder: (context) => PersonDetailsScreen(person: person),
          );
        }
        return null;
      },
    );
  }
}
