from app.services.user_service import get_user_profile
from app.services.budget_service import get_budget_status, predict_budget_risk
from app.services.goal_service import get_goals
from app.services.behavior_service import analyze_behavior
from app.services.financial_health_service import calculate_financial_health


def build_context(user_id):
    context = []

    # ==============================
    # 🔥 FETCH DATA
    # ==============================
    try:
        profile = get_user_profile(user_id)
        derived = profile.get("derived", {})
    except:
        profile, derived = {}, {}

    try:
        budgets = get_budget_status(user_id)
        risks = predict_budget_risk(user_id)
    except:
        budgets, risks = [], []

    try:
        goals = get_goals(user_id)
    except:
        goals = []

    try:
        behavior = analyze_behavior(user_id)
    except:
        behavior = {"patterns": []}

    try:
        health = calculate_financial_health(user_id)
    except:
        health = {}

    # ==============================
    # 🧠 1. PROFILE SUMMARY
    # ==============================
    income = derived.get("total_income", 0)
    savings = profile.get("monthly_savings", 0)
    emi = derived.get("total_emi", 0)

    context.append(f"Income ₹{income}, Savings ₹{savings}, EMI ₹{emi}")

    # ==============================
    # 🔥 2. CRITICAL RISKS (TOP PRIORITY)
    # ==============================
    for r in risks:
        context.append(f"CRITICAL: {r}")

    for b in budgets:
        if b.get("usage_percent", 0) > 90:
            context.append(f"CRITICAL: Overspending in {b['category']}")

    for g in goals:
        if g.get("status") == "At Risk":
            context.append(f"CRITICAL: Goal '{g['goal_name']}' at risk")

    # ==============================
    # ⚠️ 3. BEHAVIOR ISSUES
    # ==============================
    for p in behavior.get("patterns", []):
        if p["severity"] == "high":
            context.append(f"WARNING: {p['pattern']}")
        elif p["severity"] == "medium":
            context.append(f"NOTICE: {p['pattern']}")

    # ==============================
    # 📊 4. FINANCIAL HEALTH
    # ==============================
    if health:
        context.append(
            f"Health: {health.get('status')} ({health.get('score')})"
        )

    # ==============================
    # 🎯 5. GOAL STATUS
    # ==============================
    for g in goals:
        if g.get("status") == "On Track":
            context.append(f"GOOD: Goal '{g['goal_name']}' on track")

    # ==============================
    # 🔥 6. CONFLICT DETECTION (NEW)
    # ==============================
    try:
        expense_ratio = 0
        if income > 0:
            expense_ratio = sum(
                [b.get("spent", 0) for b in budgets]
            ) / income

        if savings > 0 and expense_ratio > 0.8:
            context.append(
                "CONFLICT: Good savings but high spending risk"
            )

    except:
        pass

    # ==============================
    # 🔥 7. DECISION HINTS (NEW)
    # ==============================
    try:
        if risks:
            context.append(
                "ACTION: Reduce spending immediately in high-risk categories"
            )

        risky_goals = [g for g in goals if g.get("status") == "At Risk"]

        if risky_goals:
            context.append(
                "ACTION: Increase savings to protect financial goals"
            )

    except:
        pass

    # ==============================
    # 🧹 CLEAN + LIMIT
    # ==============================
    context = list(dict.fromkeys(context))  # remove duplicates

    # PRIORITY SORT
    def priority(x):
        if x.startswith("CRITICAL"):
            return 1
        if x.startswith("WARNING"):
            return 2
        if x.startswith("CONFLICT"):
            return 3
        if x.startswith("ACTION"):
            return 4
        return 5

    context.sort(key=priority)

    return context[:12]