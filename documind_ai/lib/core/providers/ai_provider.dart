import 'dart:async';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/secure_storage_repository.dart';
import '../models/ai_provider_config.dart';

final aiProviderConfigProvider = AsyncNotifierProvider<AIProviderConfigNotifier, AIProviderConfig?>(() {
  return AIProviderConfigNotifier();
});

class AIProviderConfigNotifier extends AsyncNotifier<AIProviderConfig?> {
  @override
  FutureOr<AIProviderConfig?> build() async {
    final storage = ref.read(secureStorageProvider);
    final config = await storage.getProviderConfig();
    _applyConfig(config);
    return config;
  }

  void _applyConfig(AIProviderConfig? config) {
    if (config != null && (config.provider == 'OpenAI' || config.provider == 'Groq' || config.provider == 'OpenRouter')) {
      OpenAI.apiKey = config.apiKey;
      if (config.baseUrl != null && config.baseUrl!.isNotEmpty) {
        OpenAI.baseUrl = config.baseUrl!;
      }
    }
  }

  Future<bool> validateAndSaveConfig(AIProviderConfig config) async {
    state = const AsyncValue.loading();
    try {
      if (config.provider == 'OpenAI' || config.provider == 'Groq' || config.provider == 'OpenRouter') {
        OpenAI.apiKey = config.apiKey;
        String? sanitizedBaseUrl = config.baseUrl;
        if (sanitizedBaseUrl != null && sanitizedBaseUrl.isNotEmpty) {
          if (sanitizedBaseUrl.endsWith('/v1')) {
            sanitizedBaseUrl = sanitizedBaseUrl.substring(0, sanitizedBaseUrl.length - 3);
          }
          if (sanitizedBaseUrl.endsWith('/v1/')) {
            sanitizedBaseUrl = sanitizedBaseUrl.substring(0, sanitizedBaseUrl.length - 4);
          }
          OpenAI.baseUrl = sanitizedBaseUrl;
          config = config.copyWith(baseUrl: sanitizedBaseUrl); // Save the sanitized version
        } else {
          OpenAI.baseUrl = "https://api.openai.com"; // default
        }
        
        if (config.provider != 'OpenRouter') {
          // Test connection (OpenRouter's model list parsing crashes dart_openai)
          await OpenAI.instance.model.list();
        }
      } else if (config.provider == 'Gemini' || config.provider == 'Anthropic') {
        // Validation for Gemini and Anthropic could be a simple generation request or just save it.
      }

      final storage = ref.read(secureStorageProvider);
      await storage.saveProviderConfig(config);
      state = AsyncValue.data(config);
      return true;
    } catch (e) {
      // Revert on failure
      final storage = ref.read(secureStorageProvider);
      final existingConfig = await storage.getProviderConfig();
      _applyConfig(existingConfig);
      state = AsyncValue.data(existingConfig);
      return false; 
    }
  }
  
  Future<void> removeConfig() async {
    final storage = ref.read(secureStorageProvider);
    await storage.deleteProviderConfig();
    state = const AsyncValue.data(null);
  }
}
