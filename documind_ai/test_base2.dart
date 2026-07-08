import 'package:dart_openai/dart_openai.dart';

void main() async {
  OpenAI.apiKey = "invalid_key";
  OpenAI.baseUrl = "https://api.groq.com/openai";
  
  try {
    await OpenAI.instance.model.list();
    print("Success");
  } catch (e) {
    print("Error with https://api.groq.com/openai: $e");
  }

  OpenAI.baseUrl = "https://api.groq.com/openai/v1";
  try {
    await OpenAI.instance.model.list();
    print("Success");
  } catch (e) {
    print("Error with https://api.groq.com/openai/v1: $e");
  }
}
