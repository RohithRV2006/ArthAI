from app.config.db import transactions_col, summary_col
from app.services.user_service import get_user_profile
from datetime import datetime


# ==============================
# 🔥 TAMIL TRANSLATIONS
# ==============================
_TAMIL = {
    # Category dominance
    "Very high spending on {cat} ({pct}%)":     "மிக அதிகமான {cat} செலவு ({pct}%)",
    "High spending on {cat} ({pct}%)":           "அதிகமான {cat} செலவு ({pct}%)",
    # Savings
    "Very low savings rate":                     "மிகக் குறைந்த சேமிப்பு விகிதம்",
    "Savings can be improved":                   "சேமிப்பை மேம்படுத்தலாம்",
    # Time-based
    "High weekend spending habit":               "வார இறுதி செலவு அதிகமாக உள்ளது",
    # Spikes
    "Irregular high spending spikes":            "திடீர் அதிக செலவுகள் காணப்படுகின்றன",
    # Small leakage
    "Frequent small expenses adding up":         "சிறு செலவுகள் அடிக்கடி கூடுகின்றன",
    # Income vs lifestyle
    "Expenses are very close to income":         "செலவுகள் வருமானத்திற்கு மிக அருகில் உள்ளன",
    "High spending compared to income":          "வருமானத்தை விட செலவு அதிகமாக உள்ளது",
    # Stable
    "Your spending behavior looks stable":       "உங்கள் செலவு பழக்கம் நிலையாக உள்ளது",
}


def _translate(pattern: str, language: str) -> str:
    """Translate a pattern string to Tamil if needed."""
    if language != "tamil":
        return pattern

    # Dynamic patterns with {cat} and {pct}
    for en_template, ta_template in _TAMIL.items():
        if "{cat}" in en_template:
            # e.g. "Very high spending on food (45.0%)"
            prefix = en_template.split("{cat}")[0]  # "Very high spending on "
            if pattern.startswith(prefix):
                # extract cat and pct from the live string
                rest = pattern[len(prefix):]         # "food (45.0%)"
                paren_idx = rest.rfind(" (")
                if paren_idx != -1:
                    cat = rest[:paren_idx]
                    pct = rest[paren_idx + 2:].rstrip(")")
                    return ta_template.format(cat=cat, pct=pct)

    # Static patterns
    return _TAMIL.get(pattern, pattern)


# ==============================
# 🔥 MAIN FUNCTION
# ==============================
def analyze_behavior(user_id: str, language: str = "english"):
    patterns = []

    summary = summary_col.find_one({"user_id": user_id})

    if not summary:
        return {"patterns": [], "message": "Not enough data"}

    categories = summary.get("category_breakdown", {})
    monthly = summary.get("monthly", {})
    total_expense = monthly.get("expense", 0)

    if total_expense == 0:
        return {"patterns": [], "message": "No expense data"}

    # ==============================
    # 🧠 1. CATEGORY DOMINANCE
    # ==============================
    for category, amount in categories.items():
        percent = (amount / total_expense) * 100

        if percent > 50:
            patterns.append({
                "pattern": f"Very high spending on {category} ({round(percent, 1)}%)",
                "severity": "high"
            })
        elif percent > 30:
            patterns.append({
                "pattern": f"High spending on {category} ({round(percent, 1)}%)",
                "severity": "medium"
            })

    # ==============================
    # 📉 2. SAVINGS ANALYSIS
    # ==============================
    income = 0
    try:
        profile = get_user_profile(user_id)
        income = profile.get("derived", {}).get("total_income", 0)
        savings = profile.get("monthly_savings", 0)

        if income > 0:
            savings_rate = (savings / income) * 100

            if savings_rate < 10:
                patterns.append({
                    "pattern": "Very low savings rate",
                    "severity": "high"
                })
            elif savings_rate < 20:
                patterns.append({
                    "pattern": "Savings can be improved",
                    "severity": "medium"
                })
    except:
        pass

    # ==============================
    # 📅 3. TIME-BASED PATTERNS
    # ==============================
    transactions = []
    try:
        transactions = list(transactions_col.find({"user_id": user_id}))

        weekend_spend = 0
        weekday_spend = 0

        for t in transactions:
            date_obj = datetime.strptime(t["date"], "%Y-%m-%d")
            if date_obj.weekday() >= 5:
                weekend_spend += t["amount"]
            else:
                weekday_spend += t["amount"]

        if weekend_spend > weekday_spend * 0.6:
            patterns.append({
                "pattern": "High weekend spending habit",
                "severity": "medium"
            })
    except:
        pass

    # ==============================
    # 📈 4. SPENDING SPIKES
    # ==============================
    try:
        amounts = [t["amount"] for t in transactions]

        if len(amounts) >= 5:
            avg = sum(amounts) / len(amounts)
            spikes = sum(1 for a in amounts if a > avg * 2)

            if spikes >= 2:
                patterns.append({
                    "pattern": "Irregular high spending spikes",
                    "severity": "high"
                })
    except:
        pass

    # ==============================
    # 🪙 5. SMALL EXPENSE LEAKAGE
    # ==============================
    try:
        small_txns = [t for t in transactions if t["amount"] < 100]

        if len(small_txns) > 10:
            patterns.append({
                "pattern": "Frequent small expenses adding up",
                "severity": "medium"
            })
    except:
        pass

    # ==============================
    # 💳 6. INCOME vs LIFESTYLE
    # ==============================
    try:
        if income > 0:
            expense_ratio = total_expense / income

            if expense_ratio > 0.9:
                patterns.append({
                    "pattern": "Expenses are very close to income",
                    "severity": "high"
                })
            elif expense_ratio > 0.7:
                patterns.append({
                    "pattern": "High spending compared to income",
                    "severity": "medium"
                })
    except:
        pass

    # ==============================
    # 🔥 CLEAN + PRIORITY SORT
    # ==============================
    severity_order = {"high": 1, "medium": 2, "low": 3}
    patterns = list({p["pattern"]: p for p in patterns}.values())
    patterns.sort(key=lambda x: severity_order.get(x["severity"], 3))

    # ==============================
    # 🔥 TRANSLATE IF TAMIL
    # ==============================
    if language == "tamil":
        patterns = [
            {**p, "pattern": _translate(p["pattern"], language)}
            for p in patterns
        ]

    # ==============================
    # 🧠 FINAL OUTPUT
    # ==============================
    if not patterns:
        stable = _translate("Your spending behavior looks stable", language)
        return {
            "patterns": [{"pattern": stable, "severity": "low"}]
        }

    return {"patterns": patterns}
