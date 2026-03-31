from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ChatMessage(BaseModel):
    user_id: str

    role: str  # "user" | "assistant"

    message: str

    intent: Optional[str] = None  # expense / income / query / other

    chat_id: Optional[str] = None        # group conversations

    linked_transaction_ids: Optional[List[str]] = []

    metadata: Optional[dict] = {}  # extracted info if needed

    created_at: datetime = Field(default_factory=datetime.utcnow)