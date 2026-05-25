from pydantic import BaseModel, Field


class CommunityCommentCreateRequest(BaseModel):
    comment: str = Field(min_length=1, max_length=1500)


class CommunityPostCreateRequest(BaseModel):
    comment: str = Field(min_length=1, max_length=3000)


class CommunityCommentResponse(BaseModel):
    uuid: str
    post_uuid: str
    user_uuid: str
    comment: str
    created_at: str | None = None
    likes: int = 0


class CommunityPostResponse(BaseModel):
    uuid: str
    user_uuid: str
    dias_limpos: int
    comment: str
    created_at: str | None = None
    likes: int = 0
    comments: list[CommunityCommentResponse] = []
