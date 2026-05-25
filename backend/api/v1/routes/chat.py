from fastapi import APIRouter, Header, HTTPException

from api.schemas.chat import (
    ChatConversationResponse,
    ChatMessageCreateRequest,
    ChatMessageResponse,
    ChatSessionCreateRequest,
    ChatSessionResponse,
)
from api.services.chat_service import create_session, get_conversation, list_sessions, send_message

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


@router.post("/sessions", response_model=ChatSessionResponse)
def start_chat_session(payload: ChatSessionCreateRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return create_session(token, payload.titulo)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao criar sessao: {str(exc)}")


@router.get("/sessions", response_model=list[ChatSessionResponse])
def get_chat_sessions(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return list_sessions(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao listar sessoes: {str(exc)}")


@router.post("/sessions/{session_id}/messages", response_model=list[ChatMessageResponse])
def post_chat_message(
    session_id: str,
    payload: ChatMessageCreateRequest,
    authorization: str = Header(...),
):
    token = _bearer_to_token(authorization)
    try:
        result = send_message(token, session_id, payload.conteudo)
        return [result["user_message"], result["bot_message"]]
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=f"Falha no provedor de IA: {str(exc)}")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao enviar mensagem: {str(exc)}")


@router.get("/sessions/{session_id}", response_model=ChatConversationResponse)
def get_chat_conversation(session_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return get_conversation(token, session_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao buscar conversa: {str(exc)}")
