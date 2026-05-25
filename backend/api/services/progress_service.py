from __future__ import annotations

from datetime import datetime, timezone

from api.core.supabase import supabase, supabase_admin


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _recovery_milestones(clean_days: int) -> list[str]:
    milestones: list[str] = []
    if clean_days >= 1:
        milestones.append("Pressao arterial normalizada")
        milestones.append("Oxigenio no sangue normalizado")
    if clean_days >= 2:
        milestones.append("Nicotina eliminada do corpo")
    if clean_days >= 7:
        milestones.append("Paladar e olfato em recuperacao")
    if clean_days >= 14:
        milestones.append("Circulacao e respiracao melhorando")
    if clean_days >= 30:
        milestones.append("Tosse e falta de ar reduzindo")
    if clean_days >= 90:
        milestones.append("Funcao pulmonar com melhora relevante")
    if clean_days >= 365:
        milestones.append("Risco de doenca cardiaca reduzido em relacao ao inicio")

    if not milestones:
        milestones.append("Cada dia limpo conta. Seu corpo ja iniciou recuperacao biologica.")

    return milestones


def _get_or_create_progress(user_id: str) -> dict:
    response = (
        supabase_admin.table("user_progress")
        .select("uuid, user_id, clean_days, last_smoked_at, created_at, updated_at")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )

    existing = (response.data or [None])[0]
    if existing:
        return existing

    inserted = (
        supabase_admin.table("user_progress")
        .insert({"user_id": user_id, "clean_days": 0})
        .execute()
    )
    return (inserted.data or [{}])[0]


def get_my_progress(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    return _get_or_create_progress(user_id)


def check_in_clean_day(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    progress = _get_or_create_progress(user_id)

    last_update = progress.get("updated_at")
    now = datetime.now(timezone.utc)
    increment = True

    if last_update:
        update_dt = datetime.fromisoformat(last_update.replace("Z", "+00:00"))
        increment = update_dt.date() < now.date()

    new_clean_days = int(progress.get("clean_days") or 0)
    if increment:
        new_clean_days += 1

    updated = (
        supabase_admin.table("user_progress")
        .update({"clean_days": new_clean_days, "updated_at": _iso_now()})
        .eq("user_id", user_id)
        .execute()
    )

    return (updated.data or [{}])[0]


def mark_smoked(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    _get_or_create_progress(user_id)

    updated = (
        supabase_admin.table("user_progress")
        .update({"clean_days": 0, "last_smoked_at": _iso_now(), "updated_at": _iso_now()})
        .eq("user_id", user_id)
        .execute()
    )

    return (updated.data or [{}])[0]


def get_biological_recovery(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    progress = _get_or_create_progress(user_id)
    clean_days = int(progress.get("clean_days") or 0)

    return {
        "user_id": user_id,
        "clean_days": clean_days,
        "recuperation": _recovery_milestones(clean_days),
    }
