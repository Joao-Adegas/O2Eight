from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

from api.prompts.ai_prompts import CHATBOT_SYSTEM_PROMPT, DAILY_TIP_SYSTEM_PROMPT
from api.core.supabase import supabase, supabase_admin

_GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
_GROQ_MODEL_DEFAULT = "llama-3.1-8b-instant"


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _call_groq_chat(system_prompt: str, user_prompt: str) -> str:
    api_key = (os.getenv("GROQ_API_KEY") or "").strip()
    if not api_key:
        raise RuntimeError("GROQ_API_KEY nao configurada. Defina a chave para habilitar respostas reais da IA.")

    payload = {
        "model": (os.getenv("GROQ_MODEL") or _GROQ_MODEL_DEFAULT).strip(),
        "temperature": 0.4,
        "max_tokens": 350,
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
            "Accept": "application/json",
            "User-Agent": "O2Eight-Backend/1.0",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            parsed = json.loads(response.read().decode("utf-8"))
            choices = parsed.get("choices") or []
            if not choices:
                raise RuntimeError("Groq retornou resposta sem opcoes de completacao.")
            content = choices[0].get("message", {}).get("content", "").strip()
            if not content:
                raise RuntimeError("Groq retornou conteudo vazio.")
            return content
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="ignore")
        if exc.code == 403 and "1010" in error_body:
            raise RuntimeError(
                "Groq bloqueou a requisicao (HTTP 403/1010). Verifique rede/VPN/firewall e valide a chave da API."
            ) from exc
        raise RuntimeError(f"Groq HTTP {exc.code}: {error_body[:300]}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Falha de conexao com Groq: {exc.reason}") from exc
    except TimeoutError as exc:
        raise RuntimeError("Timeout ao consultar Groq.") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError("Resposta invalida da Groq (JSON malformado).") from exc


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
        milestones.append("Seu corpo ja comecou a se recuperar. Cada dia limpo importa.")

    return milestones


def _get_form(user_id: str) -> dict:
    response = (
        supabase_admin.table("forms")
        .select(
            "smoking_time, cigarettes_per_day, cigarette_type, motivations_to_quit, pack_price, "
            "triggers, family_health_history, time_smoke_the_most"
        )
        .eq("user_uuid", user_id)
        .limit(1)
        .execute()
    )
    form = (response.data or [None])[0]
    if not form:
        raise ValueError("Formulario nao encontrado para este usuario")
    return form


def _get_progress(user_id: str) -> dict:
    response = (
        supabase_admin.table("user_progress")
        .select("clean_days, last_smoked_at")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    return (response.data or [{"clean_days": 0, "last_smoked_at": None}])[0]


def _get_hardware_summary(user_id: str) -> dict:
    response = (
        supabase_admin.table("hardware_sessions")
        .select("quantidade_puxadas, inicio_da_sessao")
        .eq("user_id", user_id)
        .order("inicio_da_sessao", desc=True)
        .limit(30)
        .execute()
    )
    sessions = response.data or []
    if not sessions:
        return {"sessions": 0, "total_puffs": 0}

    total_puffs = sum(int(item.get("quantidade_puxadas") or 0) for item in sessions)
    return {"sessions": len(sessions), "total_puffs": total_puffs}


def generate_daily_tip(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)
    form = _get_form(user_id)
    progress = _get_progress(user_id)
    hardware = _get_hardware_summary(user_id)

    clean_days = int(progress.get("clean_days") or 0)
    recovery = _recovery_milestones(clean_days)

    tip = _call_groq_chat(
        system_prompt=DAILY_TIP_SYSTEM_PROMPT,
        user_prompt=(
            f"Dias limpo: {clean_days}. Motivacoes: {', '.join(form.get('motivations_to_quit', []))}. "
            f"Gatilhos: {', '.join(form.get('triggers', []))}. Horario que mais fuma: {form.get('time_smoke_the_most')}. "
            f"Cigarros por dia: {form.get('cigarettes_per_day')}. Tipo: {', '.join(form.get('cigarette_type', []))}. "
            f"Ultimas sessoes hardware: {hardware['sessions']} sessoes / {hardware['total_puffs']} puxadas. "
            f"Recuperacao biologica atual: {', '.join(recovery)}"
        ),
    )

    return {
        "user_id": user_id,
        "clean_days": clean_days,
        "tip": tip,
        "biological_recovery": recovery,
    }


def generate_chatbot_reply(token: str, message: str) -> str:
    user_id = _extract_user_id_from_token(token)
    form = _get_form(user_id)
    progress = _get_progress(user_id)

    return _call_groq_chat(
        system_prompt=CHATBOT_SYSTEM_PROMPT,
        user_prompt=(
            f"Mensagem do usuario: {message}. Dias limpo: {progress.get('clean_days', 0)}. "
            f"Gatilhos: {', '.join(form.get('triggers', []))}. "
            f"Motivacoes: {', '.join(form.get('motivations_to_quit', []))}."
        ),
    )
