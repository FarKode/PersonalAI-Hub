class AIProviderConfig {
  final String provider; // 'OpenAI', 'Gemini', 'Groq', 'OpenRouter'
  final String apiKey;
  final String? baseUrl;
  final String? modelName;

  AIProviderConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.modelName,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'modelName': modelName,
    };
  }

  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      provider: json['provider'] as String,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String?,
      modelName: json['modelName'] as String?,
    );
  }

  AIProviderConfig copyWith({
    String? provider,
    String? apiKey,
    String? baseUrl,
    String? modelName,
  }) {
    return AIProviderConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
    );
  }
}
