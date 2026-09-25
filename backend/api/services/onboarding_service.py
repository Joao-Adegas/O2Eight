from __future__ import annotations

from datetime import datetime, timezone

from api.core.supabase import supabase, supabase_admin
from api.schemas.onboarding import FormUpsertRequest

_CIGARETTES_PER_DAY_TO_AVERAGE = {
    "Entre 1 e 5": 3,
    "Entre 5 e 10": 8,
    "Entre 10 e 15": 12,
    "Entre 15 e 20": 18,
    "Mais de 20": 25,
}


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def upsert_form(token: str, payload: FormUpsertRequest) -> dict:
    user_id = _extract_user_id_from_token(token)

    # Ensures profile row exists after SSO login.
    supabase_admin.table("users").upsert({"id": user_id}, on_conflict="id").execute()

    row = {
        "user_uuid": user_id,
        "smoking_time": payload.smoking_time,
        "cigarettes_per_day": payload.cigarettes_per_day,
        "cigarette_type": payload.cigarette_type,
        "motivations_to_quit": payload.motivations_to_quit,
        "pack_price": payload.pack_price,
        "triggers": payload.triggers,
        "family_health_history": payload.family_health_history,
        "time_smoke_the_most": payload.time_smoke_the_most,
        "updated_at": _iso_now(),
    }

    response = supabase_admin.table("forms").upsert(row, on_conflict="user_uuid").execute()
    saved = (response.data or [{}])[0]

    return {
        "uuid": saved.get("uuid"),
        "user_uuid": saved.get("user_uuid", user_id),
        "smoking_time": saved.get("smoking_time", payload.smoking_time),
        "cigarettes_per_day": saved.get("cigarettes_per_day", payload.cigarettes_per_day),
        "cigarette_type": saved.get("cigarette_type", payload.cigarette_type),
        "motivations_to_quit": saved.get("motivations_to_quit", payload.motivations_to_quit),
        "pack_price": float(saved.get("pack_price", payload.pack_price)),
        "triggers": saved.get("triggers", payload.triggers),
        "family_health_history": saved.get("family_health_history", payload.family_health_history),
        "time_smoke_the_most": saved.get("time_smoke_the_most", payload.time_smoke_the_most),
        "created_at": saved.get("created_at"),
        "updated_at": saved.get("updated_at", row["updated_at"]),
    }


def get_my_form(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)

    response = (
        supabase_admin.table("forms")
        .select(
            "uuid, user_uuid, smoking_time, cigarettes_per_day, cigarette_type, motivations_to_quit, "
            "pack_price, triggers, family_health_history, time_smoke_the_most, created_at, updated_at"
        )
        .eq("user_uuid", user_id)
        .limit(1)
        .execute()
    )

    form = (response.data or [None])[0]
    if not form:
        raise ValueError("Formulario ainda nao foi preenchido")

    form["pack_price"] = float(form.get("pack_price") or 0)
    return form


def get_form_savings(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)

    form = get_my_form(token)
    average_cigarettes = _CIGARETTES_PER_DAY_TO_AVERAGE.get(form["cigarettes_per_day"], 0)

    progress_resp = (
        supabase_admin.table("user_progress")
        .select("clean_days")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    progress = (progress_resp.data or [{"clean_days": 0}])[0]

    clean_days = int(progress.get("clean_days") or 0)
    pack_price = float(form["pack_price"])
    estimated_saved_money = round(clean_days * (average_cigarettes / 20.0) * pack_price, 2)

    return {
        "user_uuid": user_id,
        "clean_days": clean_days,
        "estimated_saved_money": estimated_saved_money,
    }
