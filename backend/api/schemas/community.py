# api/schemas/community.py
from pydantic import BaseModel, Field


class CommunityPostCreateRequest(BaseModel):
    comment: str = Field(min_length=1, max_length=3000)
    is_anonymous: bool = False


class CommunityCommentCreateRequest(BaseModel):
    comment: str = Field(min_length=1, max_length=1500)
    parent_uuid: str | None = None  # preenchido quando é resposta a outro comentário
    is_anonymous: bool = False


class CommunityCommentResponse(BaseModel):
    uuid: str
    post_uuid: str
    parent_uuid: str | None = None
    author_name: str | None = None  # None quando anônimo
    is_anonymous: bool = False
    is_mine: bool = False
    comment: str
    created_at: str | None = None
    likes: int = 0
    liked_by_me: bool = False


class CommunityPostResponse(BaseModel):
    uuid: str
    author_name: str | None = None  # None quando anônimo
    is_anonymous: bool = False
    is_mine: bool = False
    dias_limpos: int = 0
    comment: str
    created_at: str | None = None
    likes: int = 0
    liked_by_me: bool = False
    comments_count: int = 0
    comments: list[CommunityCommentResponse] = []


class LikeToggleResponse(BaseModel):
    liked: bool
    likes: int


class DeleteResponse(BaseModel):
    deleted: bool