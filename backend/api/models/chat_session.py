from pydantic import BaseModel


class ChatSession(BaseModel):
    id: str
    user_id: str
    started_at: str | None = None
    ended_at: str | None = None
    initial_emotion: str | None = None
    final_status: str | None = None
