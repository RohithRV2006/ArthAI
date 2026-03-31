import requests
from fastapi import APIRouter, HTTPException
import os
from pydantic import BaseModel

router = APIRouter()

class TranslateRequest(BaseModel):
    text: str
    target_lang: str

@router.post("/translate")
def translate_text(req: TranslateRequest):
    # 1. If the text is empty, just return it
    if not req.text.strip():
        return {"translated_text": req.text}

    # 2. Figure out the language code (Google uses 'ta' for Tamil)
    lang_code = "ta" if req.target_lang.lower() == "tamil" else "en"
    
    # 3. If they want English, no need to translate!
    if lang_code == "en":
        return {"translated_text": req.text}

    # 4. Talk to Google securely
    url = f"https://translation.googleapis.com/language/translate/v2?key={os.getenv('GOOGLE_API_KEY')}"
    payload = {
        "q": req.text,
        "target": lang_code,
        "format": "text"
    }
    
    response = requests.post(url, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        translated = data["data"]["translations"][0]["translatedText"]
        return {"translated_text": translated}
    else:
        print(f"Google API Error: {response.text}")
        raise HTTPException(status_code=400, detail="Translation failed")
