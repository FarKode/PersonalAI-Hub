import 'package:flutter_test/flutter_test.dart';
import 'package:documind_ai/core/models/ai_provider_config.dart';

void main() {
  group('AIProviderConfig Model Tests', () {
    test('toJson should convert model to expected Map', () {
      final config = AIProviderConfig(
        provider: 'OpenAI',
        apiKey: 'sk-proj-testkey12345',
        baseUrl: 'https://api.openai.com',
        modelName: 'gpt-4o',
      );

      final json = config.toJson();

      expect(json['provider'], equals('OpenAI'));
      expect(json['apiKey'], equals('sk-proj-testkey12345'));
      expect(json['baseUrl'], equals('https://api.openai.com'));
      expect(json['modelName'], equals('gpt-4o'));
    });

    test('fromJson should build model correctly from valid Map', () {
      final json = {
        'provider': 'Gemini',
        'apiKey': 'AIzaSyTestKey56789',
        'baseUrl': null,
        'modelName': 'gemini-1.5-flash',
      };

      final config = AIProviderConfig.fromJson(json);

      expect(config.provider, equals('Gemini'));
      expect(config.apiKey, equals('AIzaSyTestKey56789'));
      expect(config.baseUrl, isNull);
      expect(config.modelName, equals('gemini-1.5-flash'));
    });

    test('copyWith should override only specified properties', () {
      final baseConfig = AIProviderConfig(
        provider: 'Groq',
        apiKey: 'gsk_testKey',
        baseUrl: 'https://api.groq.com',
        modelName: 'llama-3-8b',
      );

      final updatedConfig = baseConfig.copyWith(
        apiKey: 'gsk_newTestKey',
        modelName: 'llama-3-70b',
      );

      // Mutated fields
      expect(updatedConfig.apiKey, equals('gsk_newTestKey'));
      expect(updatedConfig.modelName, equals('llama-3-70b'));
      
      // Preserved fields
      expect(updatedConfig.provider, equals('Groq'));
      expect(updatedConfig.baseUrl, equals('https://api.groq.com'));
    });
  });
}
