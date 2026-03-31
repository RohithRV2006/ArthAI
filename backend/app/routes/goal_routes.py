from fastapi import APIRouter
from app.schemas.goal_schema import GoalCreate, GoalAddMoney
from app.services.goal_service import (
    create_goal,
    add_money_to_goal,
    get_goals,
    get_goal_alerts
)

router = APIRouter(prefix="/goal", tags=["Goal"])


# ✅ CREATE GOAL
@router.post("/create")
def create(data: GoalCreate):
    return create_goal(
        data.user_id,
        data.goal_name,
        data.target_amount,
        data.deadline
    )


# 💰 ADD MONEY
@router.post("/add")
def add_money(data: GoalAddMoney):
    return add_money_to_goal(
        data.user_id,
        data.goal_name,
        data.amount
    )


# 📊 GET GOALS
@router.get("/{user_id}")
def get(user_id: str):
    return get_goals(user_id)


# 🚨 ALERTS
@router.get("/alerts/{user_id}")
def alerts(user_id: str):
    return get_goal_alerts(user_id)