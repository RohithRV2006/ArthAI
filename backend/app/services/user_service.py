from app.config.db import user_col, summary_col
from datetime import datetime

# ==============================
# 🧹 CLEAN DATA (REMOVE NONE)
# ==============================
def clean_data(data: dict):
    if isinstance(data, dict):
        return {k: clean_data(v) for k, v in data.items() if v is not None}
    elif isinstance(data, list):
        return [clean_data(i) for i in data]
    else:
        return data

# ==============================
# 🧮 CALCULATIONS
# ==============================
def calculate_household_income(user):
    income_sources = user.get("income_sources", [])
    members = user.get("members", [])
    total_income = sum(i.get("amount", 0) for i in income_sources)
    if total_income == 0:
        total_income = sum(m.get("monthly_income", 0) for m in members)
    return total_income

def calculate_net_worth(user):
    assets = user.get("assets", [])
    liabilities = user.get("liabilities", [])
    total_assets = sum(a.get("value", 0) for a in assets)
    total_liabilities = sum(l.get("outstanding_amount", 0) for l in liabilities)
    return total_assets - total_liabilities

def calculate_total_emi(user):
    liabilities = user.get("liabilities", [])
    return sum(l.get("monthly_payment", 0) for l in liabilities)

# ==============================
# 👤 CREATE / UPDATE PROFILE
# ==============================
def create_or_update_user(data):
    cleaned_data = clean_data(data)

    total_income = calculate_household_income(cleaned_data)
    savings_list = cleaned_data.get("savings", [])
    total_savings = sum(s.get("amount", 0) for s in savings_list)

    cleaned_data["monthly_income"] = total_income
    cleaned_data["monthly_savings"] = total_savings

    # 1. Save the clean data to the Users collection
    user_col.replace_one(
        {"user_id": cleaned_data["user_id"]},
        cleaned_data,
        upsert=True
    )

    # 2. 🔥 THE FIX: Instantly overwrite the old data in the Summary collection!
    summary_col.update_one(
        {"user_id": cleaned_data["user_id"]},
        {"$set": {
            "monthly.income": total_income,
            "user_id": cleaned_data["user_id"],
            "last_updated": str(datetime.today())
        }},
        upsert=True
    )

    return {"message": "User profile saved successfully"}

# ==============================
# 📥 GET USER PROFILE 
# ==============================
def get_user_profile(user_id):
    user = user_col.find_one({"user_id": user_id}, {"_id": 0})

    if not user:
        return {"message": "User not found"}

    total_income = calculate_household_income(user) or 0
    net_worth = calculate_net_worth(user)
    total_emi = calculate_total_emi(user)

    savings_list = user.get("savings", [])
    total_savings = sum(s.get("amount", 0) for s in savings_list)
    
    savings_rate = 0
    if total_income > 0:
        savings_rate = round((total_savings / total_income) * 100, 2)

    return {
        **user,
        "derived": {
            "total_income": total_income,
            "net_worth": net_worth,
            "total_emi": total_emi,
            "savings_rate": savings_rate
        }
    }
