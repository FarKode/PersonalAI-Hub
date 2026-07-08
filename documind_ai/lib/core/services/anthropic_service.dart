import 'dart:convert';
import 'package:http/http.dart' as http;

class AnthropicService {
  final String apiKey;
  final String modelName;

  AnthropicService({required this.apiKey, required this.modelName});

  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    final response = await http.post(
      url,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': modelName,
        'max_tokens': 4096,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userPrompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Anthropic API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['content'] != null && data['content'].isNotEmpty) {
      return data['content'][0]['text'] ?? '';
    }
    return '';
  }

  Stream<String> generateTextStream({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    final request = http.Request('POST', url)
      ..headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      })
      ..body = jsonEncode({
        'model': modelName,
        'max_tokens': 4096,
        'system': systemPrompt,
        'stream': true,
        'messages': [
          {'role': 'user', 'content': userPrompt}
        ],
      });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();
        throw Exception('Anthropic stream error: ${response.statusCode} $error');
      }

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          if (dataStr == '[DONE]') break;
          try {
            final json = jsonDecode(dataStr);
            if (json['type'] == 'content_block_delta' && json['delta']?['text'] != null) {
              yield json['delta']['text'];
            }
          } catch (_) {
            // Ignore parse errors on partial chunks
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
