from app.services.user_service import get_user_profile
from app.services.budget_service import get_budget_health_score
from app.services.goal_service import get_goals


# ==============================
# 🔥 MAIN FUNCTION
# ==============================
def calculate_financial_health(user_id):
    profile = get_user_profile(user_id)

    if "message" in profile:
        return {"message": "User not found"}

    derived = profile.get("derived", {})

    income = derived.get("total_income", 0) or 0
    savings = profile.get("monthly_savings", 0) or 0
    emi = derived.get("total_emi", 0) or 0
    net_worth = derived.get("net_worth", 0) or 0

    score = 0

    # ==============================
    # 💰 1. SAVINGS SCORE (30)
    # ==============================
    savings_rate = 0
    if income > 0:
        savings_rate = (savings / income) * 100

    if savings_rate >= 30:
        score += 30
    elif savings_rate >= 20:
        score += 25
    elif savings_rate >= 10:
        score += 15
    else:
        score += 5

    # ==============================
    # 💳 2. DEBT SCORE (25)
    # ==============================
    debt_ratio = 0
    if income > 0:
        debt_ratio = (emi / income) * 100

    if debt_ratio < 20:
        score += 25
    elif debt_ratio < 40:
        score += 15
    else:
        score += 5

    # ==============================
    # 🏠 3. ASSET SCORE (20)
    # ==============================
    if net_worth > 0:
        if income > 0 and net_worth > income * 6:
            score += 20
        else:
            score += 15
    else:
        score += 5

    # ==============================
    # 📊 4. BUDGET SCORE (15) 🔥 FIXED
    # ==============================
    try:
        budget = get_budget_health_score(user_id)
        budget_score = budget.get("score", 50)  # default mid value

        # 🔥 Normalize (0–100 → 0–15)
        score += (budget_score / 100) * 15
    except:
        score += 10

    # ==============================
    # 🎯 5. GOAL SCORE (10)
    # ==============================
    try:
        goals = get_goals(user_id)

        if not goals:
            score += 5
        else:
            on_track = sum(1 for g in goals if g["status"] == "On Track")
            score += min(on_track * 5, 10)
    except:
        score += 5

    # ==============================
    # 🔥 FINAL NORMALIZATION
    # ==============================
    score = round(min(score, 100))  # never exceed 100

    # ==============================
    # 🧠 FINAL LABEL
    # ==============================
    if score >= 80:
        status = "Excellent"
    elif score >= 60:
        status = "Good"
    elif score >= 40:
        status = "Average"
    else:
        status = "Poor"

    return {
        "score": score,
        "status": status,
        "breakdown": {
            "savings_rate": round(savings_rate, 2),
            "debt_ratio": round(debt_ratio, 2),
            "net_worth": net_worth
        }
    }