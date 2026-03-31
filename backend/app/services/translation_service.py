from google import genai
import os

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))


def translate_to_tamil(text: str) -> str:
    prompt = f"""
    Translate the following text into simple, natural Tamil.
    
    Rules:
    - Keep meaning exact
    - Use conversational Tamil
    - Do not add extra explanation

    Text: "{text}"
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )
        return response.text.strip()
    except:
        return text