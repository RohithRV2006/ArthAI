from app.config.db import db

def save_financial_data(user_id, intent, data):
    record = {
        "user_id": user_id,
        "type": intent,
        "data": data
    }

    result = db.finances.insert_one(record)

    return {
        "message": f"{intent} stored successfully",
        "id": str(result.inserted_id)
    }