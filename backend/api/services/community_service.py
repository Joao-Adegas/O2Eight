from api.core.supabase import supabase, supabase_admin


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def create_post(token: str, comment: str) -> dict:
    user_id = _extract_user_id_from_token(token)

    progress_resp = (
        supabase_admin.table("user_progress")
        .select("clean_days")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    progress = (progress_resp.data or [{"clean_days": 0}])[0]

    inserted = (
        supabase_admin.table("community_posts")
        .insert({
            "user_uuid": user_id,
            "dias_limpos": int(progress.get("clean_days") or 0),
            "comment": comment,
            "likes": 0,
        })
        .execute()
    )

    row = (inserted.data or [{}])[0]
    row["comments"] = []
    return row


def create_comment(token: str, post_uuid: str, comment: str) -> dict:
    user_id = _extract_user_id_from_token(token)

    inserted = (
        supabase_admin.table("community_comments")
        .insert({"post_uuid": post_uuid, "user_uuid": user_id, "comment": comment, "likes": 0})
        .execute()
    )

    return (inserted.data or [{}])[0]


def list_posts(token: str, limit: int = 50) -> list[dict]:
    _extract_user_id_from_token(token)

    posts_resp = (
        supabase_admin.table("community_posts")
        .select("uuid, user_uuid, dias_limpos, comment, created_at, likes")
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )

    posts = posts_resp.data or []
    if not posts:
        return []

    post_ids = [post["uuid"] for post in posts if post.get("uuid")]
    comments_resp = (
        supabase_admin.table("community_comments")
        .select("uuid, post_uuid, user_uuid, comment, created_at, likes")
        .in_("post_uuid", post_ids)
        .order("created_at", desc=False)
        .execute()
    )

    comments_map: dict[str, list[dict]] = {}
    for comment in comments_resp.data or []:
        post_id = comment.get("post_uuid")
        if not post_id:
            continue
        comments_map.setdefault(post_id, []).append(comment)

    for post in posts:
        post["comments"] = comments_map.get(post.get("uuid"), [])

    return posts
