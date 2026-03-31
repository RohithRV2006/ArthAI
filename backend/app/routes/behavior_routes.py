from fastapi import APIRouter
from app.services.behavior_service import analyze_behavior
 
router = APIRouter(prefix="/behavior", tags=["Behavior"])
 
@router.get("/{user_id}")
def get_behavior(user_id: str, language: str = "english"):   # 🔥 added language
    return analyze_behavior(user_id, language=language)
