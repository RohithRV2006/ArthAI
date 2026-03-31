from fastapi import APIRouter
from app.services.financial_health_service import calculate_financial_health
from app.services.health_history_service import (
    save_health_snapshot,
    get_health_history
)

router = APIRouter(prefix="/health", tags=["Financial Health"])


@router.get("/{user_id}")
def get_health(user_id: str):
    return calculate_financial_health(user_id)

@router.post("/track/{user_id}")
def track_health(user_id: str):
    save_health_snapshot(user_id)
    return {"message": "Health snapshot saved"}

@router.get("/history/{user_id}")
def health_history(user_id: str):
    return get_health_history(user_id)