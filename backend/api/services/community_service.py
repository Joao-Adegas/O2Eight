# api/services/community_service.py
from __future__ import annotations

from api.core.supabase import supabase, supabase_admin

FEED_LIMIT = 50


class NotAllowedError(Exception):
    """Usuário tentou alterar conteúdo que não é dele."""


# ───────────────────────── Auxiliares ─────────────────────────

def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _clean_days_now(user_id: str) -> int:
    # Importação local para evitar dependência circular
    from api.services.progress_service import _compute_clean_days, _get_or_create_progress

    clean_days, _, _ = _compute_clean_days(_get_or_create_progress(user_id))
    return clean_days


def _names_for(user_ids: set[str]) -> dict[str, str]:
    if not user_ids:
        return {}
    response = supabase_admin.table("users").select("id, name").in_("id", list(user_ids)).execute()
    return {row["id"]: (row.get("name") or "Usuário") for row in (response.data or [])}


def _likes_for(column: str, target_ids: list[str], user_id: str) -> tuple[dict[str, int], set[str]]:
    """Conta curtidas por alvo e diz quais o usuário atual curtiu."""
    if not target_ids:
        return {}, set()
    response = (
        supabase_admin.table("community_likes")
        .select(f"{column}, user_uuid")
        .in_(column, target_ids)
        .execute()
    )
    counts: dict[str, int] = {}
    mine: set[str] = set()
    for row in response.data or []:
        target = row[column]
        counts[target] = counts.get(target, 0) + 1
        if row["user_uuid"] == user_id:
            mine.add(target)
    return counts, mine


def _author_name(row: dict, names: dict[str, str]) -> str | None:
    if row.get("is_anonymous"):
        return None
    return names.get(row.get("user_uuid"), "Usuário")


def _serialize_comment(row: dict, user_id: str, names: dict, counts: dict, liked: set) -> dict:
    return {
        "uuid": row["uuid"],
        "post_uuid": row["post_uuid"],
        "parent_uuid": row.get("parent_uuid"),
        "author_name": _author_name(row, names),
        "is_anonymous": bool(row.get("is_anonymous")),
        "is_mine": row.get("user_uuid") == user_id,
        "comment": row.get("comment") or "",
        "created_at": row.get("created_at"),
        "likes": counts.get(row["uuid"], 0),
        "liked_by_me": row["uuid"] in liked,
    }


def _serialize_post(
    row: dict,
    user_id: str,
    names: dict,
    counts: dict,
    liked: set,
    comments_count: int,
    comments: list[dict] | None = None,
) -> dict:
    return {
        "uuid": row["uuid"],
        "author_name": _author_name(row, names),
        "is_anonymous": bool(row.get("is_anonymous")),
        "is_mine": row.get("user_uuid") == user_id,
        "dias_limpos": int(row.get("dias_limpos") or 0),
        "comment": row.get("comment") or "",
        "created_at": row.get("created_at"),
        "likes": counts.get(row["uuid"], 0),
        "liked_by_me": row["uuid"] in liked,
        "comments_count": comments_count,
        "comments": comments or [],
    }


def _get_post_row(post_id: str) -> dict:
    response = supabase_admin.table("community_posts").select("*").eq("uuid", post_id).limit(1).execute()
    row = (response.data or [None])[0]
    if not row:
        raise ValueError("Publicacao nao encontrada")
    return row


def _get_comment_row(comment_id: str) -> dict:
    response = supabase_admin.table("community_comments").select("*").eq("uuid", comment_id).limit(1).execute()
    row = (response.data or [None])[0]
    if not row:
        raise ValueError("Comentario nao encontrado")
    return row


def _post_detail(user_id: str, post_id: str) -> dict:
    post = _get_post_row(post_id)

    comments = (
        supabase_admin.table("community_comments")
        .select("*")
        .eq("post_uuid", post_id)
        .order("created_at", desc=False)
        .execute()
    ).data or []

    author_ids = {post["user_uuid"]} if not post.get("is_anonymous") else set()
    author_ids |= {c["user_uuid"] for c in comments if not c.get("is_anonymous")}
    names = _names_for(author_ids)

    post_counts, post_liked = _likes_for("post_uuid", [post_id], user_id)
    comment_counts, comment_liked = _likes_for("comment_uuid", [c["uuid"] for c in comments], user_id)

    serialized_comments = [
        _serialize_comment(c, user_id, names, comment_counts, comment_liked) for c in comments
    ]
    return _serialize_post(post, user_id, names, post_counts, post_liked, len(comments), serialized_comments)


# ───────────────────────── Publicações ─────────────────────────

def list_posts(token: str) -> list[dict]:
    """Feed: publicações mais recentes, sem os comentários (só a contagem)."""
    user_id = _extract_user_id_from_token(token)

    posts = (
        supabase_admin.table("community_posts")
        .select("*")
        .order("created_at", desc=True)
        .limit(FEED_LIMIT)
        .execute()
    ).data or []
    post_ids = [p["uuid"] for p in posts]

    comments_count: dict[str, int] = {}
    if post_ids:
        rows = (
            supabase_admin.table("community_comments")
            .select("post_uuid")
            .in_("post_uuid", post_ids)
            .execute()
        ).data or []
        for row in rows:
            comments_count[row["post_uuid"]] = comments_count.get(row["post_uuid"], 0) + 1

    names = _names_for({p["user_uuid"] for p in posts if not p.get("is_anonymous")})
    counts, liked = _likes_for("post_uuid", post_ids, user_id)

    return [
        _serialize_post(p, user_id, names, counts, liked, comments_count.get(p["uuid"], 0))
        for p in posts
    ]


def get_post(token: str, post_id: str) -> dict:
    """Publicação com todos os comentários e respostas."""
    user_id = _extract_user_id_from_token(token)
    return _post_detail(user_id, post_id)


def create_post(token: str, comment: str, is_anonymous: bool = False) -> dict:
    user_id = _extract_user_id_from_token(token)

    inserted = (
        supabase_admin.table("community_posts")
        .insert(
            {
                "user_uuid": user_id,
                "comment": comment.strip(),
                "dias_limpos": _clean_days_now(user_id),
                "is_anonymous": is_anonymous,
            }
        )
        .execute()
    )
    post_id = (inserted.data or [{}])[0].get("uuid")
    return _post_detail(user_id, post_id)


def delete_post(token: str, post_id: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    post = _get_post_row(post_id)
    if post.get("user_uuid") != user_id:
        raise NotAllowedError("Voce so pode excluir suas proprias publicacoes")

    comment_ids = [
        c["uuid"]
        for c in (
            supabase_admin.table("community_comments").select("uuid").eq("post_uuid", post_id).execute()
        ).data or []
    ]
    if comment_ids:
        supabase_admin.table("community_likes").delete().in_("comment_uuid", comment_ids).execute()
        supabase_admin.table("community_comments").delete().eq("post_uuid", post_id).execute()
    supabase_admin.table("community_likes").delete().eq("post_uuid", post_id).execute()
    supabase_admin.table("community_posts").delete().eq("uuid", post_id).execute()
    return {"deleted": True}


# ───────────────────────── Comentários ─────────────────────────

def create_comment(
    token: str,
    post_id: str,
    comment: str,
    parent_uuid: str | None = None,
    is_anonymous: bool = False,
) -> dict:
    user_id = _extract_user_id_from_token(token)
    _get_post_row(post_id)

    if parent_uuid:
        parent = _get_comment_row(parent_uuid)
        if parent["post_uuid"] != post_id:
            raise ValueError("O comentario respondido nao pertence a esta publicacao")
        # Um nível de resposta: responder uma resposta entra no mesmo fio
        parent_uuid = parent.get("parent_uuid") or parent["uuid"]

    inserted = (
        supabase_admin.table("community_comments")
        .insert(
            {
                "post_uuid": post_id,
                "user_uuid": user_id,
                "comment": comment.strip(),
                "parent_uuid": parent_uuid,
                "is_anonymous": is_anonymous,
            }
        )
        .execute()
    )
    row = (inserted.data or [{}])[0]
    names = _names_for({user_id})
    return _serialize_comment(row, user_id, names, {}, set())


def delete_comment(token: str, comment_id: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    comment = _get_comment_row(comment_id)
    if comment.get("user_uuid") != user_id:
        raise NotAllowedError("Voce so pode excluir seus proprios comentarios")

    reply_ids = [
        r["uuid"]
        for r in (
            supabase_admin.table("community_comments").select("uuid").eq("parent_uuid", comment_id).execute()
        ).data or []
    ]
    ids = [comment_id, *reply_ids]
    supabase_admin.table("community_likes").delete().in_("comment_uuid", ids).execute()
    if reply_ids:
        supabase_admin.table("community_comments").delete().in_("uuid", reply_ids).execute()
    supabase_admin.table("community_comments").delete().eq("uuid", comment_id).execute()
    return {"deleted": True}


# ───────────────────────── Curtidas ─────────────────────────

def _toggle_like(user_id: str, column: str, target_id: str, counter_table: str) -> dict:
    existing = (
        supabase_admin.table("community_likes")
        .select("uuid")
        .eq("user_uuid", user_id)
        .eq(column, target_id)
        .limit(1)
        .execute()
    ).data or []

    if existing:
        supabase_admin.table("community_likes").delete().eq("uuid", existing[0]["uuid"]).execute()
        liked = False
    else:
        supabase_admin.table("community_likes").insert({"user_uuid": user_id, column: target_id}).execute()
        liked = True

    counts, _ = _likes_for(column, [target_id], user_id)
    total = counts.get(target_id, 0)

    # Mantém a coluna "likes" coerente com a contagem real
    supabase_admin.table(counter_table).update({"likes": total}).eq("uuid", target_id).execute()
    return {"liked": liked, "likes": total}


def toggle_post_like(token: str, post_id: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    _get_post_row(post_id)
    return _toggle_like(user_id, "post_uuid", post_id, "community_posts")


def toggle_comment_like(token: str, comment_id: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    _get_comment_row(comment_id)
    return _toggle_like(user_id, "comment_uuid", comment_id, "community_comments")