# 🌌 Aura AI

> **A Next-Gen Multimodal AI Assistant built with Flutter — featuring Interactive Hands-Free Voice Mode, Multi-Provider Intelligence, Vision Support, and a Futuristic Glassmorphism Design.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-brightgreen?style=for-the-badge)](https://flutter.dev)

---

## ✨ Key Features

### ⚡ 1. Multi-Provider & Intelligent Fallback Engine
- **Groq AI (Primary)**: Ultra-fast LLM inference using models like `openai/gpt-oss-120b` and vision analysis via `meta-llama/llama-4-scout-17b`.
- **Cerebras AI (Backup)**: Automatic failover if Groq encounters rate limits or service interruptions.
- **GitHub Models (2nd Backup)**: Secondary backup powered by `openai/gpt-4o-mini`.
- **Resilient SSE Streaming**: `FallbackAiService` handles stream errors gracefully with zero drop in user experience.

### 🎙️ 2. Hands-Free Interactive Voice Mode
- **Real-Time Voice Interaction**: Speak directly using Speech-to-Text (`speech_to_text`) and listen to AI answers via Text-to-Speech (`flutter_tts`).
- **3D Animated AI Orb**: Stateful glowing Orb widget reflecting real-time AI status (*Idle*, *Listening*, *Thinking*, *Speaking*).
- **Multi-Lingual Voice Support**: Toggle voice interaction across English, Urdu, Hindi, and Arabic.

### 🖼️ 3. Multimodal & File Attachments
- **Image Analysis (Vision)**: Upload images directly into chats for AI visual recognition and context extraction.
- **Document & File Uploads**: Attach text documents and files using integrated pickers (`file_picker`, `image_picker`).

### 📂 4. Project Workspaces & Custom Personas
- **Project Workspaces**: Group related chats under specific Projects with dedicated custom system instructions.
- **Custom Personas & Controls**: Customize reply style (*Concise*, *Balanced*, *Detailed*) and output language (*Auto*, *English*, *Urdu*, *Roman Urdu*).

### 🔐 5. Dual Authentication System
- **Firebase Authentication**: Support for Email/Password sign-up/login and Google Sign-In.
- **Offline Local Auth**: Built-in offline mode using local SHA-256 hashed password authentication when Firebase is unconfigured.
- **Guest Mode**: One-tap guest entry for instant access.

### 🎨 6. Dark Aurora & Glassmorphism UI
- Animated **Aurora Gradient Backgrounds** paired with translucent **Glassmorphism Components**.
- **Responsive Layout**: Fluid UI adapting between mobile navigation drawers and desktop/tablet split-screen sidebars.
- **Markdown & Chat Export**: Full Markdown formatting with code syntax highlighting, copyable code blocks, and 1-click Markdown chat export.

---

## 🛠️ Tech Stack & Packages

| Category | Technology / Package |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Dart 3.x) |
| **State Management** | `ListenableBuilder` & `ChangeNotifier` |
| **Authentication** | `firebase_auth`, `firebase_core`, `crypto` (Local SHA-256 fallback) |
| **Networking & AI Streaming** | `http` (Server-Sent Events streaming client) |
| **Voice & Speech** | `speech_to_text`, `flutter_tts` |
| **Media & Pickers** | `image_picker`, `file_picker` |
| **UI & Styling** | `google_fonts`, `flutter_markdown_plus`, Custom Glassmorphism & Aurora Shader painters |
| **Local Storage** | `shared_preferences` |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # Application entry point & theme initialization
├── firebase_options.dart       # Firebase platform configuration
├── controllers/
│   ├── auth_controller.dart    # Firebase & Local Auth management
│   ├── chat_controller.dart    # Chat sessions, project workspaces, SSE generation
│   └── settings_controller.dart# API keys, user profile & system preferences
├── core/
│   ├── secrets.dart            # Provider API keys (Groq, Cerebras, GitHub) & Models
│   ├── store.dart              # SharedPreferences key-value storage wrapper
│   ├── theme/                  # Color tokens & AppTheme configurations
│   └── utils/                  # Responsive screen breakpoints utility
├── models/
│   ├── attachment.dart         # File & Image attachment model
│   ├── chat_message.dart       # Single chat message schema
│   ├── chat_session.dart       # Chat session container
│   └── project.dart            # Workspace project model
├── screens/
│   ├── auth_screen.dart        # Login, Signup, Reset & Guest auth UI
│   ├── chat_view.dart          # Chat interface with scrollable message list
│   ├── onboarding_screen.dart  # Initial welcome walkthrough
│   ├── settings_screen.dart    # Preferences, profile, API key tester, & voice settings
│   ├── voice_mode_screen.dart  # Hands-free voice interface with animated AI Orb
│   └── shell/
│       └── app_shell.dart      # Adaptive shell (Mobile drawer & Desktop split view)
├── services/
│   ├── ai_service.dart         # REST SSE stream client, OpenAI format parser, Fallback engine
│   └── voice_service.dart      # Speech-to-Text & Text-to-Speech manager
└── widgets/
    ├── ai_orb.dart             # Animated glowing stateful AI Orb widget
    ├── aurora_background.dart  # Custom animated gradient background painter
    ├── buttons.dart            # Custom glass & gradient buttons
    ├── chat_input_bar.dart     # Input widget with voice & attachment triggers
    ├── dialogs.dart            # Translucent confirmation dialogs
    ├── glass_container.dart    # Glassmorphism backdrop-blur containers
    ├── message_bubble.dart     # Markdown rendered chat bubbles
    └── sidebar.dart            # Project & session management sidebar navigation
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `^3.13.2` or higher
- **Dart SDK**: Included with Flutter
- **Groq API Key**: Get a free API key at [console.groq.com/keys](https://console.groq.com/keys)

### Setup & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/aura_ai.git
   cd aura_ai
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys:**
   Open `lib/core/secrets.dart` and add your Groq API key:
   ```dart
   class Secrets {
     static const groqKey = 'YOUR_GROQ_API_KEY_HERE';
     static const cerebrasKey = 'PASTE_CEREBRAS_KEY'; // Optional backup
     static const githubKey = 'PASTE_GITHUB_TOKEN';   // Optional backup
     
     static const model = 'openai/gpt-oss-120b';
     static const visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
   }
   ```
   *Alternatively, you can paste your Groq key directly inside the running app via **Settings → API Key**.*

4. **Launch the app:**
   ```bash
   flutter run
   ```

---

## ⚙️ Configuration Notes

- **Offline Mode**: If Firebase is unconfigured, Aura AI automatically switches to **Offline Auth Mode**, hashing credentials locally using SHA-256 for secure local storage.
- **Firebase Setup**: To enable full Firebase Auth and Google Sign-In, place `google-services.json` in `android/app/` (or `GoogleService-Info.plist` in `ios/Runner/`) and configure your Firebase project details.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---
Made with ❤️ using **Flutter** & **Dart**.
