from pydantic import BaseModel


class CommunityComment(BaseModel):
    uuid: str
    post_uuid: str
    user_uuid: str
    comment: str
    created_at: str | None = None
    likes: int = 0
