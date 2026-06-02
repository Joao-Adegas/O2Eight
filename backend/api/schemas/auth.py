from pydantic import BaseModel

class OAuthResponse(BaseModel):
    url: str


class EmailSignupRequest(BaseModel):
    email: str
    password: str
    name: str | None = None


class EmailSignupResponse(BaseModel):
    message: str
    id: str
    email: str | None = None
    access_token: str | None = None
    refresh_token: str | None = None
    token_type: str | None = None
    expires_in: int | None = None
    needs_email_confirmation: bool

class UserResponse(BaseModel):
    id: str
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    created_at: str | None = None
