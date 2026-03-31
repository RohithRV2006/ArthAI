ArthAI

Arth is an intelligent, voice-enabled personal finance management system designed to simplify how individuals track, understand, and improve their financial life. Unlike traditional expense trackers, Arth acts as a smart financial companion that understands natural language, analyzes behavior, and provides actionable insights in real time.

Home Finance Management System  
Personal Budget and Expense Management Platform  

---

## Project Overview

ArthAI is a full-stack AI-powered financial management platform that combines:

- A Flutter-based mobile frontend for user interaction  
- A FastAPI-based backend for processing, intelligence, and data management  

The system enables users to manage finances effortlessly using voice or text, while receiving intelligent insights and recommendations.

---

## Core Concept

Arth is designed as a **personal financial assistant**, not just a tracker.

It focuses on:

- Natural interaction (voice/text instead of manual entry)  
- Intelligent analysis (AI-driven insights)  
- Real-time feedback (instant updates and alerts)  

Users can simply say:

"I spent ₹200 on lunch"

And the system will:

- Understand the intent  
- Categorize the expense  
- Store it  
- Update dashboards  
- Provide insights  

---

## System Architecture

Frontend (Flutter App)  
↓  
API Communication (HTTP)  
↓  
Backend (FastAPI Server)  
↓  
Database (MongoDB)  
↓  
AI Engine (Google Gemini API)  

---

## Frontend Overview

The frontend is a cross-platform mobile application built using Flutter.

### Responsibilities

- User interaction (UI/UX)  
- Voice and text input handling  
- Displaying dashboards and insights  
- Sending requests to backend  
- Rendering real-time updates  

### Key Features

- AI Chat Interface (Voice + Text)  
- Dynamic Financial Dashboard  
- Budget and Goal Visualization  
- Financial Health Score  
- English and Tamil language support  

---

## Backend Overview

The backend is an AI-powered engine built using FastAPI.

### Responsibilities

- Processing natural language input  
- Managing financial data  
- Running AI models for insights  
- Handling API requests  
- Updating database  

### Key Features

- NLP-based intent detection  
- Expense and income tracking  
- Budget and goal management  
- AI-generated insights  
- Financial health scoring  

---

## Tech Stack

### Frontend

- Flutter  
- Dart  
- Provider (State Management)  
- speech_to_text, flutter_tts  
- http  
- shared_preferences  

### Backend

- FastAPI  
- Python  
- MongoDB  
- Google Gemini API  

---

## End-to-End Flow

1. User speaks or types input  
2. Frontend converts speech to text  
3. Request sent to backend API  
4. AI processes and extracts intent  
5. Data validated and stored in MongoDB  
6. Backend updates financial metrics  
7. AI generates insights  
8. Response sent to frontend  
9. UI updates instantly  

---

## Project Structure

### Frontend

```
lib/
├── ..._screen.dart
├── ..._provider.dart
├── ..._service.dart
├── ..._model.dart
├── app_strings.dart
└── main.dart
```

### Backend

```
app/
├── config/
├── routes/
├── schemas/
├── services/
├── utils/

main.py
```

---

## Key Functional Modules

- Expense Tracking  
- Income Tracking  
- Budget Management  
- Goal Tracking  
- AI Insights Engine  
- Financial Health Evaluation  

---

## Getting Started

### Clone Repository

```
git clone https://github.com/RohithRV2006/ArthAI.git
cd ArthAI
```

---

### Backend Setup

```
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Create .env file:

```
GEMINI_API_KEY=your_api_key
MONGO_URI=your_mongodb_uri
```

Run server:

```
uvicorn app.main:app --reload
```

---

### Frontend Setup

```
cd frontend
flutter pub get
flutter run
```

---

## API Integration

- Base URL configured in frontend  
- Communicates via REST APIs  
- Main endpoint:

```
POST /ai/process
```

---

## Testing

Backend Swagger UI:

```
http://localhost:8000/docs
```

---

## Future Improvements

- Biometric authentication  
- Bank API integration  
- Investment tracking  
- SMS-based expense detection  
- Real-time push notifications  

---

## Hackathon Details

This project is developed during an 18-hour Hackathon conducted by Coding Ninjas SCE Team on 31st March 2026.

---

## Note

ArthAI is a complete ecosystem consisting of both frontend and backend.  
Both components must run together for full functionality.

---
