import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../models/ai_provider_config.dart';
import '../../features/monetization/services/api_usage_tracker.dart';
import 'anthropic_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final config = ref.watch(aiProviderConfigProvider).value;
  final usageTracker = ref.read(apiUsageTrackerProvider);
  return AIService(config: config, usageTracker: usageTracker);
});

class AIService {
  final AIProviderConfig? config;
  final ApiUsageTracker? usageTracker;

  AIService({this.config, this.usageTracker});

  bool get isConfigured => config != null;

  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (config == null) throw Exception('AI Provider not configured');

    usageTracker?.incrementUsage();

    if (config!.provider == 'Gemini') {
      final model = GenerativeModel(
        model: config!.modelName ?? 'gemini-1.5-flash',
        apiKey: config!.apiKey,
        systemInstruction: Content.system(systemPrompt),
      );
      final response = await model.generateContent([Content.text(userPrompt)]);
      return response.text ?? '';
    } else if (config!.provider == 'Anthropic') {
      final anthropicService = AnthropicService(
        apiKey: config!.apiKey,
        modelName: config!.modelName ?? 'claude-3-haiku-20240307',
      );
      return await anthropicService.generateText(systemPrompt: systemPrompt, userPrompt: userPrompt);
    } else {
      // OpenAI, Groq, OpenRouter via dart_openai
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
      );
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt)],
      );
      final chatCompletion = await OpenAI.instance.chat.create(
        model: config!.modelName ?? 'gpt-4o-mini',
        messages: [systemMessage, userMessage],
      );
      return chatCompletion.choices.first.message.content?.first.text ?? '';
    }
  }

  Stream<String> generateTextStream({
    required String systemPrompt,
    required String userPrompt,
  }) {
    if (config == null) throw Exception('AI Provider not configured');

    usageTracker?.incrementUsage();

    if (config!.provider == 'Gemini') {
      final model = GenerativeModel(
        model: config!.modelName ?? 'gemini-1.5-flash',
        apiKey: config!.apiKey,
        systemInstruction: Content.system(systemPrompt),
      );
      final stream = model.generateContentStream([Content.text(userPrompt)]);
      return stream.map((chunk) => chunk.text ?? '');
    } else if (config!.provider == 'Anthropic') {
      final anthropicService = AnthropicService(
        apiKey: config!.apiKey,
        modelName: config!.modelName ?? 'claude-3-haiku-20240307',
      );
      return anthropicService.generateTextStream(systemPrompt: systemPrompt, userPrompt: userPrompt);
    } else {
      // OpenAI, Groq, OpenRouter
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
      );
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt)],
      );
      final stream = OpenAI.instance.chat.createStream(
        model: config!.modelName ?? 'gpt-4o-mini',
        messages: [systemMessage, userMessage],
      );
      return stream.map((chunk) {
        if (chunk.choices.isNotEmpty && chunk.choices.first.delta.content != null) {
          return chunk.choices.first.delta.content!.map((e) => e?.text ?? "").join("");
        }
        return "";
      });
    }
  }

  Future<List<List<double>>> createEmbeddingsBatch(List<String> texts) async {
    if (config == null) throw Exception('AI Provider not configured');
    
    if (config!.provider == 'Gemini') {
      final model = GenerativeModel(
        model: 'text-embedding-004',
        apiKey: config!.apiKey,
      );
      final requests = texts.map((t) => EmbedContentRequest(Content.text(t))).toList();
      final response = await model.batchEmbedContents(requests);
      return response.embeddings.map((e) => e.values).toList();
    } else if (config!.provider == 'Groq') {
      throw Exception('Groq currently does not support text embeddings. Please use Gemini or OpenAI for Document Mind.');
    } else {
      final embeddings = await OpenAI.instance.embedding.create(
        model: 'text-embedding-3-small',
        input: texts,
      );
      return embeddings.data.map((e) => e.embeddings).toList();
    }
  }

  Future<List<double>> createEmbedding(String text) async {
    final batch = await createEmbeddingsBatch([text]);
    return batch.first;
  }
}
