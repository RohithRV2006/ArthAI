from google import genai
from google.genai import types
import os
import json
import re
from datetime import datetime

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# Allowed categories (central control)
ALLOWED_CATEGORIES = [
    "food", "travel", "shopping", "bills", "health", "education", "others"
]


# ==============================
# 🧠 LANGUAGE HELPER
# ==============================
def get_language_instruction(language: str):
    if language == "tamil":
        return "Respond in simple conversational Tamil."
    return "Respond in clear English."


# ==============================
# MAIN PARSER (NO BREAKING CHANGE)
# ==============================
def classify_and_parse(text, language="english"):
    today = datetime.today().strftime("%Y-%m-%d")

    prompt = f"""
    You are a STRICT financial NLP parser.

    Your job:
    1. Identify intent
    2. Extract structured financial data

    ============================
    INTENTS:
    - expense: money spent
    - income: money received
    - query: questions, greetings, or general chat
    - habit: general behavior
    - goal: saving intention
    ============================

    STRICT RULES:
    - If NO amount → NOT expense/income → use "query"
    - Greetings ("hi", "hello", "hey") → "query"
    - Questions → "query"
    - NEVER guess missing numbers

    ============================
    CATEGORY RULES:
    Allowed categories ONLY:
    {ALLOWED_CATEGORIES}

    Mapping:
    - lunch, dinner, breakfast, snacks → food
    - vegetables, groceries → food
    - bus, train, auto, uber, petrol → travel
    - going to school/college/office → travel
    - fees, books → education

    If unsure → "others"
    ============================

    OUTPUT FORMAT (STRICT JSON ARRAY):
    [
      {{
        "intent": "expense/income/query/habit/goal",
        "data": {{
          "type": "expense/income",
          "amount": number,
          "category": "string",
          "subcategory": "string",
          "payment_method": "string",
          "notes": "string",
          "date": "{today}"
        }}
      }}
    ]

    RULES:
    - ALWAYS return JSON ARRAY ONLY

    Input: "{text}"
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            )
        )

        parsed = json.loads(response.text)

        if isinstance(parsed, dict):
            parsed = [parsed]

        # ==============================
        # POST-PROCESSING (UNCHANGED)
        # ==============================
        for item in parsed:
            if not item.get("data"):
                item["data"] = {}

            data = item["data"]

            raw_amt = str(data.get("amount", "0"))
            clean_amt = re.sub(r'[^\d.]', '', raw_amt)

            try:
                data["amount"] = float(clean_amt) if clean_amt else 0.0
            except:
                data["amount"] = 0.0

            data["date"] = today

            raw_cat = str(data.get("category", "others")).lower()
            if raw_cat not in ALLOWED_CATEGORIES:
                raw_cat = "others"
            data["category"] = raw_cat

            data["subcategory"] = str(data.get("subcategory", "") or "").lower()
            data["payment_method"] = str(data.get("payment_method", "") or "").lower()
            data["notes"] = str(data.get("notes", "") or "").strip()

            intent = str(item.get("intent", "query")).lower()
            if intent not in ["expense", "income", "query", "habit", "goal"]:
                intent = "query"
            item["intent"] = intent

            if intent in ["expense", "income"]:
                data["type"] = intent
            else:
                data["type"] = "unknown"

        return parsed

    except Exception as e:
        print("Gemini Error:", e)
        return []


# ==============================
# 💬 GENERIC RESPONSE (UPGRADED)
# ==============================
def get_llm_response(prompt: str, language="english"):
    try:
        lang_instruction = get_language_instruction(language)

        full_prompt = f"""
        {lang_instruction}

        {prompt}
        """

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=full_prompt
        )

        return response.text.strip()

    except Exception as e:
        print("LLM Error:", e)
        return "Unable to generate response right now."