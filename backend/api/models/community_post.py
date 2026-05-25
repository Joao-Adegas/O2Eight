from pydantic import BaseModel


class CommunityPost(BaseModel):
    uuid: str
    user_uuid: str
    dias_limpos: int
    comment: str
    created_at: str | None = None
    likes: int = 0
