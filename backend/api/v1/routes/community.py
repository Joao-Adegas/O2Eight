# api/v1/routes/community.py
from fastapi import APIRouter, Header, HTTPException

from api.schemas.community import (
    CommunityCommentCreateRequest,
    CommunityCommentResponse,
    CommunityPostCreateRequest,
    CommunityPostResponse,
    DeleteResponse,
    LikeToggleResponse,
)
from api.services.community_service import (
    NotAllowedError,
    create_comment,
    create_post,
    delete_comment,
    delete_post,
    get_post,
    list_posts,
    toggle_comment_like,
    toggle_post_like,
)

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


def _run(action, error_message: str):
    """Executa a ação e converte os erros do service em respostas HTTP."""
    try:
        return action()
    except NotAllowedError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"{error_message}: {str(exc)}")


# ───────────────────────── Publicações ─────────────────────────

@router.get("/posts", response_model=list[CommunityPostResponse])
def get_community_posts(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(lambda: list_posts(token), "Falha ao listar publicacoes")


@router.post("/posts", response_model=CommunityPostResponse)
def post_community(payload: CommunityPostCreateRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(
        lambda: create_post(token, payload.comment, payload.is_anonymous),
        "Falha ao criar publicacao",
    )


@router.get("/posts/{post_id}", response_model=CommunityPostResponse)
def get_community_post(post_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(lambda: get_post(token, post_id), "Falha ao buscar publicacao")


@router.delete("/posts/{post_id}", response_model=DeleteResponse)
def delete_community_post(post_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(lambda: delete_post(token, post_id), "Falha ao excluir publicacao")


@router.post("/posts/{post_id}/like", response_model=LikeToggleResponse)
def like_community_post(post_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(lambda: toggle_post_like(token, post_id), "Falha ao curtir publicacao")


# ───────────────────────── Comentários ─────────────────────────

@router.post("/posts/{post_id}/comments", response_model=CommunityCommentResponse)
def post_community_comment(
    post_id: str,
    payload: CommunityCommentCreateRequest,
    authorization: str = Header(...),
):
    token = _bearer_to_token(authorization)
    return _run(
        lambda: create_comment(
            token, post_id, payload.comment, payload.parent_uuid, payload.is_anonymous
        ),
        "Falha ao criar comentario",
    )


@router.delete("/comments/{comment_id}", response_model=DeleteResponse)
def delete_community_comment(comment_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(lambda: delete_comment(token, comment_id), "Falha ao excluir comentario")


@router.post("/comments/{comment_id}/like", response_model=LikeToggleResponse)
def like_community_comment(comment_id: str, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    return _run(lambda: toggle_comment_like(token, comment_id), "Falha ao curtir comentario")