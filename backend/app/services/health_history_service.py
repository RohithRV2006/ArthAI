from app.config.db import health_col
from datetime import datetime
from app.services.financial_health_service import calculate_financial_health


# ==============================
# 💾 SAVE SCORE SNAPSHOT
# ==============================
def save_health_snapshot(user_id):
    health = calculate_financial_health(user_id)

    if "score" not in health:
        return

    health_col.insert_one({
        "user_id": user_id,
        "score": health["score"],
        "status": health["status"],
        "date": datetime.now()
    })


# ==============================
# 📈 GET SCORE HISTORY
# ==============================
def get_health_history(user_id):
    records = list(
        health_col.find(
            {"user_id": user_id},
            {"_id": 0}
        ).sort("date", 1)
    )

    return records