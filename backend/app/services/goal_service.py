from app.config.db import goals_col
from datetime import datetime
import math


# ==============================
# 🧠 HELPER: MONTH DIFFERENCE
# ==============================
def months_between(deadline):
    today = datetime.today()
    current_month = today.year * 12 + today.month

    try:
        year, month = map(int, deadline.split("-"))
        target_month = year * 12 + month
    except:
        return 1

    return max(target_month - current_month, 1)


# ==============================
# ✅ CREATE GOAL
# ==============================
def create_goal(user_id, goal_name, target_amount, deadline):
    goal = {
        "user_id": user_id,
        "goal_name": goal_name,
        "target_amount": target_amount,
        "saved_amount": 0,   # 🔥 NEW
        "deadline": deadline,
        "created_at": datetime.utcnow()
    }

    goals_col.insert_one(goal)

    return {"message": f"Goal '{goal_name}' created"}


# ==============================
# 💰 ADD MONEY TO GOAL
# ==============================
def add_money_to_goal(user_id, goal_name, amount):
    goal = goals_col.find_one({
        "user_id": user_id,
        "goal_name": goal_name
    })

    if not goal:
        return {"error": "Goal not found"}

    goals_col.update_one(
        {"user_id": user_id, "goal_name": goal_name},
        {"$inc": {"saved_amount": amount}}
    )

    return {"message": f"₹{amount} added to {goal_name}"}


# ==============================
# 📊 GET GOALS WITH PROGRESS
# ==============================
def get_goals(user_id):
    goals = list(goals_col.find({"user_id": user_id}, {"_id": 0}))

    response = []

    for g in goals:
        target = g["target_amount"]
        saved = g.get("saved_amount", 0)
        deadline = g["deadline"]

        remaining = max(target - saved, 0)
        progress = (saved / target) * 100 if target > 0 else 0

        months_left = months_between(deadline)

        monthly_required = remaining / months_left if months_left > 0 else remaining

        # 🔥 Prediction
        if saved > 0:
            predicted_months = math.ceil(remaining / (saved / max(months_left, 1)))
        else:
            predicted_months = None

        # 🔥 Status
        if saved >= target:
            status = "Completed"
        elif predicted_months and predicted_months > months_left:
            status = "At Risk"
        else:
            status = "On Track"

        response.append({
            "goal_name": g["goal_name"],
            "target_amount": target,
            "saved_amount": saved,
            "remaining_amount": remaining,
            "progress_percent": round(progress, 2),
            "deadline": deadline,
            "monthly_required": round(monthly_required, 2),
            "predicted_months": predicted_months,
            "status": status
        })

    return response


# ==============================
# 🚨 GOAL ALERTS
# ==============================
def get_goal_alerts(user_id):
    goals = get_goals(user_id)

    alerts = []

    for g in goals:
        if g["status"] == "At Risk":
            alerts.append(f"⚠️ {g['goal_name']} is at risk")
        elif g["status"] == "Completed":
            alerts.append(f"🎉 {g['goal_name']} completed!")

    return alerts