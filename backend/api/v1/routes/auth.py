from fastapi import APIRouter, HTTPException, Header
from api.services.auth_service import get_google_oauth_url, get_current_user
from api.schemas.auth import OAuthResponse, UserResponse

router = APIRouter()

@router.get("/google", response_model=OAuthResponse)
def login_google():
    url = get_google_oauth_url("http://localhost:8000/auth/callback")
    return {"url": url}

@router.get("/callback")
def auth_callback(code: str = None):
    return {"message": "Login realizado com sucesso!"}

@router.get("/me", response_model=UserResponse)
def get_me(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    try:
        user = get_current_user(token)
        return user.user
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido")