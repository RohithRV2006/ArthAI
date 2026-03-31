from app.config.db import db
from datetime import datetime

memory_col = db["memory"]


def save_memory(user_id, text, intent):
    memory = {
        "user_id": user_id,
        "text": text,
        "intent": intent,
        "created_at": datetime.utcnow()
    }
    memory_col.insert_one(memory)


def get_recent_memory(user_id, limit=5):
    memories = list(
        memory_col.find({"user_id": user_id})
        .sort("created_at", -1)
        .limit(limit * 2)
    )

    # 🔥 FILTER ONLY IMPORTANT
    filtered = [
        m["text"]
        for m in memories
        if m["intent"] in ["habit", "query"]
    ]

    return filtered[:limit]