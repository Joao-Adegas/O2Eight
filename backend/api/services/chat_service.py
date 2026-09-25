# api/services/chat_service.py
from api.core.supabase import supabase, supabase_admin
from api.services.ai_service import CHAT_HISTORY_LIMIT, generate_chatbot_reply

TITLE_MAX_LENGTH = 40


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _get_own_session(session_id: str, user_id: str) -> dict:
    session_resp = (
        supabase_admin.table("chat_sessions_new")
        .select("uuid, usuario_id, titulo, created_at")
        .eq("uuid", session_id)
        .eq("usuario_id", user_id)
        .limit(1)
        .execute()
    )
    session = (session_resp.data or [None])[0]
    if not session:
        raise ValueError("Sessao nao encontrada para este usuario")
    return session


def _title_from(text: str) -> str:
    clean = " ".join(text.split())
    if len(clean) <= TITLE_MAX_LENGTH:
        return clean
    return clean[:TITLE_MAX_LENGTH].rstrip() + "…"


def create_session(token: str, titulo: str | None) -> dict:
    user_id = _extract_user_id_from_token(token)

    inserted = (
        supabase_admin.table("chat_sessions_new")
        .insert({"usuario_id": user_id, "titulo": titulo})
        .execute()
    )

    return (inserted.data or [{}])[0]


def list_sessions(token: str, limit: int = 50) -> list[dict]:
    user_id = _extract_user_id_from_token(token)

    response = (
        supabase_admin.table("chat_sessions_new")
        .select("uuid, usuario_id, titulo, created_at")
        .eq("usuario_id", user_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )

    return response.data or []


def send_message(token: str, session_id: str, conteudo: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    session = _get_own_session(session_id, user_id)

    # Últimas mensagens da conversa, para a IA lembrar do contexto
    history_resp = (
        supabase_admin.table("chat_messages_new")
        .select("remetente, conteudo, enviado_em")
        .eq("sessao_id", session_id)
        .order("enviado_em", desc=True)
        .limit(CHAT_HISTORY_LIMIT)
        .execute()
    )
    history = list(reversed(history_resp.data or []))

    # Gera a resposta ANTES de gravar: se a IA falhar, nada fica salvo pela metade
    bot_reply = generate_chatbot_reply(token, conteudo, history)

    user_insert = (
        supabase_admin.table("chat_messages_new")
        .insert({"sessao_id": session_id, "remetente": "usuario", "conteudo": conteudo})
        .execute()
    )
    bot_insert = (
        supabase_admin.table("chat_messages_new")
        .insert({"sessao_id": session_id, "remetente": "bot", "conteudo": bot_reply})
        .execute()
    )

    # Primeira mensagem da conversa vira o título da sessão
    if not session.get("titulo"):
        (
            supabase_admin.table("chat_sessions_new")
            .update({"titulo": _title_from(conteudo)})
            .eq("uuid", session_id)
            .execute()
        )

    return {
        "user_message": (user_insert.data or [{}])[0],
        "bot_message": (bot_insert.data or [{}])[0],
    }


def get_conversation(token: str, session_id: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    session = _get_own_session(session_id, user_id)

    messages_resp = (
        supabase_admin.table("chat_messages_new")
        .select("uuid, sessao_id, remetente, conteudo, enviado_em")
        .eq("sessao_id", session_id)
        .order("enviado_em", desc=False)
        .execute()
    )

    return {"sessao": session, "mensagens": messages_resp.data or []}