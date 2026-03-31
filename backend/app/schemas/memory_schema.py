from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class Memory(BaseModel):
    user_id: str

    type: str  # "pattern" | "preference" | "insight" | "risk"

    content: str  # human-readable insight

    confidence: Optional[float] = 0.5  # 0 to 1

    tags: Optional[List[str]] = []

    entities: Optional[dict] = {}

    importance: Optional[int] = 3   # 1–5 priority

    source: Optional[str] = "ai"  # ai / system

    last_updated: datetime = Field(default_factory=datetime.utcnow)