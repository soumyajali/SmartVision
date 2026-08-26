import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/voice_settings.dart';

class SpeechService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  
  VoiceSettings _settings = VoiceSettings();
  VoiceSettings get settings => _settings;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      await _applySettings();
      _isInitialized = true;
      notifyListeners();
      log('Speech Service initialized.');
    } catch (e) {
      log('Error initializing Speech Service: $e');
    }
  }

  Future<void> _applySettings() async {
    try {
      await _flutterTts.setLanguage(_settings.language);
      await _flutterTts.setSpeechRate(_settings.speechRate);
      await _flutterTts.setVolume(_settings.volume);
    } catch (e) {
      log('Error applying speech settings: $e');
    }
  }

  void updateSettings(VoiceSettings newSettings) {
    _settings = newSettings;
    if (_isInitialized) {
      _applySettings();
    }
    notifyListeners();
  }

  void toggleVoice(bool enabled) {
    _settings = _settings.copyWith(enabled: enabled);
    if (!enabled) {
      stop();
    }
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!_settings.enabled || !_isInitialized) return;
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      log('TTS Speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      log('TTS Stop error: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
