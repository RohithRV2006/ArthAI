# Arth Flutter — Integration Guide

## Project Structure

```
lib/
├── main.dart                          ← App entry, providers, bottom nav
├── core/
│   ├── api/
│   │   ├── api_constants.dart         ← All endpoint URLs (edit base URL here)
│   │   ├── api_client.dart            ← HTTP GET/POST with error handling
│   │   ├── ai_service.dart            ← /ai/process  &  /ai/insights/{id}
│   │   └── expense_service.dart       ← /expense/add
│   ├── models/
│   │   ├── user_model.dart            ← User / MongoDB schema
│   │   ├── ai_models.dart             ← AiResponse, InsightModel, ChatMessage
│   │   └── expense_model.dart         ← ExpenseModel / ExpenseSchema
│   └── utils/
│       └── local_storage.dart         ← SharedPreferences (user session)
└── features/
    ├── ai_chat/
    │   ├── providers/
    │   │   └── ai_chat_provider.dart  ← Chat state, voice, language toggle
    │   └── screens/
    │       └── ai_chat_screen.dart    ← Full chat UI with mic + TTS
    └── dashboard/
        ├── providers/
        │   └── dashboard_provider.dart ← Fetches AI insights
        └── screens/
            └── home_screen.dart        ← Dashboard + insight cards
```

## Setup Steps

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Android permissions
Open `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```
And inside `<application>`:
```xml
android:usesCleartextTraffic="true"
```

### 3. iOS permissions
Open `ios/Runner/Info.plist` and add:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Arth needs microphone access for voice input</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Arth uses speech recognition to understand your voice</string>
```

### 4. Save a user session (after login)
When your auth system returns a user, call:
```dart
await LocalStorage.saveUser(UserModel(
  userId: 'your_user_id_from_mongodb',
  name: 'User Name',
  email: 'user@email.com',
));
```

## API Endpoints Used

| Method | Endpoint              | Purpose                        |
|--------|-----------------------|--------------------------------|
| POST   | /ai/process           | Send text/voice message to AI  |
| GET    | /ai/insights/{userId} | Fetch dashboard insights       |
| POST   | /expense/add          | Manually add an expense        |

## How the AI chat works

1. User speaks → `speech_to_text` transcribes to text
2. Text sent to `POST /ai/process` with `{user_id, text}`
3. Backend classifies intent (expense/income/saving/query)
4. Response displayed as chat bubble
5. If `type == data_saved` → green "Saved" badge shown
6. AI reply spoken aloud via `flutter_tts`

## Next screens to build
- `TransactionsScreen` — list + calendar view
- `BudgetScreen` — limits, savings goals, net worth
- `ProfileScreen` — user info, income sources, language
