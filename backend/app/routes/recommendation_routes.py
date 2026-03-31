from fastapi import APIRouter
from app.services.recommendation_service import generate_recommendations

router = APIRouter(prefix="/recommend", tags=["Recommendation"])


@router.get("/{user_id}")
def get_recommendations(user_id: str):
    return {
        "recommendations": generate_recommendations(user_id)
    }