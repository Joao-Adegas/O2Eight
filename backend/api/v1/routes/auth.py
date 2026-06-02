from fastapi import APIRouter, HTTPException, Header
from api.services.auth_service import (
    get_google_oauth_url,
    get_current_user,
    register_sso_user,
    register_email_user,
    exchange_callback_code_for_session,
)
from api.schemas.auth import EmailSignupRequest, EmailSignupResponse, OAuthResponse, UserResponse

# link test route: http://localhost:8000/auth/google

router = APIRouter()

@router.get("/google", response_model=OAuthResponse)
def login_google():
    url = get_google_oauth_url("http://localhost:8000/auth/callback")
    return {"url": url}

@router.get("/callback")
def auth_callback(code: str = None):
    if not code:
        raise HTTPException(status_code=400, detail="Parâmetro 'code' é obrigatório no callback")

    try:
        session_data = exchange_callback_code_for_session(code)
        return {
            "message": "Login realizado com sucesso! Use o access_token para /auth/register-sso.",
            **session_data,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha no callback OAuth: {str(exc)}")

@router.get("/me", response_model=UserResponse)
def get_me(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)
    try:
        user = get_current_user(token)
        return user
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido")


@router.post("/register-sso", response_model=UserResponse)
def register_user_with_sso(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)
    try:
        user = register_sso_user(token)
        return user
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Não foi possível cadastrar/sincronizar o usuário SSO: {str(exc)}",
        )


@router.post("/register-email", response_model=EmailSignupResponse)
def register_user_with_email(payload: EmailSignupRequest):
    try:
        return register_email_user(
            email=payload.email,
            password=payload.password,
            name=payload.name,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Não foi possível cadastrar usuário com email/senha: {str(exc)}",
        )