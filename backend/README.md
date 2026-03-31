# Arth AI – Backend

The backend of **Arth AI** is a powerful, AI-driven financial engine built using **FastAPI**.
It processes natural language inputs, manages financial data, and generates intelligent insights to help users make better financial decisions.

---

## Core Idea

Arth is not just an expense tracker — it is an **AI-powered financial assistant** that:

* Understands natural language (e.g., *"I spent 200 on food"*)
* Tracks income, expenses, budgets, and goals
* Provides real-time financial insights and recommendations

---

## Tech Stack

* **Framework**: FastAPI
* **Database**: MongoDB
* **AI Integration**: Google Gemini API
* **Language**: Python

---

## Project Structure

```
app/
├── config/        # Database configuration
├── routes/        # API endpoints
├── schemas/       # Pydantic models
├── services/      # Business logic
├── utils/         # Helper functions

main.py            # Entry point
```

---

## Key Features

### AI-Powered Input Processing

* Converts natural language into structured financial data
* Supports intents:

  * Expense
  * Income
  * Goal
  * Query

### Expense & Income Tracking

* Automatically logs transactions
* Smart category normalization

### Budget Management

* Set limits for categories
* Real-time alerts on overspending

### Goal Tracking

* Create and track savings goals
* Predict completion timelines

### AI Insights & Recommendations

* Personalized financial advice
* Behavior analysis and pattern detection

### Financial Health Score

* Evaluates:

  * income
  * spending
  * savings
  * liabilities

---

## API Flow

1. User sends input (text/voice)
2. AI classifies intent
3. Data is extracted and validated
4. Stored in database
5. System updates:

   * summary
   * budgets
   * alerts
6. AI generates insights

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/RohithRV2006/ArthAI.git
cd ArthAI/backend
```

### 2. Create Virtual Environment

```bash
python -m venv venv
source venv/bin/activate   # Mac/Linux
venv\Scripts\activate      # Windows
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Setup Environment Variables

Create a `.env` file:

```
GEMINI_API_KEY=your_api_key
MONGO_URI=your_mongodb_uri
```

---

### 5. Run the Server

```bash
uvicorn app.main:app --reload
```

---

## API Endpoints

### 🔹 AI Processing

```
POST /ai/process
```

Processes user input and returns:

* transactions
* insights
* financial health
* recommendations

---

### 🔹 Insights

```
GET /ai/insights/{user_id}
```

---

### 🔹 Other Modules

* Budget APIs
* Goal APIs
* User Profile APIs
* Financial Health APIs

---

## Testing

Open Swagger UI:

```
http://localhost:8000/docs
```

---

## Security (To Be Improved)

* JWT Authentication (planned)
* Role-based access (future scope)

---

## Future Improvements

* Voice integration (STT + TTS)
* Bank API integration
* Investment tracking
* Real-time notifications

---

## This project is made at an 18 hrs Hackthon conducted by Coding Ninjas SCE Team on 31st March 2026

---

## Note

This backend is part of the **Arth AI ecosystem**, which includes a Flutter-based frontend application.

---
