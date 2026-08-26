class VoiceSettings {
  bool enabled;
  double speechRate;
  double volume;
  String language;

  VoiceSettings({
    this.enabled = true,
    this.speechRate = 0.5, // 0.0 to 1.0
    this.volume = 1.0,     // 0.0 to 1.0
    this.language = 'en-US',
  });

  VoiceSettings copyWith({
    bool? enabled,
    double? speechRate,
    double? volume,
    String? language,
  }) {
    return VoiceSettings(
      enabled: enabled ?? this.enabled,
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      language: language ?? this.language,
    );
  }
}
