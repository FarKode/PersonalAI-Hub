import 'package:flutter/foundation.dart';
import '../../../core/database/models/isar_chunk.dart';
import '../../../core/utils/vector_utils.dart';
import '../../../objectbox.g.dart';
import '../../../core/services/ai_service.dart';
import '../../../main.dart'; // Access obxStore

class RagOrchestrator {
  final AIService aiService;

  RagOrchestrator({
    required this.aiService,
  });

  /// Step 1: Ingestion - Embed all chunks and update ObjectBox
  Future<void> embedAndSaveChunks(int docId) async {
    final box = obxStore.box<IsarChunk>();

    // Fetch chunks for this document that haven't been embedded
    final query = box.query(IsarChunk_.docId.equals(docId).and(IsarChunk_.chunkVector.isNull())).build();
    final chunks = query.find();
    query.close();

    if (chunks.isEmpty) return;

    for (int i = 0; i < chunks.length; i += 20) {
      final end = (i + 20 < chunks.length) ? i + 20 : chunks.length;
      final batch = chunks.sublist(i, end);
      
      final texts = batch.map((c) => c.chunkText).toList();
      final vectors = await aiService.createEmbeddingsBatch(texts);

      for (int j = 0; j < batch.length; j++) {
        batch[j].chunkVector = vectors[j];
      }
      box.putMany(batch);
    }
  }

  /// Step 2-5: Retrieval and Generation (Streaming) - Answer query using local RAG
  Future<Stream<String>> answerQueryStream(String queryStr, int docId) async {
    // 1. Embed the user's query
    final queryVector = await aiService.createEmbedding(queryStr);

    final box = obxStore.box<IsarChunk>();

    // 2. Fetch all chunks with valid vectors for this document
    final query = box.query(IsarChunk_.docId.equals(docId).and(IsarChunk_.chunkVector.notNull())).build();
    final chunks = query.find();
    query.close();

    if (chunks.isEmpty) {
      return Stream.value("No processed content found for this document. (Ensure you're using a provider that supports embeddings, like OpenAI or Gemini)");
    }

    // 3. Calculate cosine similarity between query and all chunks (manual fallback to guarantee accuracy per-document)
    final Map<IsarChunk, double> similarities = {};
    for (final chunk in chunks) {
      if (chunk.chunkVector != null) {
        final sim = VectorUtils.cosineSimilarity(queryVector, chunk.chunkVector!);
        similarities[chunk] = sim;
      }
    }

    // Sort chunks by highest similarity score
    final sortedChunks = similarities.keys.toList()
      ..sort((a, b) => similarities[b]!.compareTo(similarities[a]!));

    // Fetch the top 3 most relevant chunks
    final topChunks = sortedChunks.take(3).toList();
    
    String contextText = "";
    for (int i = 0; i < topChunks.length; i++) {
      contextText += "[Chunk ${topChunks[i].id}]\n${topChunks[i].chunkText}\n\n";
    }

    final systemPrompt = "You are a document assistant. Use the following context to answer the user's question. "
      "If the answer is not in the context, say 'I don't know'.\n\n"
      "CRITICAL: Whenever you state a fact from the context, you MUST cite it by appending the chunk tag at the end of the sentence. "
      "For example: 'The sky is blue. [Chunk 5]'\n\n"
      "Context:\n$contextText";

    try {
      return aiService.generateTextStream(
        systemPrompt: systemPrompt,
        userPrompt: queryStr,
      );
    } catch (e) {
      debugPrint("Chat Generation Error: $e");
      return Stream.value("An error occurred while generating the response: $e");
    }
  }
}
