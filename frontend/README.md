# Arth AI – Frontend

The frontend of **Arth AI** is a modern, AI-powered mobile application built using **Flutter**.
It delivers a seamless user experience for managing personal finances through voice, text, and interactive dashboards.

---

## Core Idea

Arth is not just a finance app — it is an **AI-powered personal financial assistant** that:

- Understands natural language (e.g., *"I spent ₹200 on food"*)
- Tracks expenses, income, budgets, and goals
- Provides real-time insights and financial health analysis
- Supports multilingual interaction (English and Tamil)

---

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Voice Integration**: speech_to_text, flutter_tts
- **Network/API**: http (connected to FastAPI backend)
- **Local Storage**: shared_preferences

---

## Project Structure

```
lib/
├── ..._screen.dart    # UI Screens (home, chat, budget, etc.)
├── ..._provider.dart  # State Management
├── ..._service.dart   # API & Business Logic
├── ..._model.dart     # Data Models
├── app_strings.dart   # Localization
└── main.dart          # Entry Point
```

---

## Key Features

### AI Chat & Voice Interface

- Speak or type to interact with Arth
- Converts natural language into financial actions
- Supports English and Tamil language toggle

### Dynamic Dashboard

- Real-time overview of income, expenses, and savings
- Displays AI-generated insights
- Shows alerts and financial summaries

### Budget & Goal Tracking

- Visual progress indicators for budgets
- Color-coded warnings for spending limits
- Track savings goals with estimated completion

### Financial Health Score

- Provides a score from 1–100
- Based on:
  - savings rate
  - debt ratio
  - net worth

- Includes detailed breakdown and analysis

---

## App Flow

1. User logs in (Google or Email)
2. User completes profile setup (income, assets, family details)
3. Home screen loads personalized financial data
4. User interacts via voice/text to log transactions
5. Data is sent to FastAPI backend
6. UI updates dynamically with insights and analytics

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/RohithRV2006/ArthAI.git
cd ArthAI/frontend
```

---

### 2. Install Dependencies

```bash
flutter pub get
```

---

### 3. Configure Backend Connection

Update your API base URL:

```
Android Emulator: http://10.0.2.2:8000
iOS Simulator / Desktop: http://127.0.0.1:8000
Physical Device: http://<YOUR_WIFI_IPV4_ADDRESS>:8000
```

---

### 4. Run the Application

```bash
flutter run
```

---

## Key Screens

### home_screen.dart

- Displays financial summary, health score, and AI insights

### ai_chat_screen.dart

- Core AI interaction screen with voice and text support

### budget_screen.dart / goal_screen.dart

- Budget tracking and savings goal management

### financial_health_screen.dart

- Animated score with detailed financial breakdown

### profile_screen.dart

- User profile, preferences, and language settings

---

## Future Improvements

- Biometric authentication (Face ID / Fingerprint)
- SMS-based transaction detection
- Dark and light mode support
- Push notifications for reminders

---

## This project is made at an 18 hrs Hackthon conducted by Coding Ninjas SCE Team on 31st March 2026

---

## Note

This frontend is part of the **Arth AI ecosystem** and requires the FastAPI backend to function properly.

---
