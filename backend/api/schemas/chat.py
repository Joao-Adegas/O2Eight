from typing import Literal

from pydantic import BaseModel, Field


Sender = Literal["usuario", "bot"]


class ChatSessionCreateRequest(BaseModel):
    titulo: str | None = Field(default=None, max_length=200)


class ChatSessionResponse(BaseModel):
    uuid: str
    usuario_id: str
    titulo: str | None = None
    created_at: str | None = None


class ChatMessageCreateRequest(BaseModel):
    conteudo: str = Field(min_length=1, max_length=3000)


class ChatMessageResponse(BaseModel):
    uuid: str
    sessao_id: str
    remetente: Sender
    conteudo: str
    enviado_em: str | None = None


class ChatConversationResponse(BaseModel):
    sessao: ChatSessionResponse
    mensagens: list[ChatMessageResponse]
