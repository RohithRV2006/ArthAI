from fastapi import APIRouter
from app.services.alert_service import generate_alerts
 
router = APIRouter(prefix="/alerts", tags=["Alerts"])
 
@router.get("/{user_id}")
def get_alerts(user_id: str, language: str = "english"):     # 🔥 added language
    return generate_alerts(user_id, language=language)
