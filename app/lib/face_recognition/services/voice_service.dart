import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  String _lastAnnouncement = "";
  DateTime _lastAnnouncementTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> announcePerson(String name) async {
    // Prevent spamming the same name multiple times a second
    if (name == _lastAnnouncement && DateTime.now().difference(_lastAnnouncementTime).inSeconds < 5) {
      return;
    }

    try {
      if (name == "Unknown Person") {
        await _flutterTts.speak("Unknown person.");
      } else {
        await _flutterTts.speak("$name detected.");
      }
      _lastAnnouncement = name;
      _lastAnnouncementTime = DateTime.now();
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  Future<void> announceDanger(String item) async {
    try {
      await _flutterTts.speak("Danger warning! $item detected in area!");
    } catch (e) {
      debugPrint("TTS Danger Error: $e");
    }
  }

  Future<void> announceFound(String item) async {
    try {
      await _flutterTts.speak("$item found!");
    } catch (e) {
      debugPrint("TTS Found Error: $e");
    }
  }
}

