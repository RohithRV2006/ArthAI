from app.config.db import summary_col
from datetime import datetime
from app.services.user_service import get_user_profile


def update_summary(user_id, intent, amount, category):
    summary = summary_col.find_one({"user_id": user_id})

    # ==============================
    # 🆕 CREATE IF NOT EXISTS
    # ==============================
    if not summary:
        summary = {
            "user_id": user_id,
            "monthly": {},
            "category_breakdown": {},
            "last_updated": str(datetime.today())
        }

    # ==============================
    # 🔥 ENSURE STRUCTURE (CRITICAL FIX)
    # ==============================
    summary.setdefault("monthly", {})
    summary["monthly"].setdefault("income", 0)
    summary["monthly"].setdefault("expense", 0)
    summary["monthly"].setdefault("savings", 0)

    summary.setdefault("category_breakdown", {})

    # ==============================
    # 💰 HANDLE INCOME
    # ==============================
    if intent == "income":
        summary["monthly"]["income"] += amount

    # ==============================
    # 💸 HANDLE EXPENSE
    # ==============================
    elif intent == "expense":
        summary["monthly"]["expense"] += amount

        # Category breakdown
        summary["category_breakdown"][category] = (
            summary["category_breakdown"].get(category, 0) + amount
        )

    # ==============================
    # 🔥 GET ACTUAL INCOME FROM PROFILE
    # ==============================
    try:
        profile = get_user_profile(user_id)
        actual_income = profile.get("derived", {}).get("total_income", 0)
    except:
        actual_income = summary["monthly"].get("income", 0)

    expense = summary["monthly"].get("expense", 0)

    # Override income if available
    if actual_income > 0:
        summary["monthly"]["income"] = actual_income

    # ==============================
    # 💡 RECALCULATE SAVINGS
    # ==============================
    summary["monthly"]["savings"] = (
        summary["monthly"]["income"] - expense
    )

    summary["last_updated"] = str(datetime.today())

    # ==============================
    # 💾 SAVE
    # ==============================
    summary_col.update_one(
        {"user_id": user_id},
        {"$set": summary},
        upsert=True
    )