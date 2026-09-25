# api/services/ai_service.py
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

from api.prompts.ai_prompts import CHATBOT_SYSTEM_PROMPT, DAILY_TIP_SYSTEM_PROMPT
from api.core.supabase import supabase, supabase_admin

_GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
_GROQ_MODEL_DEFAULT = "openai/gpt-oss-20b"

# Quantas mensagens anteriores da conversa a IA recebe como contexto
CHAT_HISTORY_LIMIT = 10


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token invalido")
    return auth_user.id


def _call_groq_messages(
    messages: list[dict],
    max_tokens: int = 350,
    temperature: float = 0.4,
) -> str:
    """Chama a Groq com uma lista completa de mensagens (system/user/assistant)."""
    api_key = (os.getenv("GROQ_API_KEY") or "").strip()
    if not api_key:
        raise RuntimeError("GROQ_API_KEY nao configurada. Defina a chave para habilitar respostas reais da IA.")

    payload = {
        "model": (os.getenv("GROQ_MODEL") or _GROQ_MODEL_DEFAULT).strip(),
        "temperature": temperature,
        "max_tokens": max_tokens,
        "messages": messages,
    }

    # Modelos gpt-oss "pensam" antes de responder, e isso gasta tokens.
    # Com esforço baixo e uma folga no limite, sobra espaço para a resposta.
    if payload["model"].startswith("openai/gpt-oss"):
        payload["reasoning_effort"] = "low"
        payload["max_tokens"] = max_tokens + 400

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


def _call_groq_chat(system_prompt: str, user_prompt: str) -> str:
    """Atalho para uma pergunta simples (1 system + 1 user). Usado por outros services."""
    return _call_groq_messages(
        [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]
    )


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


def _current_clean_days(user_id: str) -> int:
    # Importação local para evitar dependência circular com progress_service
    from api.services.progress_service import _compute_clean_days, _get_or_create_progress

    clean_days, _, _ = _compute_clean_days(_get_or_create_progress(user_id))
    return clean_days


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


def _join(values) -> str:
    return ", ".join(values or []) or "nao informado"


def generate_daily_tip(token: str) -> dict:
    # Importação local para evitar dependência circular com progress_service
    from api.services.progress_service import _recovery_milestones

    user_id = _extract_user_id_from_token(token)
    form = _get_form(user_id)
    hardware = _get_hardware_summary(user_id)

    clean_days = _current_clean_days(user_id)
    recovery = _recovery_milestones(clean_days)

    tip = _call_groq_chat(
        system_prompt=DAILY_TIP_SYSTEM_PROMPT,
        user_prompt=(
            f"Dias limpo: {clean_days}. Motivacoes: {_join(form.get('motivations_to_quit'))}. "
            f"Gatilhos: {_join(form.get('triggers'))}. Horario que mais fuma: {form.get('time_smoke_the_most')}. "
            f"Cigarros por dia: {form.get('cigarettes_per_day')}. Tipo: {_join(form.get('cigarette_type'))}. "
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


def generate_chatbot_reply(token: str, message: str, history: list[dict] | None = None) -> str:
    """
    Gera a resposta do chatbot.
    history: mensagens anteriores da sessão, da mais antiga para a mais nova,
             no formato {"remetente": "usuario"|"bot", "conteudo": "..."}.
    """
    user_id = _extract_user_id_from_token(token)
    form = _get_form(user_id)
    clean_days = _current_clean_days(user_id)

    context = (
        "Contexto do usuario (use para personalizar, sem repetir literalmente): "
        f"dias sem fumar: {clean_days}; "
        f"gatilhos: {_join(form.get('triggers'))}; "
        f"motivacoes para parar: {_join(form.get('motivations_to_quit'))}; "
        f"horario em que mais fumava: {form.get('time_smoke_the_most') or 'nao informado'}; "
        f"tipo de cigarro: {_join(form.get('cigarette_type'))}."
    )

    messages: list[dict] = [
        {"role": "system", "content": f"{CHATBOT_SYSTEM_PROMPT}\n\n{context}"},
    ]

    for item in (history or [])[-CHAT_HISTORY_LIMIT:]:
        content = (item.get("conteudo") or "").strip()
        if not content:
            continue
        role = "assistant" if item.get("remetente") == "bot" else "user"
        messages.append({"role": role, "content": content})

    messages.append({"role": "user", "content": message})

    return _call_groq_messages(messages, max_tokens=450, temperature=0.5)