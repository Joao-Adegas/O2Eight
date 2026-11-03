# api/v1/routes/auth.py
from datetime import datetime, timezone

from fastapi import APIRouter, Header, HTTPException

from api.core.supabase import supabase, supabase_admin
from api.schemas.auth import ConsentRequest, UserResponse

router = APIRouter()

# Versão do termo de consentimento em vigor.
# Ao mudar o texto do termo no app, aumente esta versão (ex: "1.1") e a do
# Flutter (ConsentScreen.termsVersion): todos os usuários verão o termo de novo.
CURRENT_TERMS_VERSION = "1.0"


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


def _get_auth_user(token: str):
    """Valida o token no Supabase Auth e devolve o usuario (id, email, metadata do Google)."""
    try:
        result = supabase.auth.get_user(token)
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Token invalido ou expirado: {exc}")
    if not result or not result.user:
        raise HTTPException(status_code=401, detail="Token invalido ou expirado")
    return result.user


def _find_profile(user_id: str) -> dict | None:
    res = supabase_admin.table("users").select("*").eq("id", user_id).limit(1).execute()
    return res.data[0] if res.data else None


def _to_response(auth_user, profile: dict) -> UserResponse:
    accepted_version = profile.get("terms_version")
    return UserResponse(
        id=auth_user.id,
        email=auth_user.email,  # email vem do Supabase Auth (a tabela users nao tem essa coluna)
        phone=auth_user.phone or None,
        name=profile.get("name"),
        created_at=profile.get("created_at"),
        terms_version=accepted_version,
        terms_accepted_at=profile.get("terms_accepted_at"),
        terms_current_version=CURRENT_TERMS_VERSION,
        terms_up_to_date=accepted_version == CURRENT_TERMS_VERSION,
    )


@router.post("/register-sso", response_model=UserResponse)
def register_sso(authorization: str = Header(...)):
    """Cria a linha em public.users no primeiro login. Idempotente: se ja existe, so devolve."""
    token = _bearer_to_token(authorization)
    auth_user = _get_auth_user(token)

    try:
        profile = _find_profile(auth_user.id)
        if profile is None:
            meta = auth_user.user_metadata or {}
            name = (
                meta.get("full_name")
                or meta.get("name")
                or (auth_user.email.split("@")[0] if auth_user.email else None)
            )
            res = supabase_admin.table("users").insert({"id": auth_user.id, "name": name}).execute()
            profile = res.data[0] if res.data else {"name": name}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao registrar usuario: {exc}")

    return _to_response(auth_user, profile)


@router.get("/me", response_model=UserResponse)
def get_me(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    auth_user = _get_auth_user(token)

    try:
        profile = _find_profile(auth_user.id)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao buscar usuario: {exc}")

    if profile is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario ainda nao registrado. Chame POST /auth/register-sso primeiro.",
        )

    return _to_response(auth_user, profile)


@router.post("/consent", response_model=UserResponse)
def accept_consent(payload: ConsentRequest, authorization: str = Header(...)):
    """Registra que o usuario aceitou a versao atual do termo de consentimento."""
    token = _bearer_to_token(authorization)
    auth_user = _get_auth_user(token)

    if payload.version != CURRENT_TERMS_VERSION:
        raise HTTPException(
            status_code=409,
            detail=f"Versao do termo desatualizada. Versao atual: {CURRENT_TERMS_VERSION}",
        )

    try:
        profile = _find_profile(auth_user.id)
        if profile is None:
            raise HTTPException(
                status_code=404,
                detail="Usuario ainda nao registrado. Chame POST /auth/register-sso primeiro.",
            )

        res = (
            supabase_admin.table("users")
            .update(
                {
                    "terms_version": CURRENT_TERMS_VERSION,
                    "terms_accepted_at": datetime.now(timezone.utc).isoformat(),
                }
            )
            .eq("id", auth_user.id)
            .execute()
        )
        profile = res.data[0] if res.data else _find_profile(auth_user.id)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao registrar consentimento: {exc}")

    return _to_response(auth_user, profile)