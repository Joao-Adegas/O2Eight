from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta, timezone
import json
import os
import urllib.request
import urllib.error

from api.core.supabase import supabase, supabase_admin


_GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
_GROQ_MODEL_DEFAULT = "llama-3.1-8b-instant"


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _iso_z(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def _parse_iso(ts: str) -> datetime:
    normalized = ts.replace("Z", "+00:00")
    return datetime.fromisoformat(normalized)


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token inválido")

    user_id = auth_user.id
    supabase_admin.table("users").upsert({"id": user_id}, on_conflict="id").execute()
    return user_id


def _get_user_profile(user_id: str) -> dict:
    profile_response = (
        supabase_admin.table("users")
        .select("daily_cigarette_consumption, pack_price, preferred_ai_tone")
        .eq("id", user_id)
        .limit(1)
        .execute()
    )
    return (profile_response.data or [{}])[0]


def _get_onboarding_answers(user_id: str) -> dict[str, list[str]]:
    response = (
        supabase_admin.table("onboarding_responses")
        .select("question_key, answer_text")
        .eq("user_id", user_id)
        .execute()
    )

    grouped: dict[str, list[str]] = {}
    for row in response.data or []:
        key = row.get("question_key")
        value = row.get("answer_text")
        if not key or value is None:
            continue
        grouped.setdefault(key, []).append(value)
    return grouped


def _get_recent_hardware_puffs(user_id: str, days: int = 30) -> list[dict]:
    start = _iso_z(_now_utc() - timedelta(days=days))
    response = (
        supabase_admin.table("hardware_puffs")
        .select("id, happened_at")
        .eq("user_id", user_id)
        .gte("happened_at", start)
        .order("happened_at", desc=False)
        .execute()
    )
    return response.data or []


def _call_groq_chat(system_prompt: str, user_prompt: str) -> str:
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        return "Respire por 90 segundos, beba água e mude de ambiente por 5 minutos. Você consegue atravessar essa janela de risco."

    payload = {
        "model": os.getenv("GROQ_MODEL", _GROQ_MODEL_DEFAULT),
        "temperature": 0.4,
        "max_tokens": 300,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }

    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        _GROQ_URL,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            parsed = json.loads(response.read().decode("utf-8"))
            choices = parsed.get("choices") or []
            if not choices:
                return "Vamos passar por essa vontade juntos. Faça 10 respirações lentas agora e me conte como ficou a intensidade."
            return choices[0].get("message", {}).get("content", "").strip() or (
                "Vamos passar por essa vontade juntos. Faça 10 respirações lentas agora e me conte como ficou a intensidade."
            )
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return "A vontade é temporária. Levante, caminhe por 3 minutos e tome um copo d'água para quebrar o gatilho."


def analyze_predictive_patterns(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    puffs = _get_recent_hardware_puffs(user_id, days=30)

    slots: list[tuple[int, int]] = []
    for puff in puffs:
        ts = puff.get("happened_at")
        if not ts:
            continue
        dt = _parse_iso(ts)
        slots.append((dt.weekday(), dt.hour))

    counts = Counter(slots)
    total = len(slots)

    patterns: list[dict] = []
    for (weekday, hour), count in counts.most_common(8):
        confidence = round(count / total, 3) if total else 0
        patterns.append(
            {
                "weekday": weekday,
                "hour": hour,
                "puffs_count": count,
                "confidence_score": confidence,
            }
        )

    return {
        "user_id": user_id,
        "evaluated_puffs": total,
        "patterns": patterns,
    }


def simulate_hardware_puffs(
    token: str,
    total_puffs: int,
    days_back: int,
    peak_weekday: int,
    peak_hour: int,
    peak_ratio: float,
    clear_existing: bool,
) -> dict:
    user_id = _extract_user_id_from_token(token)

    if clear_existing:
        supabase_admin.table("hardware_puffs").delete().eq("user_id", user_id).execute()

    now = _now_utc()
    peak_dates: list[datetime] = []
    for day_offset in range(days_back):
        day = (now - timedelta(days=day_offset)).date()
        if day.weekday() == peak_weekday:
            peak_dates.append(datetime.combine(day, datetime.min.time(), tzinfo=timezone.utc))

    if not peak_dates:
        peak_dates = [now]

    peak_count = int(total_puffs * peak_ratio)
    baseline_count = max(total_puffs - peak_count, 0)

    peak_rows: list[dict] = []
    minute_sequence = [3, 11, 19, 27, 35, 43, 51]
    for i in range(peak_count):
        day_ref = peak_dates[i % len(peak_dates)]
        minute = minute_sequence[i % len(minute_sequence)]
        happened_at = day_ref.replace(hour=peak_hour, minute=minute, second=0, microsecond=0)
        peak_rows.append({"user_id": user_id, "happened_at": _iso_z(happened_at)})

    baseline_rows: list[dict] = []
    baseline_hours = [8, 10, 12, 16, 18, 21]
    for i in range(baseline_count):
        day_offset = i % days_back
        hour = baseline_hours[i % len(baseline_hours)]
        minute = (i * 7) % 60
        day_ref = now - timedelta(days=day_offset)
        happened_at = day_ref.replace(hour=hour, minute=minute, second=0, microsecond=0)
        baseline_rows.append({"user_id": user_id, "happened_at": _iso_z(happened_at)})

    all_rows = peak_rows + baseline_rows
    if all_rows:
        supabase_admin.table("hardware_puffs").insert(all_rows).execute()

    return {
        "user_id": user_id,
        "inserted_puffs": len(all_rows),
        "peak_weekday": peak_weekday,
        "peak_hour": peak_hour,
        "days_back": days_back,
    }


def _next_weekday_hour(base: datetime, weekday: int, hour: int) -> datetime:
    days_ahead = (weekday - base.weekday()) % 7
    candidate = base.replace(hour=hour, minute=0, second=0, microsecond=0) + timedelta(days=days_ahead)
    if candidate <= base:
        candidate += timedelta(days=7)
    return candidate


def generate_predictive_alert(token: str, lead_minutes: int) -> dict:
    user_id = _extract_user_id_from_token(token)
    analysis = analyze_predictive_patterns(token)
    patterns = analysis["patterns"]

    if patterns:
        top = patterns[0]
        critical_time = _next_weekday_hour(_now_utc(), top["weekday"], top["hour"])
    else:
        critical_time = _now_utc() + timedelta(hours=24)

    predicted_at = critical_time - timedelta(minutes=lead_minutes)

    profile = _get_user_profile(user_id)
    onboarding = _get_onboarding_answers(user_id)

    motivation = ", ".join(onboarding.get("motivacao_parar", [])) or "saúde"
    triggers = ", ".join(onboarding.get("gatilho_emocional", [])) or "ansiedade"

    suggestion = _call_groq_chat(
        system_prompt=(
            "Você é um coach antitabagismo breve e prático. Responda em PT-BR com 1 ação imediata, "
            "1 ação de 5 minutos e 1 frase motivacional curta."
        ),
        user_prompt=(
            f"Usuário com gatilhos: {triggers}. Motivação principal: {motivation}. "
            f"Tom preferido: {profile.get('preferred_ai_tone') or 'empatico'}. "
            "Crie sugestão para janela de risco que começa em 10-15 minutos."
        ),
    )

    inserted = (
        supabase_admin.table("ai_predictive_alerts")
        .insert(
            {
                "user_id": user_id,
                "predicted_at": _iso_z(predicted_at),
                "sent_at": _iso_z(_now_utc()),
                "suggestion_text": suggestion,
                "result_status": "pending",
            }
        )
        .execute()
    )

    row = (inserted.data or [{}])[0]
    return {
        "alert_id": row.get("id"),
        "user_id": user_id,
        "predicted_at": row.get("predicted_at") or _iso_z(predicted_at),
        "sent_at": row.get("sent_at") or _iso_z(_now_utc()),
        "suggestion_text": row.get("suggestion_text") or suggestion,
    }


def evaluate_predictive_alert(token: str, alert_id: str, window_minutes: int) -> dict:
    user_id = _extract_user_id_from_token(token)

    alert_response = (
        supabase_admin.table("ai_predictive_alerts")
        .select("id, predicted_at")
        .eq("id", alert_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )

    alert = (alert_response.data or [None])[0]
    if not alert:
        raise ValueError("Alerta não encontrado para este usuário")

    predicted_at = _parse_iso(alert["predicted_at"])
    window_end = predicted_at + timedelta(minutes=window_minutes)

    puffs_response = (
        supabase_admin.table("hardware_puffs")
        .select("id")
        .eq("user_id", user_id)
        .gte("happened_at", _iso_z(predicted_at))
        .lte("happened_at", _iso_z(window_end))
        .execute()
    )

    puffs_in_window = len(puffs_response.data or [])
    status = "overcame_window" if puffs_in_window == 0 else "relapse_risk"

    supabase_admin.table("ai_predictive_alerts").update({"result_status": status}).eq("id", alert_id).eq(
        "user_id", user_id
    ).execute()

    return {
        "alert_id": alert_id,
        "user_id": user_id,
        "result_status": status,
        "puffs_in_window": puffs_in_window,
    }


def _build_behavioral_context(user_id: str) -> dict:
    profile = _get_user_profile(user_id)
    onboarding = _get_onboarding_answers(user_id)

    last_puff_resp = (
        supabase_admin.table("hardware_puffs")
        .select("happened_at")
        .eq("user_id", user_id)
        .order("happened_at", desc=True)
        .limit(1)
        .execute()
    )

    last_puff = (last_puff_resp.data or [None])[0]
    abstinence_hours: float | None = None
    estimated_saved_money: float | None = None

    if last_puff and last_puff.get("happened_at"):
        last_puff_at = _parse_iso(last_puff["happened_at"])
        abstinence_hours = round((_now_utc() - last_puff_at).total_seconds() / 3600, 2)

        daily = profile.get("daily_cigarette_consumption")
        price = profile.get("pack_price")
        if daily and price and daily > 0:
            abstinence_days = max(abstinence_hours / 24, 0)
            estimated_saved_money = round(abstinence_days * (daily / 20) * float(price), 2)

    return {
        "preferred_tone": profile.get("preferred_ai_tone") or "empatico",
        "triggers": onboarding.get("gatilho_emocional", []),
        "motivations": onboarding.get("motivacao_parar", []),
        "abstinence_hours": abstinence_hours,
        "estimated_saved_money": estimated_saved_money,
    }


def _behavioral_ai_reply(user_message: str, context: dict) -> str:
    tone = context["preferred_tone"]
    triggers = ", ".join(context["triggers"]) or "não informado"
    motivations = ", ".join(context["motivations"]) or "saúde"
    abstinence = context["abstinence_hours"]
    saved = context["estimated_saved_money"]

    return _call_groq_chat(
        system_prompt=(
            "Você é um assistente psicológico para cessação do tabagismo com técnicas de TCC. "
            "Resposta curta (4-8 linhas), acolhedora e prática, sem julgamento. "
            "Se o tom for energetico, seja direto e firme sem agressividade."
        ),
        user_prompt=(
            f"Tom: {tone}. Gatilhos: {triggers}. Motivações: {motivations}. "
            f"Horas sem fumar: {abstinence}. Economia estimada: {saved}. "
            f"Mensagem do usuário: {user_message}"
        ),
    )


def start_behavioral_quick_support(token: str, message: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    context = _build_behavioral_context(user_id)

    session_insert = (
        supabase_admin.table("chat_sessions")
        .insert(
            {
                "user_id": user_id,
                "initial_emotion": "craving",
                "final_status": "in_progress",
            }
        )
        .execute()
    )

    session = (session_insert.data or [{}])[0]
    session_id = session.get("id")
    if not session_id:
        raise ValueError("Não foi possível abrir sessão de chat")

    ai_message = _behavioral_ai_reply(message, context)

    supabase_admin.table("chat_messages").insert(
        [
            {
                "session_id": session_id,
                "sender": "user",
                "message_text": message,
            },
            {
                "session_id": session_id,
                "sender": "ai",
                "message_text": ai_message,
            },
        ]
    ).execute()

    return {
        "session_id": session_id,
        "user_id": user_id,
        "user_message": message,
        "ai_message": ai_message,
        "ai_tone_used": context["preferred_tone"],
        "abstinence_hours": context["abstinence_hours"],
        "estimated_saved_money": context["estimated_saved_money"],
    }


def send_behavioral_message(token: str, session_id: str, message: str) -> dict:
    user_id = _extract_user_id_from_token(token)

    session_response = (
        supabase_admin.table("chat_sessions")
        .select("id")
        .eq("id", session_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not (session_response.data or []):
        raise ValueError("Sessão não encontrada para este usuário")

    context = _build_behavioral_context(user_id)
    ai_message = _behavioral_ai_reply(message, context)

    supabase_admin.table("chat_messages").insert(
        [
            {
                "session_id": session_id,
                "sender": "user",
                "message_text": message,
            },
            {
                "session_id": session_id,
                "sender": "ai",
                "message_text": ai_message,
            },
        ]
    ).execute()

    return {
        "session_id": session_id,
        "ai_message": ai_message,
        "ai_tone_used": context["preferred_tone"],
    }
