from pydantic import BaseModel

class OAuthResponse(BaseModel):
    url: str

class UserResponse(BaseModel):
    id: str
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    created_at: str | None = None
