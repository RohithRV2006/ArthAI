from app.services.budget_service import get_budget_status
from app.services.goal_service import get_goals
from app.services.ai_service import get_llm_response
from app.services.user_service import get_user_profile


# ==============================
# 🔥 MAIN RECOMMENDATION ENGINE
# ==============================
def generate_recommendations(user_id):
    recommendations = []

    try:
        budgets = get_budget_status(user_id)
    except:
        budgets = []

    try:
        goals = get_goals(user_id)
    except:
        goals = []

    try:
        profile = get_user_profile(user_id)
        derived = profile.get("derived", {})
        income = derived.get("total_income", 0)
        emi = derived.get("total_emi", 0)
    except:
        income, emi = 0, 0

    # ==============================
    # 📊 1. BUDGET BASED
    # ==============================
    for b in budgets:
        if b.get("usage_percent", 0) >= 80:
            excess = b.get("predicted_month_end", 0) - b.get("limit", 0)

            if excess > 0:
                reduce_per_day = round(excess / 30, 2)

                recommendations.append({
                    "priority": 1,
                    "message": f"Reduce {b['category']} spending by ₹{reduce_per_day}/day to stay within budget"
                })

    # ==============================
    # 🎯 2. GOAL BASED
    # ==============================
    for g in goals:
        if g.get("status") == "At Risk":
            recommendations.append({
                "priority": 1,
                "message": f"Increase savings by ₹{round(g.get('monthly_required', 0), 2)} per month to achieve '{g.get('goal_name')}' on time"
            })

    # ==============================
    # 💳 3. EMI / DEBT AWARENESS (NEW 🔥)
    # ==============================
    if income > 0:
        debt_ratio = emi / income

        if debt_ratio > 0.4:
            recommendations.append({
                "priority": 1,
                "message": "Your EMI is high compared to income. Consider reducing debt or restructuring loans"
            })
        elif debt_ratio > 0.25:
            recommendations.append({
                "priority": 2,
                "message": "Your EMI is moderate. Try avoiding new loans to maintain financial stability"
            })

    # ==============================
    # 🔥 4. COMBINED (SMART)
    # ==============================
    for b in budgets:
        if b.get("will_exceed"):
            for g in goals:
                if g.get("status") != "Completed":
                    recommendations.append({
                        "priority": 1,
                        "message": f"Overspending on {b['category']} may delay your goal '{g.get('goal_name')}'. Try reducing expenses"
                    })

    # ==============================
    # 🧹 5. REMOVE DUPLICATES
    # ==============================
    unique = {}
    for r in recommendations:
        unique[r["message"]] = r

    recommendations = list(unique.values())

    # ==============================
    # 🔝 6. SORT BY PRIORITY
    # ==============================
    recommendations.sort(key=lambda x: x["priority"])

    # ==============================
    # 🧠 FINAL OUTPUT (ONLY TEXT)
    # ==============================
    final_recommendations = [r["message"] for r in recommendations]

    # ==============================
    # 🧠 FALLBACK
    # ==============================
    if not final_recommendations:
        final_recommendations.append(
            "Your finances look good. Keep maintaining your current spending habits 👍"
        )

    return final_recommendations


# ==============================
# 🤖 AI EXPLANATION LAYER
# ==============================
def explain_recommendations(user_id, recommendations):
    if not recommendations:
        return ""

    rec_text = "\n".join(recommendations)

    prompt = f"""
You are a smart financial advisor.

User Recommendations:
{rec_text}

Instructions:
- Convert these into natural, friendly advice
- Keep it short (2-4 lines total)
- Use ₹ symbol if needed
- Make it motivating and practical
- Do NOT repeat raw bullet points
- Combine related suggestions into a smooth explanation

Example:
Input:
"Reduce food spending by ₹100/day"

Output:
"You're spending a bit more on food. Cutting around ₹100 daily can help you stay within budget and improve your savings."
"""

    response = get_llm_response(prompt)

    return response