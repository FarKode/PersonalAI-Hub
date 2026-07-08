# 🚀 DocuMind AI Hub

![Flutter Version](https://img.shields.io/badge/Flutter-v3.12.0-blue.svg)
![Dart Version](https://img.shields.io/badge/Dart-v3.1.0-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-Feature--First-success.svg)
![State Management](https://img.shields.io/badge/State_Management-Riverpod-orange.svg)
![Local Storage](https://img.shields.io/badge/Database-ObjectBox-green.svg)

**DocuMind AI Hub** is a premium, locally-processed, Multi-Agent AI Application built with Flutter. It serves as a Bring-Your-Own-Key (BYOK) hub where users can interact with multiple specialized AI agents, process PDF documents locally (RAG - Retrieval-Augmented Generation), craft professional emails, and improve language skills.

---

## 📖 Table of Contents
1. [Project Overview & Tech Stack](#1-project-overview--tech-stack)
2. [UI/UX & Design System](#2-uiux--design-system)
3. [Premium Features (Phase 3)](#3-premium-features-phase-3)
4. [App Architecture & Logic](#4-app-architecture--logic)
5. [API Integration & Use Cases](#5-api-integration--use-cases)
6. [Local Storage & State Persistence](#6-local-storage--state-persistence)
7. [How to Run the Project](#7-how-to-run-the-project)

---

## 1. Project Overview & Tech Stack

### 🎯 Purpose
The primary objective of DocuMind AI is to provide a privacy-first, secure, and seamless AI experience. Users configure their own API keys (OpenAI, Gemini, Anthropic, Groq, OpenRouter), and all document parsing and vector chunking happens entirely on the local device. No user documents are ever uploaded to an external server—only the relevant text chunks are sent to the AI provider during generation.

### 🛠️ Core Tech Stack & Dependencies
The project leverages a modern, highly scalable Flutter ecosystem:

- **State Management:** `flutter_riverpod` (^3.3.2) - For scalable, reactive, and predictable state management.
- **Routing:** `go_router` (^17.3.0) - For declarative routing, deep linking, and nested navigation.
- **Local Database (NoSQL):** `objectbox` (^5.3.2) - Extremely fast edge database for storing RAG chunks, documents, and chat history.
- **Secure Storage:** `flutter_secure_storage` (^10.3.1) - For encrypting and persisting API keys locally.
- **AI Integration:** 
  - `dart_openai` (^6.1.1) - Core package for interfacing with OpenAI-compatible endpoints (OpenAI, Groq, OpenRouter).
  - `google_generative_ai` (^0.4.7) - Dedicated SDK for Google Gemini models.
  - `http` (^1.2.1) - For native, raw integration with Anthropic's Claude 3 API, including SSE parsing for streams.
- **PDF Processing:** `syncfusion_flutter_pdf` (^34.1.29) - For local text extraction from PDF documents.
- **Monetization:** `in_app_purchase` (^3.3.0) - For handling the "Pay Once. Use Forever." Lifetime Pro ($9.99) unlock and strict, granular daily usage tracking (The 'Aha!' Moment strategy).
- **Animations & UI:** `flutter_animate` (^4.5.2), `lottie` (^3.4.0) - For premium micro-interactions.

---

## 2. UI/UX & Design System

DocuMind AI utilizes a state-of-the-art **Glassmorphism & Neon** design language, specifically optimized for OLED/AMOLED displays to conserve battery while delivering a high-end, futuristic feel.

### 🎨 Color Palette
Defined centrally in `AppTheme.dart`:
- **Primary Background (Amoled Black):** `#000000` (True black for infinite contrast)
- **Secondary Surface:** `#121212` (Elevated dark surface)
- **Accent 1 (Neon Purple):** `#D200FF` (Used for primary actions, Premium badging, Document Mind)
- **Accent 2 (Electric Blue):** `#00E5FF` (Used for secondary actions, Email Crafter, Quick Chat)
- **Accent 3 (Mint Green):** `#00FFA3` (Used for Language Tutor success states)
- **Text Primary:** `#FFFFFF` (White)
- **Text Secondary:** `#A0A0A0` (Grey 400)
- **Error Red:** `#FF3B30`

### 🔤 Typography
Powered by `google_fonts`:
- **Font Family:** `GoogleFonts.inter()` (Used for its unparalleled readability in dense UI).
- **Weights:** 
  - `Bold (w700)`: App Bars, Hero Titles.
  - `Medium (w500)`: Buttons, List Tiles.
  - `Regular (w400)`: Body Text, Chat Messages.

### 🧩 UI Components & Theming
- **`PremiumBackground` Widget:** A custom base layout wrapped around `Scaffold` that injects subtle glowing orbs (RadialGradients) of Purple and Blue in the corners, creating a dark glassmorphism effect.
- **Bottom Sheets:** Rounded corners (`Radius.circular(24)`), blurred backgrounds using `BackdropFilter`, and solid dark surfaces.
- **Chat Bubbles:** Dynamic borders (sharp corner on the sender's side, rounded on others). AI messages include a subtle border glow.
- **Animations:** Haptic feedback (`HapticFeedback.lightImpact()`) is heavily integrated with route transitions and button taps. `flutter_animate` handles staggered list loading.
- **App Icon:** Adaptive Circular/Squircle app icons with AMOLED black backgrounds ensuring standard premium integration on modern Android launchers.

---

## 3. Premium Features (Phase 3)

In Phase 3, six highly advanced UI/UX features were implemented to elevate the application to a top-tier premium standard:

1. **API Usage Tracker:** A sleek Glassmorphism card integrated into the `DashboardScreen` that tracks and displays real-time API call counts directly via `SharedPreferences`.
2. **Advanced History Management:** A unified `HistoryScreen` where users can Pin to Top, Rename (via AMOLED-themed dialogs), and Delete sessions seamlessly using ObjectBox integration.
3. **Instant Bubble Actions:** Every AI chat bubble features a row of minimalistic action icons:
   - **Copy:** One-tap copy to clipboard.
   - **Share:** Native device sharing via `share_plus`.
   - **Regenerate:** Instantly resend the last prompt.
   - **Voice Output (TTS):** Read text aloud using `flutter_tts`.
4. **Futuristic Voice I/O Engine:**
   - **In-Place Glowing Mic:** The text input field features an embedded mic button. Upon activation, it triggers real-time voice recognition using `speech_to_text`. The mic transforms into a glowing, pulsing `Neon Purple` orb utilizing `flutter_animate`, and dictates text dynamically into the `TextField`.
   - **Animated Equalizer:** During Text-to-Speech playback, the speaker icon transitions into an animated equalizer and a neon glow encompasses the active message bubble.
5. **Quick Prompt Templates:** Horizontal `ActionChip` scrollbars injected above the text input in the Agent screens (Email Crafter, Language Tutor, Quick Chat), providing one-tap prompt templates.
6. **Custom System Persona:** Users can modify the core AI instructions via a dedicated premium Bottom Sheet in the Quick Chat interface, stored persistently.

---

## 4. App Architecture & Logic

The project follows a strict **Feature-First (Layered) Architecture**. This ensures massive scalability and isolates domain logic from UI.

### 📂 Folder Structure
```text
lib/
 ┣ core/                    # App-wide shared resources
 ┃ ┣ database/              # ObjectBox models (IsarDocument, AgentSession, etc.)
 ┃ ┣ providers/             # Global Riverpod providers (AIProvider, etc.)
 ┃ ┣ router/                # GoRouter configuration
 ┃ ┣ services/              # Shared Services (AIService interface)
 ┃ ┣ theme/                 # AppTheme, Colors, Typography
 ┃ ┗ widgets/               # Reusable UI (PremiumBackground, Equalizer)
 ┣ features/                # Independent, isolated feature modules
 ┃ ┣ auth/                  # API Key management, Bottom Sheets
 ┃ ┣ chat/                  # RAG Implementation, Document Mind UI, ChatProvider
 ┃ ┣ dashboard/             # Main Hub, Agent selections (Quick Chat, Email Crafter)
 ┃ ┣ history/               # Unified History viewer and HistoryService
 ┃ ┣ monetization/          # Paywalls, In-App Purchases, Usage Tracker
 ┃ ┗ onboarding/            # Splash screen, Welcome flow
 ┗ main.dart                # App entry point, ProviderScope initialization
```

### 🧠 State Management (Riverpod)
- **Reactive State:** `NotifierProvider` and `StateNotifierProvider` are used exclusively. There are zero `setState` calls for complex business logic.
- **Dependency Injection:** Riverpod acts as the DI container. For example, `chatProvider` reads `ragOrchestratorProvider`, which in turn reads `aiServiceProvider`. This allows for extremely easy mocking during testing.
- **Data Flow:** 
  1. UI triggers an action (e.g., `ref.read(chatProvider.notifier).sendMessage()`).
  2. The Notifier updates state (`isTyping = true`).
  3. The Notifier calls a Service (`RagOrchestrator`).
  4. The Service processes data and calls the Network layer (`AIService`).
  5. The response streams back, Notifier updates state iteratively, and UI rebuilds reactively.

---

## 5. API Integration & Use Cases

### 🌐 Network Layer Design
Instead of standard HTTP/Dio requests, DocuMind abstracts AI calls behind an `AIService` interface. This allows polymorphic behavior based on the user's selected provider.

- **Polymorphism:** `AIService` checks the current configuration (`AIProviderConfig`). 
  - If `OpenAI`, `Groq`, or `OpenRouter`: It dynamically alters `OpenAI.baseUrl` and `OpenAI.apiKey` in the `dart_openai` singleton and routes the request.
  - If `Gemini`: It bypasses `dart_openai` entirely and instantiates `GenerativeModel` from the `google_generative_ai` SDK.
  - If `Anthropic`: It instantiates `AnthropicService` to communicate directly via HTTP and parse Server-Sent Events (SSE) for streaming Claude models.
- **URL Sanitization:** Interceptors/Sanitizers manually clean custom base URLs to prevent trailing `/v1` conflicts.

### 📝 Core Use Cases
1. **Local RAG (Document Mind):**
   - **Step 1:** User picks a PDF. `syncfusion_flutter_pdf` extracts text locally.
   - **Step 2:** Text is chunked (500 words per chunk) and saved to ObjectBox.
   - **Step 3:** When chatting, a quick local keyword matching algorithm (BM25 or similar) fetches the top 3 relevant chunks.
   - **Step 4:** Chunks are injected into the System Prompt.
2. **Single-Turn Agents (Email Crafter / Language Tutor):**
   - User inputs bullet points. UI calls `AIService.generateText()`. Result is rendered and persisted to `HistoryService`.
3. **Conversational Agent (Quick Chat):**
   - Maintains an active memory buffer of the conversation.

---

## 6. Local Storage & State Persistence

DocuMind is highly optimized for offline capability and rapid data retrieval.

- **ObjectBox (High-Performance NoSQL):** 
  - Chosen over SQLite/Hive due to its incredible edge computing speed and native vector/relational capabilities.
  - **Models:** 
    - `IsarDocument` & `IsarChunk` (For PDF metadata and text fragments).
    - `AgentSession` & `AgentMessage` (For unified conversation history across all 4 agents).
  - Relations (`ToOne`, `ToMany`) are used to link messages to their parent sessions.
- **Flutter Secure Storage:** 
  - Used exclusively to encrypt and store sensitive `AIProviderConfig` JSON (Base URLs and API Keys) securely using Keystore/Keychain.
- **Shared Preferences:** 
  - Loaded synchronously at app launch.
  - Handles the Pro status persistence to prevent UI flickering.
  - Powers the granular, daily Freemium `UsageTracker` (resetting automatically at midnight).

---

## 7. How to Run the Project

Follow these steps to clone, configure, and run the project locally.

### Prerequisites
- Flutter SDK `^3.12.0`
- Android Studio / Xcode
- ObjectBox requires a native C-library binding (handled automatically by Flutter).

### Step-by-Step Guide

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/documind_ai.git
   cd documind_ai
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate ObjectBox Bindings & Riverpod Code:**
   Whenever you change a Database Model (in `lib/core/database/models/`), you must regenerate the ObjectBox bindings.
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

### 🔐 Environment & API Setup
Since this is a BYOK (Bring Your Own Key) application, no `.env` file is strictly required to run the code. The user inputs their keys directly into the UI upon first launch. However, if you are developing and wish to hardcode a debug key, you can do so in `lib/main.dart` inside the `ensureInitialized` block.

---
*Architected and developed by the DocuMind Engineering Team. Designed for extreme performance, security, and elegance.*
