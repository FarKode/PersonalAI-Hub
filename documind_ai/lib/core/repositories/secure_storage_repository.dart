import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_provider_config.dart';

final secureStorageProvider = Provider<SecureStorageRepository>((ref) {
  return SecureStorageRepository();
});

class SecureStorageRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _providerConfigKey = 'ai_provider_config';

  Future<void> saveProviderConfig(AIProviderConfig config) async {
    final jsonString = jsonEncode(config.toJson());
    await _storage.write(key: _providerConfigKey, value: jsonString);
  }

  Future<AIProviderConfig?> getProviderConfig() async {
    final jsonString = await _storage.read(key: _providerConfigKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return AIProviderConfig.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteProviderConfig() async {
    await _storage.delete(key: _providerConfigKey);
  }
}

