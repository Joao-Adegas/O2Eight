# api/services/insights_service.py
"""
Insights: padrões de vontade e recaída do usuário.

Fontes:
- craving_events: cada uso do botão "Estou com vontade" (overcome, smoked, abandoned)
- hardware_sessions: cada sessão do dispositivo (simula um cigarro fumado)

Todos os horários são agrupados no fuso do aparelho do usuário (tz_offset_minutes),
não em UTC, para que "20h" signifique 20h para a pessoa.
"""
from __future__ import annotations

import time
from datetime import datetime, timedelta, timezone

from api.core.supabase import supabase, supabase_admin

MIN_EVENTS_FOR_PATTERNS = 5  # abaixo disso, os horários de risco vêm do formulário
WINDOW_HOURS = 2  # tamanho de uma janela de risco
MAX_RISK_WINDOWS = 3
ALERT_LEAD_MINUTES = 60  # quanto tempo antes da janela o alerta fica ativo
RECENT_LIMIT = 15

WEEKDAY_LABELS = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
PERIODS = [
    ("madrugada", "Madrugada", 0, 6),
    ("manha", "Manhã", 6, 12),
    ("tarde", "Tarde", 12, 18),
    ("noite", "Noite", 18, 24),
]
FORM_PERIOD_TO_HOURS = {
    "De manhã": (6, 12),
    "De tarde": (12, 18),
    "De noite": (18, 24),
}


# ───────────────────────── Leitura do banco ─────────────────────────

RETRY_ATTEMPTS = 3


def _with_retry(fn):
    """
    Repete chamadas ao Supabase que falham por erro de rede passageiro.
    O cliente do Supabase usa uma conexão HTTP/2 compartilhada; quando a Home
    e a tela de Insights pedem dados ao mesmo tempo, às vezes a conexão
    devolve "[Errno 11] Resource temporarily unavailable".
    """
    for attempt in range(RETRY_ATTEMPTS):
        try:
            return fn()
        except ValueError:
            raise  # token inválido: não adianta repetir
        except Exception:
            if attempt == RETRY_ATTEMPTS - 1:
                raise
            time.sleep(0.2 * (attempt + 1))


def _extract_user_id_from_token(token: str) -> str:
    auth_response = _with_retry(lambda: supabase.auth.get_user(token))
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _parse_ts(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _load_moments(user_id: str, since: datetime) -> list[dict]:
    """Junta vontades do app e sessões do dispositivo numa lista só."""
    moments: list[dict] = []

    cravings = _with_retry(
        lambda: supabase_admin.table("craving_events")
        .select("started_at, outcome, duration_seconds, source")
        .eq("user_id", user_id)
        .gte("started_at", since.isoformat())
        .execute()
    ).data or []
    for row in cravings:
        at = _parse_ts(row.get("started_at"))
        if at:
            moments.append(
                {
                    "at": at,
                    "kind": row.get("outcome") or "abandoned",
                    "source": row.get("source") or "app",
                    "duration_seconds": int(row.get("duration_seconds") or 0),
                }
            )

    sessions = _with_retry(
        lambda: supabase_admin.table("hardware_sessions")
        .select("inicio_da_sessao, fim_da_sessao, quantidade_puxadas")
        .eq("user_id", user_id)
        .gte("inicio_da_sessao", since.isoformat())
        .execute()
    ).data or []
    for row in sessions:
        at = _parse_ts(row.get("inicio_da_sessao"))
        end = _parse_ts(row.get("fim_da_sessao"))
        if at:
            moments.append(
                {
                    "at": at,
                    "kind": "device",
                    "source": "device",
                    "duration_seconds": int((end - at).total_seconds()) if end else 0,
                    "puffs": int(row.get("quantidade_puxadas") or 0),
                }
            )

    return moments


def _load_form(user_id: str) -> dict:
    response = _with_retry(
        lambda: supabase_admin.table("forms")
        .select("triggers, time_smoke_the_most")
        .eq("user_uuid", user_id)
        .limit(1)
        .execute()
    )
    return (response.data or [{}])[0] or {}


# ───────────────────────── Cálculo (sem banco, testável) ─────────────────────────

def _risk_windows(hour_totals: list[int]) -> list[dict]:
    """
    Janelas de 2h com mais momentos de vontade. Uma janela entra quando tem
    pelo menos 2 momentos e concentra 1,5x a média de uma janela qualquer.
    """
    total = sum(hour_totals)
    if total == 0:
        return []
    average = total * WINDOW_HOURS / 24
    candidates = []
    for start in range(24):
        count = sum(hour_totals[(start + i) % 24] for i in range(WINDOW_HOURS))
        if count >= 2 and count >= 1.5 * average:
            candidates.append((count, start))
    candidates.sort(key=lambda c: (-c[0], c[1]))

    chosen: list[dict] = []
    taken: set[int] = set()
    for count, start in candidates:
        hours = {(start + i) % 24 for i in range(WINDOW_HOURS)}
        if hours & taken:
            continue
        taken |= hours
        chosen.append(
            {
                "start_hour": start,
                "end_hour": (start + WINDOW_HOURS) % 24,
                "count": count,
                "share": round(count / total, 3),
                "source": "history",
            }
        )
        if len(chosen) == MAX_RISK_WINDOWS:
            break
    return chosen


def _next_alert(windows: list[dict], now_local: datetime) -> dict | None:
    """Próxima janela de risco a partir de agora, e se o alerta já está ativo."""
    best = None
    for w in windows:
        start = now_local.replace(hour=w["start_hour"], minute=0, second=0, microsecond=0)
        duration = timedelta(hours=(w["end_hour"] - w["start_hour"]) % 24 or 24)
        # Se a janela de hoje já acabou, considera a de amanhã
        if start + duration <= now_local:
            start += timedelta(days=1)
        # Janela que começou ontem e ainda não acabou (ex.: 23h–1h)
        elif start - timedelta(days=1) + duration > now_local:
            start -= timedelta(days=1)
        end = start + duration
        in_window = start <= now_local < end
        minutes_until = 0 if in_window else int((start - now_local).total_seconds() // 60)
        candidate = {
            "start_hour": w["start_hour"],
            "end_hour": w["end_hour"],
            "starts_at": start.isoformat(),
            "minutes_until": minutes_until,
            "in_window": in_window,
            "active": in_window or minutes_until <= ALERT_LEAD_MINUTES,
            "source": w["source"],
        }
        if best is None or minutes_until < best["minutes_until"]:
            best = candidate
    return best


def compute_insights(
    moments: list[dict],
    form: dict,
    now_utc: datetime,
    tz_offset_minutes: int,
    days: int,
) -> dict:
    tz = timezone(timedelta(minutes=tz_offset_minutes))
    now_local = now_utc.astimezone(tz)
    local = sorted(
        ({**m, "at": m["at"].astimezone(tz)} for m in moments),
        key=lambda m: m["at"],
    )

    # Momentos que contam para os padrões: abandonados não dizem se houve vontade forte
    counted = [m for m in local if m["kind"] in ("overcome", "smoked", "device")]

    by_hour = [{"hour": h, "overcome": 0, "smoked": 0, "device": 0} for h in range(24)]
    by_weekday = [
        {"weekday": i, "label": WEEKDAY_LABELS[i], "count": 0, "smoked": 0} for i in range(7)
    ]
    for m in counted:
        h, wd = m["at"].hour, m["at"].weekday()
        by_hour[h][m["kind"]] += 1
        by_weekday[wd]["count"] += 1
        if m["kind"] in ("smoked", "device"):
            by_weekday[wd]["smoked"] += 1

    hour_totals = [b["overcome"] + b["smoked"] + b["device"] for b in by_hour]
    by_period = []
    for key, label, start, end in PERIODS:
        hours = range(start, end)
        by_period.append(
            {
                "key": key,
                "label": label,
                "range": f"{start}h às {end}h",
                "count": sum(hour_totals[h] for h in hours),
                "smoked": sum(by_hour[h]["smoked"] + by_hour[h]["device"] for h in hours),
            }
        )

    overcome = sum(1 for m in counted if m["kind"] == "overcome")
    smoked = sum(1 for m in counted if m["kind"] == "smoked")
    device = sum(1 for m in counted if m["kind"] == "device")
    decided = overcome + smoked
    has_enough = len(counted) >= MIN_EVENTS_FOR_PATTERNS

    windows = _risk_windows(hour_totals) if has_enough else []
    form_period = form.get("time_smoke_the_most")
    if not windows and form_period in FORM_PERIOD_TO_HOURS:
        start, end = FORM_PERIOD_TO_HOURS[form_period]
        windows = [
            {"start_hour": start, "end_hour": end % 24, "count": 0, "share": 0, "source": "form"}
        ]

    recent = [
        {
            "at": m["at"].isoformat(),
            "kind": m["kind"],
            "source": m["source"],
            "duration_seconds": m["duration_seconds"],
            "puffs": m.get("puffs"),
        }
        for m in reversed(local[-RECENT_LIMIT:])
    ]

    return {
        "period_days": days,
        "generated_at": now_local.isoformat(),
        "has_enough_data": has_enough,
        "min_events_for_patterns": MIN_EVENTS_FOR_PATTERNS,
        "totals": {
            "moments": len(counted),
            "overcome": overcome,
            "smoked": smoked,
            "device": device,
            "success_rate": round(overcome / decided, 3) if decided else None,
        },
        "by_hour": by_hour,
        "by_period": by_period,
        "by_weekday": by_weekday,
        "risk_windows": windows,
        "next_alert": _next_alert(windows, now_local),
        "form_risk_period": form_period,
        "triggers": form.get("triggers") or [],
        "recent": recent,
    }


# ───────────────────────── Entrada da rota ─────────────────────────

def get_insights(token: str, days: int = 30, tz_offset_minutes: int = -180) -> dict:
    user_id = _extract_user_id_from_token(token)
    days = max(1, min(days, 365))
    tz_offset_minutes = max(-840, min(tz_offset_minutes, 840))

    now_utc = datetime.now(timezone.utc)
    moments = _load_moments(user_id, now_utc - timedelta(days=days))
    form = _load_form(user_id)
    return compute_insights(moments, form, now_utc, tz_offset_minutes, days)
