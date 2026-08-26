import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feature_configuration.dart';

class FeatureManager extends ChangeNotifier {
  FeatureConfiguration _config = FeatureConfiguration();
  bool _isInitialized = false;

  FeatureConfiguration get config => _config;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final configString = prefs.getString('feature_configuration');
    if (configString != null) {
      try {
        _config = FeatureConfiguration.fromJson(jsonDecode(configString));
      } catch (e) {
        debugPrint('Failed to parse feature config: $e');
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('feature_configuration', jsonEncode(_config.toJson()));
    notifyListeners();
  }

  Future<void> updateConfig(FeatureConfiguration newConfig) async {
    _config = newConfig;
    
    // Validate Dependencies
    if (_config.objectTracking && !_config.objectDetection) {
      _config = _config.copyWith(objectDetection: true);
    }
    if (_config.objectSearch && !_config.objectDetection) {
      _config = _config.copyWith(objectDetection: true);
    }
    if (_config.objectCounting && !_config.objectDetection) {
      _config = _config.copyWith(objectDetection: true);
    }
    
    await saveConfig();
  }

  Future<void> applyPreset(String presetName) async {
    switch (presetName) {
      case 'Quick Scan':
        await updateConfig(_config.copyWith(
          objectDetection: true,
          objectTracking: true,
          objectCounting: true,
          ocr: false,
          faceRecognition: false,
        ));
        break;
      case 'Read Mode':
        await updateConfig(_config.copyWith(
          objectDetection: true,
          ocr: true,
          objectTracking: false,
          faceRecognition: false,
        ));
        break;
      case 'People Mode':
        await updateConfig(_config.copyWith(
          objectDetection: true,
          objectTracking: true,
          faceRecognition: true,
          ocr: false,
        ));
        break;
      case 'Safety Mode':
        await updateConfig(_config.copyWith(
          objectDetection: true,
          objectTracking: true,
          alerts: true,
          voiceAssistant: true,
        ));
        break;
      case 'Full Smart Scan':
        await updateConfig(FeatureConfiguration(
          objectDetection: true,
          objectTracking: true,
          objectSearch: true,
          objectCounting: true,
          ocr: true,
          faceRecognition: true,
          voiceAssistant: true,
          chatbot: true,
          alerts: true,
        ));
        break;
    }
  }
}
