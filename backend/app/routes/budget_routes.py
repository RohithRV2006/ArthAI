from fastapi import APIRouter
from app.schemas.budget_schema import BudgetCreate
from app.services.budget_service import (
    set_budget,
    get_budgets,
    get_budget_status,
    suggest_budget,
    get_budget_health_score
)

router = APIRouter(prefix="/budget", tags=["Budget"])

# ✅ Set budget
@router.post("/set")
def create_budget(data: BudgetCreate):
    return set_budget(data.user_id, data.category, data.limit)

# ✅ Get all budgets
@router.get("/{user_id}")
def fetch_budgets(user_id: str):
    return get_budgets(user_id)

# 🔥 Smart suggestion
@router.get("/suggest/{user_id}")
def get_suggestions(user_id: str):
    return suggest_budget(user_id)

@router.get("/status/{user_id}")
def budget_status(user_id: str):
    return get_budget_status(user_id)

@router.get("/health/{user_id}")
def budget_health(user_id: str):
    return get_budget_health_score(user_id)