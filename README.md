<div align="center">

<img src="assets/icons.jpg" alt="Pulse Exchange Logo" width="100" height="100" style="border-radius: 20px;" />

# 💓 Pulse Exchange

### *Your AI-powered fitness companion — track, analyze, and elevate your health.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.2-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Core-FFCA28?logo=firebase)](https://firebase.google.com)
[![ChatGPT](https://img.shields.io/badge/ChatGPT-AI%20Assistant-74AA9C?logo=openai)](https://openai.com)
[![Mapbox](https://img.shields.io/badge/Mapbox-Maps-000000?logo=mapbox)](https://mapbox.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?logo=flutter)](https://flutter.dev)

</div>

---

## 📖 About Pulse Exchange

**Pulse Exchange** is an advanced AI-powered fitness and health tracking Flutter application. It combines wearable device connectivity via Bluetooth, real-time GPS activity tracking, interactive charts, and a built-in ChatGPT assistant — all in one sleek cross-platform app. Whether you're running, cycling, or monitoring your vitals, Pulse Exchange delivers a smart, personalized health experience on both Android and iOS.

---

## 🚀 Key Features

- 🤖 **AI Health Assistant** — Built-in ChatGPT integration for personalized fitness advice, workout planning, and health Q&A
- 🗺️ **Live Activity Tracking** — Real-time GPS route mapping powered by Mapbox for runs, walks, and cycling sessions
- 📊 **Interactive Health Charts** — Beautiful, animated charts (fl_chart) for visualizing fitness progress, heart rate, and activity trends
- 🦷 **Bluetooth Wearable Sync** — Connect and sync data from Bluetooth fitness devices via `flutter_blue_plus`
- 🎙️ **Voice Input** — Hands-free interaction with Speech-to-Text for logging workouts or querying the AI assistant
- 📸 **Camera Integration** — In-app camera for progress photos and body tracking
- 🔐 **Biometric Authentication** — Fingerprint and Face ID login with `local_auth` for secure, fast access
- 🔒 **Secure Data Storage** — Sensitive health data encrypted with `flutter_secure_storage`
- 📍 **Location-Based Features** — GPS location tracking for outdoor activities and route history
- 📄 **CSV Export** — Export health data and workout history to CSV for external analysis
- 🕐 **Timezone-Aware Scheduling** — Smart reminders and scheduling that respect user timezone
- ✨ **Premium Animations** — Lottie animations, animated text, and smooth transitions via `flutter_animate` and `animate_do`
- 🌐 **Markdown Support** — Rich AI responses rendered beautifully with `flutter_markdown`
- 🌍 **Multi-Language & Localization** — Full internationalization support with `intl`
- 🔗 **URL Launcher** — In-app links to external resources, articles, and workout guides
- 📱 **Device-Aware** — Device info detection for optimized performance across devices

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.7.2 |
| **State Management** | Provider 6.x |
| **Authentication** | Firebase Auth + Google Sign-In + Biometric (local_auth) |
| **AI Integration** | ChatGPT API (chat_gpt_api) |
| **Maps & Navigation** | Mapbox Maps Flutter |
| **Bluetooth** | flutter_blue_plus (wearable device sync) |
| **Charts & Analytics** | fl_chart |
| **Voice Input** | speech_to_text |
| **Camera** | camera package |
| **Secure Storage** | flutter_secure_storage |
| **Local Storage** | shared_preferences |
| **Networking** | HTTP package |
| **Media** | Image Picker, Cached Network Image |
| **Animations** | Lottie, flutter_animate, animate_do, animated_text_kit |
| **Data Export** | CSV package |
| **Timezone** | timezone + flutter_timezone |
| **Environment Config** | flutter_dotenv |
| **ID Generation** | ULID |
| **Typography** | Google Fonts, Font Awesome Flutter |
| **Localization** | Intl |
| **Permissions** | permission_handler |
| **App Icon** | flutter_launcher_icons |

---

## 🏗️ Project Structure

```
pulse_exchange/
├── lib/
│   ├── core/                        # App-wide utilities, theme & constants
│   │   ├── theme/                   # Color palette, text styles, app theme
│   │   └── utils/                   # Helpers, formatters, validators
│   ├── data/                        # Data layer
│   │   ├── models/                  # User, Workout, Activity, HealthData models
│   │   └── repositories/            # API, Bluetooth & local data repositories
│   ├── providers/                   # Provider state management
│   │   ├── auth_provider.dart       # Firebase Auth + Google Sign-In state
│   │   ├── workout_provider.dart    # Active workout & session state
│   │   └── health_provider.dart     # Health metrics & chart data state
│   ├── screens/                     # Feature-based UI screens
│   │   ├── auth/                    # Login, Register, Biometric auth
│   │   ├── home/                    # Dashboard with stats overview
│   │   ├── tracking/                # Live GPS activity tracking (Mapbox)
│   │   ├── charts/                  # Health analytics & fl_chart visualizations
│   │   ├── ai_assistant/            # ChatGPT-powered fitness advisor
│   │   ├── bluetooth/               # Wearable device pairing & data sync
│   │   ├── camera/                  # Progress photo capture
│   │   └── profile/                 # User profile, settings & data export
│   ├── widgets/                     # Reusable UI components
│   │   ├── animated_stat_card.dart  # Lottie-animated health stat cards
│   │   ├── chart_widget.dart        # Reusable fl_chart wrapper
│   │   └── voice_input_button.dart  # Speech-to-text input button
│   └── main.dart                    # App entry point, env config & Firebase init
├── assets/
│   └── icons.jpg                    # App icon
├── .env                             # API keys (gitignored)
├── pubspec.yaml
└── README.md
```

> 📌 The project follows a **feature-first layered architecture** with Provider for state management, separating data, business logic, and UI for a scalable and maintainable codebase.

---

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK `^3.7.2` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- Dart SDK `^3.7.2`
- Android Studio / Xcode
- Firebase project with Auth enabled
- OpenAI API key (for ChatGPT integration)
- Mapbox account and access token

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/pulse-exchange.git
cd pulse_exchange

# 2. Install dependencies
flutter pub get

# 3. Configure environment variables
# Create a .env file in the project root:
echo "OPENAI_API_KEY=your_openai_key" >> .env
echo "MAPBOX_ACCESS_TOKEN=your_mapbox_token" >> .env

# 4. Configure Firebase
# - Place google-services.json in android/app/
# - Place GoogleService-Info.plist in ios/Runner/

# 5. Generate app icons
dart run flutter_launcher_icons

# 6. Run the app
flutter run
```

### Environment Variables (`.env`)

```env
OPENAI_API_KEY=your_openai_api_key
MAPBOX_ACCESS_TOKEN=your_mapbox_access_token
```

> ⚠️ Never commit your `.env` file — it's already in `.gitignore`

---

## 🔮 Future Roadmap

- 🏃 **Social Challenges** — Compete with friends on leaderboards
- 🍎 **Nutrition Tracking** — AI-powered meal logging and calorie counting
- 🏥 **Doctor Integration** — Share health reports with physicians
- 🌙 **Sleep Tracking** — Monitor and analyze sleep patterns
- ⌚ **Apple Watch / WearOS** — Native wearable app companion
- 📊 **Advanced Analytics** — Predictive health insights using ML

---

<div align="center">
  <sub>Built with 💙 using Flutter · Powered by ChatGPT & Mapbox · Secured with Firebase</sub><br/>
  <sub>⭐ Star this repo if you found it helpful!</sub>
</div>
