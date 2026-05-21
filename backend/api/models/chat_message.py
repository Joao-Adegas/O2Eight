from pydantic import BaseModel


class ChatMessage(BaseModel):
    id: int
    session_id: str
    sender: str
    message_text: str
    created_at: str | None = None
