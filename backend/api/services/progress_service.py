# api/services/progress_service.py
from __future__ import annotations

import json
from datetime import datetime, timezone

from api.core.supabase import supabase, supabase_admin
from api.prompts.recovery_prompts import RECOVERY_MILESTONES_SYSTEM_PROMPT
from api.services.ai_service import _call_groq_chat
from api.services.onboarding_service import _CIGARETTES_PER_DAY_TO_AVERAGE

CIGARETTES_PER_PACK = 20


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _parse_ts(value: str | None) -> datetime | None:
    """Converte o timestamp que vem do Supabase em datetime com fuso UTC."""
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _recovery_milestones(clean_days: int) -> list[str]:
    """
    Retorna mensagens motivacionais sobre recuperação biológica geradas pela IA,
    com base na quantidade de dias sem fumar.
    """
    try:
        raw = _call_groq_chat(
            system_prompt=RECOVERY_MILESTONES_SYSTEM_PROMPT,
            user_prompt=f"O usuário está há {clean_days} dia(s) sem fumar. Quais melhorias biológicas estão acontecendo agora?",
        )
        milestones = json.loads(raw)
        if isinstance(milestones, list) and all(isinstance(m, str) for m in milestones):
            return milestones
    except (json.JSONDecodeError, Exception):
        pass

    # Fallback estático caso a IA falhe
    if clean_days <= 0:
        return ["Cada dia limpo conta. Seu corpo já iniciou recuperação biológica."]
    return ["Pressão arterial normalizada.", "Oxigênio no sangue normalizado."]


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
        .insert({"user_id": user_id, "clean_days": 0, "created_at": _iso_now()})
        .execute()
    )
    return (inserted.data or [{}])[0]


def _clean_since(progress: dict) -> datetime:
    """
    Desde quando o usuário está sem fumar:
    - se já teve recaída → data da última recaída (last_smoked_at)
    - senão → data em que o progresso começou (created_at)
    """
    return (
        _parse_ts(progress.get("last_smoked_at"))
        or _parse_ts(progress.get("created_at"))
        or datetime.now(timezone.utc)
    )


def _compute_clean_days(progress: dict) -> tuple[int, float, datetime]:
    """Retorna (dias inteiros, dias com fração, data de início)."""
    since = _clean_since(progress)
    elapsed_seconds = max((datetime.now(timezone.utc) - since).total_seconds(), 0)
    elapsed_days = elapsed_seconds / 86400
    return int(elapsed_days), elapsed_days, since


def _sync_clean_days(user_id: str, progress: dict, clean_days: int) -> None:
    """Mantém a coluna clean_days atualizada (outras partes do app leem ela)."""
    if int(progress.get("clean_days") or 0) != clean_days:
        (
            supabase_admin.table("user_progress")
            .update({"clean_days": clean_days, "updated_at": _iso_now()})
            .eq("user_id", user_id)
            .execute()
        )


def _daily_cost(user_id: str) -> tuple[float, bool]:
    """
    Quanto o usuário gastava por dia com cigarro, a partir do formulário.
    Retorna (custo_diario, tem_formulario).
    """
    response = (
        supabase_admin.table("forms")
        .select("pack_price, cigarettes_per_day")
        .eq("user_uuid", user_id)
        .limit(1)
        .execute()
    )
    form = (response.data or [None])[0]
    if not form:
        return 0.0, False

    average_cigarettes = _CIGARETTES_PER_DAY_TO_AVERAGE.get(form.get("cigarettes_per_day"), 0)
    pack_price = float(form.get("pack_price") or 0)
    return (average_cigarettes / CIGARETTES_PER_PACK) * pack_price, True


def get_my_progress(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    return _get_or_create_progress(user_id)


def get_dashboard(token: str) -> dict:
    """Dados do card da Home: dias sem fumar e dinheiro economizado."""
    user_id = _extract_user_id_from_token(token)
    progress = _get_or_create_progress(user_id)

    clean_days, elapsed_days, since = _compute_clean_days(progress)
    _sync_clean_days(user_id, progress, clean_days)

    daily_cost, has_form = _daily_cost(user_id)

    return {
        "user_id": user_id,
        "clean_days": clean_days,
        "clean_since": since.isoformat(),
        "daily_cost": round(daily_cost, 2),
        # usa a fração do dia para o valor crescer ao longo do dia
        "estimated_saved_money": round(elapsed_days * daily_cost, 2),
        "has_form": has_form,
    }


def check_in_clean_day(token: str) -> dict:
    """
    Mantido por compatibilidade. Os dias agora são calculados pela data
    (ver get_dashboard), então o check-in manual não é mais necessário.
    """
    user_id = _extract_user_id_from_token(token)
    progress = _get_or_create_progress(user_id)
    clean_days, _, _ = _compute_clean_days(progress)
    _sync_clean_days(user_id, progress, clean_days)
    return _get_or_create_progress(user_id)


def mark_smoked(token: str) -> dict:
    """Recaída: zera o contador a partir de agora."""
    user_id = _extract_user_id_from_token(token)
    return mark_smoked_for_user(user_id)


def mark_smoked_for_user(user_id: str) -> dict:
    """Mesma coisa que mark_smoked, mas recebendo o id direto (será usado pelo hardware)."""
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
    clean_days, _, _ = _compute_clean_days(progress)

    return {
        "user_id": user_id,
        "clean_days": clean_days,
        "recuperation": _recovery_milestones(clean_days),
    }


def record_craving(
    token: str,
    outcome: str,
    started_at: str | None = None,
    duration_seconds: int = 0,
    source: str = "app",
) -> dict:
    """
    Registra um momento de vontade.
    outcome: "overcome" (passou), "smoked" (fumou) ou "abandoned" (saiu sem responder).
    Se fumou, reinicia o contador de dias sem fumar.
    """
    user_id = _extract_user_id_from_token(token)

    previous_clean_days = None
    if outcome == "smoked":
        previous_clean_days, _, _ = _compute_clean_days(_get_or_create_progress(user_id))

    (
        supabase_admin.table("craving_events")
        .insert(
            {
                "user_id": user_id,
                "started_at": started_at or _iso_now(),
                "duration_seconds": duration_seconds,
                "outcome": outcome,
                "source": source,
            }
        )
        .execute()
    )

    if outcome == "smoked":
        mark_smoked_for_user(user_id)

    overcome = (
        supabase_admin.table("craving_events")
        .select("uuid", count="exact")
        .eq("user_id", user_id)
        .eq("outcome", "overcome")
        .execute()
    )

    return {
        "outcome": outcome,
        "overcome_total": overcome.count or 0,
        "previous_clean_days": previous_clean_days,
    }