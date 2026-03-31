from google import genai
import os

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

ALLOWED_CATEGORIES = [
    "food", "travel", "shopping", "bills", "health", "education", "others"
]


def llm_category_fallback(text: str) -> str:
    """
    Use LLM to classify category when rule-based mapper fails
    """

    prompt = f"""
    Classify the following expense into ONE category.

    Allowed categories:
    {ALLOWED_CATEGORIES}

    Rules:
    - Return ONLY one word
    - Do not explain
    - Do not create new categories
    - If unsure, return "others"

    Input: "{text}"
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )

        category = response.text.strip().lower()

        if category in ALLOWED_CATEGORIES:
            return category

        return "others"

    except Exception as e:
        print("LLM Category Error:", e)
        return "others"