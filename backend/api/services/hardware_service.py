from api.core.supabase import supabase, supabase_admin


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def create_hardware_session(token: str, payload: dict) -> dict:
    user_id = _extract_user_id_from_token(token)

    if payload["user_id"] != user_id:
        raise ValueError("O user_id enviado deve ser igual ao usuario autenticado")

    row = {
        "user_id": user_id,
        "quantidade_puxadas": payload["quantidade_puxadas"],
        "inicio_da_sessao": payload["inicio_da_sessao"],
        "fim_da_sessao": payload["fim_da_sessao"],
    }

    inserted = supabase_admin.table("hardware_sessions").insert(row).execute()
    return (inserted.data or [{}])[0]


def list_my_hardware_sessions(token: str, limit: int = 50) -> list[dict]:
    user_id = _extract_user_id_from_token(token)

    response = (
        supabase_admin.table("hardware_sessions")
        .select("uuid, user_id, quantidade_puxadas, inicio_da_sessao, fim_da_sessao, created_at")
        .eq("user_id", user_id)
        .order("inicio_da_sessao", desc=True)
        .limit(limit)
        .execute()
    )

    return response.data or []
