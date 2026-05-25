from pydantic import BaseModel


class ChatSession(BaseModel):
    uuid: str
    usuario_id: str
    titulo: str | None = None
    created_at: str | None = None
