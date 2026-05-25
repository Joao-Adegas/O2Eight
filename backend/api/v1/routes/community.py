from fastapi import APIRouter, Header, HTTPException

from api.schemas.community import (
    CommunityCommentCreateRequest,
    CommunityCommentResponse,
    CommunityPostCreateRequest,
    CommunityPostResponse,
)
from api.services.community_service import create_comment, create_post, like_comment, like_post, list_posts

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


@router.post("/posts", response_model=CommunityPostResponse)
def post_community(payload: CommunityPostCreateRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return create_post(token, payload.comment)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao criar post: {str(exc)}")


@router.get("/posts", response_model=list[CommunityPostResponse])
def get_community_posts(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return list_posts(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao listar posts: {str(exc)}")


@router.post("/posts/{post_id}/comments", response_model=CommunityCommentResponse)
def post_community_comment(
    post_id: str,
    payload: CommunityCommentCreateRequest,
    authorization: str = Header(...),
):
    token = _bearer_to_token(authorization)
    try:
        return create_comment(token, post_id, payload.comment)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao criar comentario: {str(exc)}")


@router.post("/comments/{comment_id}/like", response_model=CommunityCommentResponse)
def post_like_community_comment(comment_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return like_comment(token, comment_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao curtir comentario: {str(exc)}")


@router.post("/posts/{post_id}/like", response_model=CommunityPostResponse)
def post_like_community_post(post_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return like_post(token, post_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao curtir post: {str(exc)}")
