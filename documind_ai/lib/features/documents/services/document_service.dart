import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentService {
  Future<List<String>> processPdf(String filePath) async {
    // Run the extraction and chunking in a background isolate
    return await compute(_extractAndChunkPdf, filePath);
  }

  static List<String> _extractAndChunkPdf(String filePath) {
    try {
      final File file = File(filePath);
      final List<int> bytes = file.readAsBytesSync();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extract all text
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      return _chunkText(text);
    } catch (e) {
      debugPrint("Error processing PDF: $e");
      return [];
    }
  }

  static List<String> _chunkText(String text) {
    // Basic whitespace cleanup
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // We aim for chunks of ~500 tokens.
    // Assuming 1 word is approx 1.3 tokens, 500 tokens is about 380 words.
    // 50 token overlap is about 38 words.
    const int chunkSize = 380;
    const int overlap = 38;

    final List<String> words = text.split(' ');
    final List<String> chunks = [];

    int i = 0;
    while (i < words.length) {
      final end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
      final chunk = words.sublist(i, end).join(' ');
      
      if (chunk.trim().isNotEmpty) {
        chunks.add(chunk.trim());
      }

      if (end == words.length) break;
      i += (chunkSize - overlap);
    }

    return chunks;
  }
}
