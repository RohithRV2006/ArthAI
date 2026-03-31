import re


def preprocess_input(text: str) -> str:
    """
    Clean and normalize user input before sending to AI.
    This improves parsing accuracy.
    """

    if not text:
        return ""

    text = text.strip()

    # ------------------------------
    # Normalize currency
    # ------------------------------
    text = text.replace("₹", "")
    text = re.sub(r'\brs\.?\b', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\brupees\b', '', text, flags=re.IGNORECASE)

    # ------------------------------
    # Normalize spacing
    # ------------------------------
    text = re.sub(r'\s+', ' ', text)

    # ------------------------------
    # Fix common variations
    # ------------------------------
    text = text.replace("spent on", "spent")
    text = text.replace("expense on", "spent")
    text = text.replace("paid for", "spent")

    # ------------------------------
    # Lowercase (optional but useful)
    # ------------------------------
    text = text.lower()

    return text