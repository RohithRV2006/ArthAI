from app.config.db import budgets_col, transactions_col
from datetime import datetime
import calendar


# ==============================
# 🧠 HELPER FUNCTIONS
# ==============================
def get_current_month():
    return datetime.today().strftime("%Y-%m")


def get_days_info():
    today = datetime.today()
    days_passed = today.day
    total_days = calendar.monthrange(today.year, today.month)[1]
    return days_passed, total_days


# ==============================
# ✅ 1. SET / UPDATE BUDGET
# ==============================
def set_budget(user_id, category, limit):
    current_month = get_current_month()

    budgets_col.update_one(
        {
            "user_id": user_id,
            "category": category,
            "month": current_month
        },
        {
            "$set": {
                "limit": limit,
                "month": current_month,
                "updated_at": datetime.utcnow()
            }
        },
        upsert=True
    )

    return {
        "message": f"Budget set for {category} ({current_month})",
        "limit": limit
    }


# ==============================
# ✅ 2. GET BUDGETS
# ==============================
def get_budgets(user_id):
    current_month = get_current_month()

    return list(
        budgets_col.find(
            {"user_id": user_id, "month": current_month},
            {"_id": 0}
        )
    )


# ==============================
# 🔥 HELPER: MONTHLY SPENDING
# ==============================
def get_monthly_spent(user_id, category):
    current_month = get_current_month()

    pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "category": category,
                "date": {"$regex": f"^{current_month}"}
            }
        },
        {
            "$group": {
                "_id": None,
                "total": {"$sum": "$amount"}
            }
        }
    ]

    result = list(transactions_col.aggregate(pipeline))
    return result[0]["total"] if result else 0


# ==============================
# 🔥 3. CHECK BUDGET (ENHANCED)
# ==============================
def check_budget(user_id, category, current_amount):
    current_month = get_current_month()

    budget = budgets_col.find_one({
        "user_id": user_id,
        "category": category,
        "month": current_month
    })

    if not budget:
        return None

    limit = budget["limit"]
    total_spent = get_monthly_spent(user_id, category)

    percent = (total_spent / limit) * 100 if limit > 0 else 0

    # 🔥 Alerts
    if percent >= 100:
        return f"🚨 Budget exceeded for {category} (₹{total_spent}/{limit})"
    elif percent >= 80:
        return f"⚠️ Near budget limit for {category} ({round(percent, 1)}%)"
    elif percent >= 50:
        return f"🔔 You've used {round(percent, 1)}% of your {category} budget"

    return None


# ==============================
# 📊 4. BUDGET STATUS (WITH BURN RATE)
# ==============================
def get_budget_status(user_id):
    current_month = get_current_month()
    days_passed, total_days = get_days_info()

    budgets = list(
        budgets_col.find(
            {"user_id": user_id, "month": current_month}
        )
    )

    response = []

    for b in budgets:
        category = b["category"]
        limit = b["limit"]

        spent = get_monthly_spent(user_id, category)

        percent = (spent / limit) * 100 if limit > 0 else 0

        # 🔥 Burn Rate
        daily_avg = spent / days_passed if days_passed > 0 else 0

        # 🔥 Prediction
        predicted_total = round(daily_avg * total_days, 2)

        response.append({
            "category": category,
            "month": current_month,
            "limit": limit,
            "spent": spent,
            "remaining": max(limit - spent, 0),
            "usage_percent": round(percent, 2),

            # 🔥 NEW FEATURES
            "daily_avg_spend": round(daily_avg, 2),
            "predicted_month_end": predicted_total,
            "will_exceed": predicted_total > limit
        })

    return response


# ==============================
# 🤖 5. SMART BUDGET SUGGESTION
# ==============================
def suggest_budget(user_id):
    current_month = get_current_month()

    pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "date": {"$regex": f"^{current_month}"}
            }
        },
        {
            "$group": {
                "_id": "$category",
                "avg_spend": {"$avg": "$amount"},
                "total_spend": {"$sum": "$amount"}
            }
        }
    ]

    results = list(transactions_col.aggregate(pipeline))

    suggestions = []

    for r in results:
        category = r["_id"]
        avg = r["avg_spend"]

        suggested = round(avg * 1.2, 2)

        suggestions.append({
            "category": category,
            "month": current_month,
            "avg_spend": round(avg, 2),
            "suggested_budget": suggested
        })

    return suggestions


# ==============================
# 🔥 6. PREDICTION ALERT ENGINE
# ==============================
def predict_budget_risk(user_id):
    status = get_budget_status(user_id)

    alerts = []

    for item in status:
        if item["will_exceed"]:
            alerts.append(
                f"⚠️ {item['category']} may exceed budget. "
                f"Expected ₹{item['predicted_month_end']} vs limit ₹{item['limit']}"
            )

    return alerts

# ==============================
# 🧠 7. BUDGET HEALTH SCORE
# ==============================
def get_budget_health_score(user_id):
    status = get_budget_status(user_id)

    if not status:
        return {
            "score": 100,
            "status": "No data",
            "message": "Start tracking expenses to get insights"
        }

    total_score = 0
    count = len(status)

    messages = []

    for item in status:
        percent = item["usage_percent"]
        predicted = item["predicted_month_end"]
        limit = item["limit"]

        # 🔹 Usage scoring
        if percent <= 70:
            score = 100
        elif percent <= 100:
            score = 70
        else:
            score = 40

        # 🔹 Prediction penalty
        if predicted > limit:
            score -= 20
            messages.append(
                f"{item['category']} may exceed budget"
            )

        total_score += score

    final_score = round(total_score / count)

    # 🔹 Overall status
    if final_score >= 80:
        status_label = "Excellent"
    elif final_score >= 60:
        status_label = "Good"
    elif final_score >= 40:
        status_label = "Risky"
    else:
        status_label = "Critical"

    return {
        "score": final_score,
        "status": status_label,
        "warnings": messages
    }