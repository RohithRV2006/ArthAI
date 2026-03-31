from app.config.db import transactions_col
from app.utils.category_mapper import normalize_category
from datetime import datetime


def add_transaction(user_id, intent, data):
    # 🔹 Extract values safely
    amount = data.get("amount", 0)
    raw_category = data.get("category", "others")

    # 🔹 Normalize category (but don't lose original)
    normalized_category = normalize_category(raw_category)

    # 🔥 ALWAYS use current date (fixes 2023 issue)
    today = datetime.utcnow()

    transaction = {
        "user_id": user_id,
        "type": intent,
        "amount": amount,

        # 🔥 Store BOTH (important for future AI improvements)
        "category": normalized_category,
        "raw_category": raw_category,

        "date": today,  # ✅ force correct date

        "created_at": datetime.utcnow()  # 🔥 for sorting/history
    }

    result = transactions_col.insert_one(transaction)

    return str(result.inserted_id)