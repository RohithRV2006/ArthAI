from app.config.db import summary_col
from google import genai
from google.genai import types
import os
import json

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# ==============================
# 🔥 LANGUAGE HELPERS
# ==============================
def _normalize_lang(language: str) -> str:
    if not language:
        return "english"
    return language.lower()


def _lang_instruction(language: str) -> str:
    language = _normalize_lang(language)

    if language == "tamil":
        return """CRITICAL RULE: Respond fully in Tamil (தமிழ்).
Use natural conversational Tamil.
Avoid mixing English unless necessary.
Use ₹ for currency."""
    
    return "Respond in English. Use ₹ for currency."


# ==============================
# 🔹 1. Context-aware personalized insights (Chatbot)
# ==============================
def generate_insight(user_text, memory_context=None, language: str = "english"):
    language = _normalize_lang(language)

    context_text = ""
    if memory_context:
        context_text = "\n".join(memory_context[-5:])

    lang = _lang_instruction(language)

    prompt = f"""
    {lang}

    You are a highly intelligent financial advisor named Arth.

    User Context:
    {context_text}

    User Question:
    {user_text}

    Instructions:
    - Give short (2-3 lines)
    - Be specific and data-driven
    - Highlight risks clearly
    - Suggest actionable improvements
    - Avoid generic advice
    - If overspending affects goals → mention it
    - If savings is low → suggest improvement
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )

        return {"insight": response.text.strip()}

    except Exception as e:
        print("Chat Insight Error:", e)

        fallback = (
            "மன்னிக்கவும், இப்போது பதிலளிக்க முடியவில்லை."
            if language == "tamil"
            else "Sorry, I am unable to process that right now."
        )

        return {"insight": fallback}


# ==============================
# 🔹 2. Data-based insights (Dashboard)
# ==============================
def generate_data_insights(user_id: str, language: str = "english"):
    language = _normalize_lang(language)

    summary = summary_col.find_one({"user_id": user_id})
    if not summary:
        return {"message": "No financial data available"}

    monthly = summary.get("monthly", {})
    categories = summary.get("category_breakdown", {})

    income = monthly.get("income", 0)
    expense = monthly.get("expense", 0)
    savings = monthly.get("savings", 0)

    savings_rate = 0
    if income > 0:
        savings_rate = round((savings / income) * 100, 2)

    summary_text = f"""
Income: ₹{income}
Expense: ₹{expense}
Savings: ₹{savings}
Savings Rate: {savings_rate}%
Category Breakdown:
{categories}
"""

    lang = _lang_instruction(language)

    prompt = f"""
    {lang}

    Analyze this financial data:
    {summary_text}

    Instructions:
    - Give exactly 3 insights based on the data.
    - Mention real numbers and give actionable suggestions.
    - Title must be short (1-4 words).
    - Description must be 1-3 lines.
    - Category must strictly be one of: "summary", "behavior", or "goal".

    Format exactly as this JSON array:
    [
      {{
        "title": "Short Title here",
        "description": "Detailed explanation here",
        "category": "summary"
      }}
    ]
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            )
        )

        # 🔥 Safe JSON parsing
        try:
            insights_list = json.loads(response.text)

            if not isinstance(insights_list, list):
                raise ValueError("Invalid format")

        except Exception as parse_error:
            print("JSON Parse Error:", parse_error)
            raise Exception("Invalid AI JSON")

    except Exception as e:
        print("Insight Generation Error:", e)

        # Safe fallback (Flutter won't crash)
        if language == "tamil":
            insights_list = [{
                "title": "பிழை",
                "description": "தற்போது நுண்ணறிவுகளை ஏற்ற முடியவில்லை.",
                "category": "summary"
            }]
        else:
            insights_list = [{
                "title": "Error",
                "description": "Could not load insights at this time.",
                "category": "summary"
            }]

    return {
        "summary": summary_text,
        "insights": insights_list
    }