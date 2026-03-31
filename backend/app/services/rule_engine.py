import re


def detect_intent_rule(text: str):
    text = text.lower()

    # Expense indicators
    expense_words = ["spent", "paid", "bought", "purchase"]
    income_words = ["earned", "salary", "received", "income"]

    # Amount detection
    amount_pattern = r"\d+"

    has_amount = re.search(amount_pattern, text)

    # 🔹 Soft decision logic
    if has_amount:
        if any(word in text for word in expense_words):
            return "expense"
        elif any(word in text for word in income_words):
            return "income"

    return None  # let AI decide