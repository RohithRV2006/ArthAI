from difflib import get_close_matches
from app.services.category_fallback_service import llm_category_fallback

# ==============================
# 🎯 MAIN CATEGORY MAP
# ==============================
CATEGORY_MAP = {
    "food": [
        "food", "lunch", "dinner", "breakfast",
        "snacks", "meal", "restaurant", "hotel",
        "groceries", "vegetables", "fruits", "milk"
    ],
    "travel": [
        "travel", "bus", "train", "auto", "uber",
        "ola", "taxi", "petrol", "fuel", "diesel",
        "ticket", "ride", "commute"
    ],
    "shopping": [
        "shopping", "clothes", "dress", "shirt",
        "jeans", "electronics", "gadgets"
    ],
    "bills": [
        "bill", "electricity", "current", "water",
        "internet", "wifi", "rent", "recharge"
    ],
    "health": [
        "health", "hospital", "doctor", "medicine",
        "pharmacy", "clinic"
    ],
    "education": [
        "education", "fees", "books", "college",
        "school", "course", "tuition"
    ]
}


# ==============================
# 🧠 SEMANTIC PHRASE RULES (NEW)
# ==============================
SEMANTIC_RULES = [
    (["go", "going", "travel", "commute"], "travel"),
    (["school", "college", "office"], "travel"),  # movement implied
    (["eat", "food", "meal"], "food"),
    (["buy", "bought", "purchase"], "shopping"),
    (["fee", "tuition"], "education"),
]


# ==============================
# 🔍 NORMALIZATION FUNCTION
# ==============================
def normalize_category(text: str) -> str:
    if not text:
        return "others"

    text = text.lower().strip()

    # ------------------------------
    # 1. DIRECT MATCH
    # ------------------------------
    for category, keywords in CATEGORY_MAP.items():
        if text in keywords:
            return category

    # ------------------------------
    # 2. PARTIAL MATCH
    # ------------------------------
    for category, keywords in CATEGORY_MAP.items():
        for word in keywords:
            if word in text:
                return category

    # ------------------------------
    # 3. SEMANTIC RULES
    # ------------------------------
    words = text.split()

    for rule_words, category in SEMANTIC_RULES:
        if any(w in words for w in rule_words):
            return category

    # ------------------------------
    # 4. FUZZY MATCH
    # ------------------------------
    from difflib import get_close_matches
    all_keywords = [k for v in CATEGORY_MAP.values() for k in v]
    match = get_close_matches(text, all_keywords, n=1, cutoff=0.8)

    if match:
        for category, keywords in CATEGORY_MAP.items():
            if match[0] in keywords:
                return category

    # ------------------------------
    # 5. 🔥 LLM FALLBACK (NEW)
    # ------------------------------
    return llm_category_fallback(text)