import 'package:dart_openai/dart_openai.dart';

void main() async {
  OpenAI.apiKey = "invalid_key";
  OpenAI.baseUrl = "https://openrouter.ai/api";
  
  try {
    await OpenAI.instance.model.list();
    print("Success");
  } catch (e) {
    print("Error: $e");
  }
}
