from pydantic import BaseModel
from typing import Optional

class User(BaseModel):
    id: str
    email: Optional[str] = None
    phone: Optional[str] = None
    created_at: Optional[str] = None