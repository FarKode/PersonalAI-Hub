
# Technical Architecture Document
**Project:** DocuMind AI
**Tech Stack:** Flutter, Dart, Isar DB, OpenAI API

## 1. System Overview
The app follows a "Local-First, Cloud-Compute" architecture. All document storage, text chunking, and vector retrieval happen on the user's device. Only the final prompt (retrieved context + user query) is sent to the LLM via the user's API key.

## 2. Tech Stack Details
*   **Frontend:** Flutter (Material 3)
*   **State Management:** Riverpod (preferred for scalability and testing)
*   **Local Database:** Isar (Super fast NoSQL DB for Flutter, supports vector search natively or via custom implementation)
*   **PDF Processing:** `syncfusion_flutter_pdf` or `pdx` package for text extraction.
*   **API Integration:** `dart_openai` package.
*   **Routing:** GoRouter.

## 3. RAG (Retrieval-Augmented Generation) Pipeline
1.  **Ingestion:** User selects a PDF.
2.  **Extraction:** Flutter extracts raw text from the PDF.
3.  **Chunking:** Text is divided into chunks (e.g., 500 tokens per chunk with 50 token overlap).
4.  **Embedding:** App calls OpenAI Embedding API (`text-embedding-3-small`) using the user's key to get vector representations.
5.  **Storage:** Vectors + text chunks are saved in the local Isar database.
6.  **Retrieval:** When user asks a question, the query is embedded, and Cosine Similarity is calculated against local vectors to find the top 3-5 relevant chunks.
7.  **Generation:** Relevant chunks + user query are sent to `gpt-4o-mini` or `gpt-4o`. The response is streamed to the UI.

## 4. Background Processing
Document ingestion (extraction, chunking, embedding) is a heavy task. It will be executed using Flutter Isolates to prevent UI jank.
```
