from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ==============================
# 🎯 CREATE GOAL (API INPUT)
# ==============================
class GoalCreate(BaseModel):
    user_id: str
    goal_name: str = Field(..., example="Buy Laptop")
    target_amount: float = Field(..., gt=0)
    deadline: str = Field(..., example="2026-12")


# ==============================
# 💰 ADD SAVINGS (API INPUT)
# ==============================
class GoalAddMoney(BaseModel):
    user_id: str
    goal_name: str
    amount: float = Field(..., gt=0)


# ==============================
# 🧠 GOAL (DB MODEL) ⭐ NEW
# ==============================
class Goal(BaseModel):
    user_id: str

    goal_id: Optional[str] = None  # optional unique id

    goal_name: str

    target_amount: float
    saved_amount: float = 0

    deadline: str  # format: YYYY-MM

    # Optional intelligence fields
    category: Optional[str] = ""        # travel / education / etc.
    priority: Optional[str] = "medium"  # low / medium / high

    status: Optional[str] = "active"    # active / completed / paused

    # Future-ready fields
    monthly_target: Optional[float] = 0
    auto_save_enabled: Optional[bool] = False

    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


# ==============================
# 📊 RESPONSE (API OUTPUT)
# ==============================
class GoalResponse(BaseModel):
    goal_name: str
    target_amount: float
    saved_amount: float
    remaining_amount: float
    progress_percent: float
    deadline: str
    monthly_required: float
    predicted_months: Optional[int]
    status: str