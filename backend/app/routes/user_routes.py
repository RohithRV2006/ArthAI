from fastapi import APIRouter
from app.schemas.user_schema import UserProfile
from app.services.user_service import (
    create_or_update_user,
    get_user_profile
)

router = APIRouter(prefix="/user", tags=["User"])


# 🔹 Save profile
@router.post("/save")
def save_user(data: UserProfile):
    return create_or_update_user(data.dict())


# 🔹 Get profile
@router.get("/{user_id}")
def get_user(user_id: str):
    return get_user_profile(user_id)