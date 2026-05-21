from pydantic import BaseModel

class OAuthResponse(BaseModel):
    url: str

class UserResponse(BaseModel):
    id: str
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    created_at: str | None = None
    daily_cigarette_consumption: int | None = None
    pack_price: float | None = None
    preferred_ai_tone: str | None = None