from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ==============================
# 📥 INPUT
# ==============================
class BudgetCreate(BaseModel):
    user_id: str
    category: str
    limit: float


# ==============================
# 🧠 DATABASE
# ==============================
class Budget(BaseModel):
    user_id: str
    category: str

    limit: float
    spent: Optional[float] = 0

    period: str = "monthly"

    alert_threshold: Optional[float] = 0.8

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


# ==============================
# 📤 RESPONSE (OPTIONAL)
# ==============================
class BudgetResponse(BaseModel):
    category: str
    limit: float
    spent: float
    remaining: float