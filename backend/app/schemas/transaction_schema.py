from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class Transaction(BaseModel):
    user_id: str

    type: str  # "income" | "expense" | "transfer"

    amount: float

    category: str  # food / rent / salary / travel

    subcategory: Optional[str] = ""

    owner_id: Optional[str] = None  # link to FamilyMember

    payment_method: Optional[str] = ""  # cash / upi / card

    date: datetime = Field(default_factory=datetime.utcnow)

    notes: Optional[str] = ""

    source: Optional[str] = "manual"  # manual / voice / ai

    tags: Optional[List[str]] = []

    created_at: datetime = Field(default_factory=datetime.utcnow)

    confidence_score: Optional[float] = 1.0   # AI confidence (0–1)
    is_verified: Optional[bool] = False       # user confirmed/corrected
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)