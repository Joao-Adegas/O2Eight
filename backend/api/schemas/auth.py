# api/schemas/auth.py
from pydantic import BaseModel, Field


class OAuthResponse(BaseModel):
    url: str


class UserResponse(BaseModel):
    id: str
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    created_at: str | None = None

    # Termo de consentimento
    terms_version: str | None = None  # versão aceita pelo usuário (None = nunca aceitou)
    terms_accepted_at: str | None = None
    terms_current_version: str  # versão em vigor no app
    terms_up_to_date: bool  # True quando a versão aceita é a versão em vigor


class ConsentRequest(BaseModel):
    version: str = Field(min_length=1, max_length=20)