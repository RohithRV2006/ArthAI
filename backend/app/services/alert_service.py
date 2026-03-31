from app.services.budget_service import get_budget_status, predict_budget_risk
from app.services.goal_service import get_goals
from app.services.behavior_service import analyze_behavior
from app.services.financial_health_service import calculate_financial_health


# ==============================
# 🔥 TAMIL TRANSLATIONS
# ==============================
_TAMIL_ALERTS = {
    # Budget
    "budget exceeded":          "பட்ஜெட் மீறப்பட்டது",
    "budget almost used":       "பட்ஜெட் கிட்டத்தட்ட தீர்ந்துவிட்டது",
    # Goals
    "is at risk":               "ஆபத்தில் உள்ளது",
    "Goal":                     "இலக்கு",
    # Behavior
    "Very high spending":       "மிக அதிகமான செலவு",
    "High spending":            "அதிகமான செலவு",
    "Expenses are very close":  "செலவுகள் வருமானத்திற்கு மிக அருகில்",
    "Irregular high spending":  "திடீர் அதிக செலவுகள்",
    "Frequent small expenses":  "சிறு செலவுகள் அடிக்கடி",
    "Low savings":              "குறைந்த சேமிப்பு",
    # Health
    "Financial health is low":  "நிதி ஆரோக்கியம் குறைவாக உள்ளது",
}


def _translate_message(message: str, language: str) -> str:
    """Translate an alert message string to Tamil."""
    if language != "tamil":
        return message

    translated = message

    # Budget exceeded: "🚨 Food budget exceeded"
    if "budget exceeded" in translated.lower():
        # extract category name between emoji and "budget"
        clean = translated.replace("🚨", "").strip()
        parts = clean.split(" budget exceeded")
        cat = parts[0].strip() if parts else ""
        translated = f"🚨 {cat} {_TAMIL_ALERTS['budget exceeded']}"
        return translated

    # Budget almost used: "⚠️ food budget almost used (85.0%)"
    if "budget almost used" in translated.lower():
        clean = translated.replace("⚠️", "").strip()
        # extract pct from parentheses
        pct = ""
        if "(" in clean and ")" in clean:
            pct = clean[clean.rfind("(") + 1: clean.rfind(")")]
        parts = clean.split(" budget almost used")
        cat = parts[0].strip() if parts else ""
        translated = f"⚠️ {cat} {_TAMIL_ALERTS['budget almost used']} ({pct})"
        return translated

    # Goal at risk: "🎯 Goal 'Laptop' is at risk"
    if "is at risk" in translated:
        # keep goal name, translate surrounding text
        translated = translated.replace("Goal", _TAMIL_ALERTS["Goal"])
        translated = translated.replace("is at risk", _TAMIL_ALERTS["is at risk"])
        return translated

    # Financial health
    if "Financial health is low" in translated:
        score_part = ""
        if "(" in translated:
            score_part = translated[translated.rfind("("):]
        translated = f"📉 {_TAMIL_ALERTS['Financial health is low']} {score_part}"
        return translated

    # Behavior patterns — partial match
    for en_key, ta_val in _TAMIL_ALERTS.items():
        if en_key.lower() in translated.lower():
            translated = translated.replace(en_key, ta_val)

    return translated


# ==============================
# 🔥 HELPER: SIMILARITY CHECK
# ==============================
def is_similar(msg1, msg2):
    return msg1.lower().split()[:3] == msg2.lower().split()[:3]


# ==============================
# 🔥 MAIN ALERT ENGINE
# ==============================
def generate_alerts(user_id: str, language: str = "english"):
    alerts = []

    # ==============================
    # 💸 1. BUDGET ALERTS
    # ==============================
    try:
        budgets = get_budget_status(user_id)
        risks = predict_budget_risk(user_id)

        for b in budgets:
            usage = b.get("usage_percent", 0)
            if usage >= 100:
                alerts.append({
                    "type": "budget",
                    "message": f"🚨 {b['category'].capitalize()} budget exceeded",
                    "severity": "high"
                })
            elif usage >= 80:
                alerts.append({
                    "type": "budget",
                    "message": f"⚠️ {b['category']} budget almost used ({round(usage, 1)}%)",
                    "severity": "medium"
                })

        for r in risks:
            clean_risk = r.replace("⚠️", "").strip()
            alerts.append({
                "type": "budget_prediction",
                "message": f"⚠️ {clean_risk}",
                "severity": "high"
            })
    except:
        pass

    # ==============================
    # 🎯 2. GOAL ALERTS
    # ==============================
    try:
        goals = get_goals(user_id)
        for g in goals:
            if g.get("status") == "At Risk":
                alerts.append({
                    "type": "goal",
                    "message": f"🎯 Goal '{g['goal_name']}' is at risk",
                    "severity": "high"
                })
    except:
        pass

    # ==============================
    # 🧠 3. BEHAVIOR ALERTS
    # ==============================
    try:
        # Always fetch behavior in English here — we translate the final message below
        behavior = analyze_behavior(user_id, language="english")
        for p in behavior.get("patterns", []):
            if p["severity"] == "high":
                alerts.append({
                    "type": "behavior",
                    "message": f"⚠️ {p['pattern']}",
                    "severity": "medium"
                })
    except:
        pass

    # ==============================
    # 📉 4. FINANCIAL HEALTH ALERT
    # ==============================
    try:
        health = calculate_financial_health(user_id)
        if health.get("score", 100) < 50:
            alerts.append({
                "type": "health",
                "message": f"📉 Financial health is low ({health.get('score')})",
                "severity": "high"
            })
    except:
        pass

    # ==============================
    # 🔥 REMOVE DUPLICATES
    # ==============================
    filtered = []
    for alert in alerts:
        if not any(is_similar(alert["message"], f["message"]) for f in filtered):
            filtered.append(alert)
    alerts = filtered

    # ==============================
    # 🔥 PRIORITY SORT
    # ==============================
    priority = {"high": 1, "medium": 2, "low": 3}
    alerts.sort(key=lambda x: priority.get(x["severity"], 3))

    # ==============================
    # 🔥 LIMIT ALERTS (UX)
    # ==============================
    alerts = alerts[:4]

    # ==============================
    # 🔥 TRANSLATE IF TAMIL
    # ==============================
    if language == "tamil":
        alerts = [
            {**a, "message": _translate_message(a["message"], language)}
            for a in alerts
        ]

    return alerts
