import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';

class EmbeddingService {
  /// Generates an embedding for a single string using text-embedding-3-small
  Future<List<double>> createEmbedding(String text) async {
    try {
      final embedding = await OpenAI.instance.embedding.create(
        model: "text-embedding-3-small",
        input: text,
      );
      
      if (embedding.data.isNotEmpty) {
        return embedding.data.first.embeddings;
      }
      return [];
    } catch (e) {
      debugPrint("Embedding Error: $e");
      rethrow;
    }
  }

  /// Generates embeddings for a batch of strings to speed up ingestion
  Future<List<List<double>>> createEmbeddingsBatch(List<String> texts) async {
    try {
      final embedding = await OpenAI.instance.embedding.create(
        model: "text-embedding-3-small",
        input: texts,
      );
      
      // OpenAI maintains the order of inputs in the output data list
      return embedding.data.map((e) => e.embeddings).toList();
    } catch (e) {
      debugPrint("Batch Embedding Error: $e");
      rethrow;
    }
  }
}
