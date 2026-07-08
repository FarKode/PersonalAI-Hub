# Feature Ticket List (Development Backlog)
**Project:** DocuMind AI

## Epic 1: Project Setup & BYOK
*   **T-001:** Initialize Flutter project, configure Material 3, set up folder structure (features/core/widgets).
*   **T-002:** Install and configure `flutter_secure_storage` and `dart_openai`.
*   **T-003:** Build Onboarding UI with API Key input field and validation logic (test key with a simple API call).
*   **T-004:** Setup Riverpod providers for API Key state management.

## Epic 2: Document Ingestion & RAG
*   **T-005:** Integrate `file_picker` to select PDF/DOCX from device storage.
*   **T-006:** Implement PDF text extraction in a background Isolate.
*   **T-007:** Implement text chunking logic (500 tokens, 50 overlap).
*   **T-008:** Setup Isar database schema for storing vectors and text chunks.
*   **T-009:** Implement OpenAI Embedding API call for chunks and save to Isar.

## Epic 3: Chat Interface & AI
*   **T-010:** Build Chat UI (Message bubbles, input field, send button).
*   **T-011:** Implement query embedding and Cosine Similarity search in local Isar DB.
*   **T-012:** Construct final prompt (Context + Query) and stream response from OpenAI to UI.
*   **T-013:** Implement "Auto-Citation" parsing from AI response and display as clickable chips.
*   **T-014:** Add "1-Click Summary" and "Key Takeaways" floating buttons.

## Epic 4: Monetization & Polish
*   **T-015:** Integrate Google Play Billing Library for One-Time IAP ($9.99).
*   **T-016:** Implement Paywall logic (block multi-document chat and >3 docs for free users).
*   **T-017:** Add Dark Theme, animations (Lottie), and haptic feedback.
*   **T-018:** Write App Store description, prepare screenshots, and generate signed App Bundle.
```
