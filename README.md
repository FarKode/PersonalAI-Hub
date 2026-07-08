<div align="center">

# 🧠 PersonalAI Hub

**A Privacy-First, BYOK (Bring Your Own Key) AI Agent Hub for Android**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local-purple)](legal.html)

</div>

---

## 📖 Overview

**PersonalAI Hub** is a premium Android application built with Flutter that gives you a suite of powerful AI agents — all powered by **your own API key**, running entirely on your device, with **zero data sent to any third-party server we control**.

This repository contains the **Proof of Concept (POC)** documenting the architecture, design decisions, and technical implementation of the app.

---

## 🎯 Core Philosophy

> **Your data. Your keys. Your device.**

- ✅ **Zero Data Collection** — No backend server. No analytics. No telemetry.
- ✅ **BYOK Architecture** — You bring your own OpenAI / Gemini / Groq / Anthropic / OpenRouter key.
- ✅ **100% Local Storage** — Documents, chat history, and API keys never leave your device.
- ✅ **Offline-First** — Core processing (RAG pipeline, vector search) runs completely on-device.

---

## 🤖 AI Agents

| Agent | Description |
|---|---|
| 📄 **Document Mind** | Upload PDFs and chat with them using RAG (Retrieval-Augmented Generation) |
| ✉️ **Email Crafter** | Draft professional emails in seconds |
| 💬 **Quick Chat** | Fast, context-aware general-purpose AI chat |
| 🌍 **Language Tutor** | AI-powered language learning assistant |

---

## 🏗️ Technical Architecture

### System Overview
```
User Device (100% On-Device)
├── Flutter UI (Material 3, Glassmorphism)
├── Riverpod State Management
├── GoRouter Navigation
├── ObjectBox (Local NoSQL DB — Chat History, Documents, Vectors)
├── FlutterSecureStorage (Encrypted API Key Storage via Android Keystore)
└── SharedPreferences (Lightweight config flags)

External (Only when user initiates an AI request)
└── LLM Provider API (OpenAI / Gemini / Groq / Anthropic / OpenRouter)
    └── Called directly from device using the user's own API key
```

### RAG (Retrieval-Augmented Generation) Pipeline
```
1. IMPORT    → User selects PDF / TXT file
2. EXTRACT   → syncfusion_flutter_pdf extracts raw text
3. CHUNK     → Text split into ~500-token chunks (50-token overlap)
4. EMBED     → OpenAI Embeddings API called with user's key
5. STORE     → Vectors + chunks saved in local ObjectBox store
6. RETRIEVE  → On user query: cosine similarity search against local vectors
7. GENERATE  → Top-k chunks + query sent to LLM → streamed response
```

### Tech Stack
| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.12) |
| **State Management** | flutter_riverpod ^3.3 |
| **Routing** | go_router ^17.3 |
| **Local Database** | objectbox ^5.3 |
| **Secure Storage** | flutter_secure_storage ^10.3 |
| **PDF Processing** | syncfusion_flutter_pdf ^34.1 |
| **Speech I/O** | speech_to_text + flutter_tts |
| **Animations** | flutter_animate ^4.5 |

---

## 🔒 Security Design

### API Key Protection
- API keys are encrypted using **Android's native Keystore system** via `flutter_secure_storage`
- Keys are **never transmitted** through any intermediate server
- All API calls go **directly** from the user's device to the LLM provider over HTTPS

### Data Privacy
- All uploaded documents are stored **exclusively on-device** in ObjectBox
- Chat history is stored **exclusively on-device**
- The app has **no backend server** — there is no endpoint to exfiltrate data to

### Android Security Hardening
- `android:launchMode="singleTop"` to prevent activity duplication
- `restorationScopeId: null` to disable state restoration leaks
- Native `moveTaskToBack(true)` for proper app backgrounding

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── models/          # Data models (AIProviderConfig, etc.)
│   ├── providers/       # Riverpod providers
│   ├── repositories/    # SecureStorage repository
│   ├── router/          # GoRouter configuration
│   ├── services/        # AI service integrations
│   ├── theme/           # AppTheme (AMOLED dark, Glassmorphism)
│   ├── utils/           # VectorUtils (cosine similarity)
│   └── widgets/         # Shared widgets (PremiumBackground, etc.)
├── features/
│   ├── auth/            # API key setup (WelcomeSetup, ProviderBottomSheet)
│   ├── chat/            # Chat screen
│   ├── dashboard/       # Main hub screen + 4 agent screens
│   ├── history/         # Conversation history
│   ├── monetization/    # IAP & API usage tracking
│   ├── onboarding/      # Splash & onboarding screens
│   └── settings/        # Settings & API guide
├── main.dart
└── objectbox.g.dart     # ObjectBox generated code
```

---

## 🎨 Design System

- **Theme:** AMOLED Dark (`#050505` background)
- **Accent Colors:** Electric Blue (`#2979FF`) + Neon Purple (`#D500F9`)
- **Style:** Glassmorphism cards with `BackdropFilter` blur effects
- **Typography:** Google Fonts (Inter / Outfit)
- **Animations:** `flutter_animate` with fade, scale, and slide micro-animations

---

## ✅ Test Suite

```
test/
├── widget_test.dart              # Smoke test
├── ai_provider_config_test.dart  # Model serialization & mutation tests
└── vector_utils_test.dart        # Cosine similarity edge case tests
```

Run tests:
```bash
flutter test
```

---

## ⚠️ What's NOT in this Repository

For security, the following files are excluded via `.gitignore`:
- `documind_ai/android/local.properties` — local Android SDK paths
- `documind_ai/.dart_tool/` — generated tool files
- `documind_ai/build/` — build artifacts
- `documind_ai/objectbox.g.dart` — generated ObjectBox code (build locally)
- Any file containing real API keys or signing keystores

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.12`
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Setup
```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/PersonalAI-Hub.git

# 2. Navigate to the Flutter project
cd PersonalAI-Hub/documind_ai

# 3. Install dependencies
flutter pub get

# 4. Generate ObjectBox code
dart run build_runner build

# 5. Run on connected device
flutter run
```

> **Note:** You will need to provide your own API key from OpenAI, Gemini, Groq, Anthropic, or OpenRouter when first launching the app. No API key is bundled with the source code.

---

## 📄 Legal

- [Privacy Policy & Terms of Use](legal.html)
- This app uses a **BYOK model** — you are solely responsible for your API usage costs and your API provider's terms of service.

---

## 📝 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

<div align="center">
  <p>Built with ❤️ using Flutter & Gemini</p>
  <p><em>100% Private · 100% Local · 100% Yours</em></p>
</div>
