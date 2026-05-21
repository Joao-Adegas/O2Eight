from pydantic import BaseModel

class OAuthResponse(BaseModel):
    url: str

class UserResponse(BaseModel):
    id: str
    email: str | None = None