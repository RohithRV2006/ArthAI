Arth AI – Frontend
The frontend of Arth AI is a sleek, cross-platform mobile application built using Flutter.
It provides an intuitive, AI-driven interface for users to interact with their personal finance assistant through voice and text, visualize their spending, and track their financial health in real-time.

Core Idea
Arth is designed to feel like a personal financial advisor in your pocket. Through this app, users can:

Talk to Arth naturally (e.g., "I spent ₹200 on lunch today") using Voice or Text.

View beautifully animated dashboards for their budgets, goals, and net worth.

Receive proactive AI insights and alerts directly on their home screen.

Seamlessly switch between English and Tamil (தமிழ்).

Tech Stack
Framework: Flutter

Language: Dart

State Management: Provider

Voice Integration: speech_to_text & flutter_tts

Network/API: http (Connects to FastAPI Backend)

Local Storage: shared_preferences

Project Structure
For rapid development during the hackathon, the frontend uses a flat directory structure inside the lib/ folder, categorized by naming conventions:

Plaintext
lib/
├── ..._screen.dart    # UI Views (e.g., home_screen.dart, ai_chat_screen.dart)
├── ..._provider.dart  # State Management (e.g., dashboard_provider.dart, budget_provider.dart)
├── ..._service.dart   # API & Logic (e.g., api_service.dart, auth_service.dart)
├── ..._model.dart     # Data Classes (e.g., expense_model.dart, user_model.dart)
├── app_strings.dart   # Localization & Text
└── main.dart          # Application Entry Point
Key Features
🎙️ AI Chat & Voice Interface
Speak directly to the app using the built-in microphone.

Supports Natural Language Processing (NLP) to log expenses or ask financial questions.

Features an English / Tamil toggle for localized voice recognition.

Dynamic Dashboard
Real-time financial summary (Income, Expense, Savings).

Interactive AI Insights generated dynamically based on user habits.

Urgent alerts and notifications.

Budget & Goal Visualizations
Visual progress bars indicating budget usage.

Color-coded risk indicators (Green/Orange/Red) for nearing limits.

Track savings goals with predicted completion timelines.

Financial Health Score
An animated, gamified 1-100 score evaluating overall financial wellness.

Detailed diagnostic breakdowns (Savings Rate, Debt-to-Income, Net Worth).

App Flow
User opens the app and authenticates (Google/Email).

User completes the Profile Setup (Income, Family details, Assets).

The Home Screen loads personalized data and AI insights from the backend.

User taps the Arth AI Mic to log a transaction via voice.

The App sends the text to the FastAPI backend, which parses the intent.

The App dynamically refreshes, instantly updating the UI, charts, and budget bars.

Getting Started
1. Clone the Repository
Bash
git clone https://github.com/RohithRV2006/ArthAI.git
cd ArthAI/frontend
2. Install Dependencies
Ensure you have the Flutter SDK installed, then run:

Bash
flutter pub get
3. Configure the Backend Connection
Locate your API service file (e.g., lib/api_service.dart or lib/api_constants.dart) and ensure the Base URL points to your running backend:

Android Emulator: http://10.0.2.2:8000

iOS Simulator / Desktop: http://127.0.0.1:8000

Physical Device: http://<YOUR_WIFI_IPV4_ADDRESS>:8000

4. Run the Application
Bash
flutter run
Key Screens
home_screen.dart: Displays Quick Stats, Financial Health Banner, and AI Insights.

ai_chat_screen.dart: The core conversational interface with Speech-to-Text and Text-to-Speech capabilities.

budget_screen.dart / goal_screen.dart: Interactive tabs for monitoring category limits, AI-suggested budgets, and saving targets.

financial_health_screen.dart: An animated gauge showing the user's score, paired with a detailed asset/liability breakdown.

profile_screen.dart: User management, language preferences, and family tracking.

Future Improvements
Biometric Authentication (FaceID/Fingerprint)

Automated SMS parsing for offline bank transactions

Dark/Light mode dynamic switching

Push notifications for daily budget reminders

This project is made at an 18 hrs Hackthon conducted by Coding Ninjas SCE Team on 31st March 2026
Note
This frontend is part of the Arth AI ecosystem, and requires the FastAPI backend to function correctly.
