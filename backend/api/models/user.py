from pydantic import BaseModel
from typing import Optional


class User(BaseModel):
    # SSO fields from Supabase Auth
    id: str
    email: Optional[str] = None
    phone: Optional[str] = None

    # Profile fields stored in public.users
    name: Optional[str] = None
    created_at: Optional[str] = None
    daily_cigarette_consumption: Optional[int] = None
    pack_price: Optional[float] = None
    preferred_ai_tone: Optional[str] = None