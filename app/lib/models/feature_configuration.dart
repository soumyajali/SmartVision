class FeatureConfiguration {
  bool objectDetection;
  bool objectTracking;
  bool objectSearch;
  bool objectCounting;
  bool ocr;
  bool faceRecognition;
  bool voiceAssistant;
  bool chatbot;
  bool alerts;

  FeatureConfiguration({
    this.objectDetection = true,
    this.objectTracking = false,
    this.objectSearch = false,
    this.objectCounting = false,
    this.ocr = false,
    this.faceRecognition = false,
    this.voiceAssistant = true,
    this.chatbot = false,
    this.alerts = true,
  });

  factory FeatureConfiguration.fromJson(Map<String, dynamic> json) {
    return FeatureConfiguration(
      objectDetection: json['objectDetection'] ?? true,
      objectTracking: json['objectTracking'] ?? false,
      objectSearch: json['objectSearch'] ?? false,
      objectCounting: json['objectCounting'] ?? false,
      ocr: json['ocr'] ?? false,
      faceRecognition: json['faceRecognition'] ?? false,
      voiceAssistant: json['voiceAssistant'] ?? true,
      chatbot: json['chatbot'] ?? false,
      alerts: json['alerts'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectDetection': objectDetection,
      'objectTracking': objectTracking,
      'objectSearch': objectSearch,
      'objectCounting': objectCounting,
      'ocr': ocr,
      'faceRecognition': faceRecognition,
      'voiceAssistant': voiceAssistant,
      'chatbot': chatbot,
      'alerts': alerts,
    };
  }

  FeatureConfiguration copyWith({
    bool? objectDetection,
    bool? objectTracking,
    bool? objectSearch,
    bool? objectCounting,
    bool? ocr,
    bool? faceRecognition,
    bool? voiceAssistant,
    bool? chatbot,
    bool? alerts,
  }) {
    return FeatureConfiguration(
      objectDetection: objectDetection ?? this.objectDetection,
      objectTracking: objectTracking ?? this.objectTracking,
      objectSearch: objectSearch ?? this.objectSearch,
      objectCounting: objectCounting ?? this.objectCounting,
      ocr: ocr ?? this.ocr,
      faceRecognition: faceRecognition ?? this.faceRecognition,
      voiceAssistant: voiceAssistant ?? this.voiceAssistant,
      chatbot: chatbot ?? this.chatbot,
      alerts: alerts ?? this.alerts,
    );
  }
}
