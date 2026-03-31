from pydantic import BaseModel
from typing import Optional

class UserInput(BaseModel):
    text: str
    user_id: str
    language: Optional[str] = "english"