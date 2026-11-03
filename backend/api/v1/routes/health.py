# api/v1/routes/health.py
from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from api.core.supabase import supabase_admin  # também carrega o .env

router = APIRouter()

CHECK_TIMEOUT_SECONDS = 5
_GROQ_MODELS_URL = "https://api.groq.com/openai/v1/models"
_GROQ_MODEL_DEFAULT = "openai/gpt-oss-20b"


def _http_get_json(url: str, headers: dict) -> dict:
    request = urllib.request.Request(url, headers={**headers, "User-Agent": "O2Eight-Health/1.0"})
    with urllib.request.urlopen(request, timeout=CHECK_TIMEOUT_SECONDS) as response:
        return json.loads(response.read().decode("utf-8"))


def _check_database() -> str:
    """Faz uma consulta mínima na tabela users."""
    supabase_admin.table("users").select("id").limit(1).execute()
    return "Consulta ao banco respondeu"


def _check_sso() -> str:
    """Consulta o endpoint de saúde do Supabase Auth (login Google e e-mail)."""
    url = (os.getenv("SUPABASE_URL") or "").rstrip("/")
    key = os.getenv("SUPABASE_ANON_KEY") or ""
    if not url or not key:
        raise RuntimeError("SUPABASE_URL ou SUPABASE_ANON_KEY nao configurada")
    data = _http_get_json(f"{url}/auth/v1/health", {"apikey": key})
    return f"Supabase Auth respondeu ({data.get('name', 'GoTrue')})"


def _check_ai() -> str:
    """
    Lista os modelos da Groq: valida a chave e se o modelo configurado existe,
    sem gerar texto (não gasta cota).
    """
    key = (os.getenv("GROQ_API_KEY") or "").strip()
    if not key:
        raise RuntimeError("GROQ_API_KEY nao configurada")
    model = (os.getenv("GROQ_MODEL") or _GROQ_MODEL_DEFAULT).strip()

    data = _http_get_json(_GROQ_MODELS_URL, {"Authorization": f"Bearer {key}"})
    available = {m.get("id") for m in data.get("data", [])}
    if model not in available:
        raise RuntimeError(f"Modelo '{model}' nao esta disponivel para esta chave")
    return f"Groq respondeu; modelo {model} disponivel"


def _run(name: str, check) -> dict:
    started = time.perf_counter()
    try:
        detail = check()
        status = "ok"
    except urllib.error.HTTPError as exc:
        status, detail = "error", f"HTTP {exc.code}"
    except urllib.error.URLError as exc:
        status, detail = "error", f"Sem conexao: {exc.reason}"
    except TimeoutError:
        status, detail = "error", f"Sem resposta em {CHECK_TIMEOUT_SECONDS}s"
    except Exception as exc:
        # Mensagem curta: a rota é pública e não deve expor detalhes internos
        status, detail = "error", str(exc)[:160]
    return {
        "name": name,
        "status": status,
        "latency_ms": round((time.perf_counter() - started) * 1000),
        "detail": detail,
    }


@router.get("/live")
def health_live():
    """Só confirma que a API está no ar. Use esta no health check do Render."""
    return {"status": "ok"}


@router.get("")
def health():
    """Verifica banco, SSO (Supabase Auth) e IA (Groq) em paralelo."""
    checks = {"database": _check_database, "sso": _check_sso, "ai": _check_ai}

    with ThreadPoolExecutor(max_workers=len(checks)) as pool:
        futures = {name: pool.submit(_run, name, fn) for name, fn in checks.items()}
        results = {name: future.result() for name, future in futures.items()}

    healthy = all(r["status"] == "ok" for r in results.values())
    body = {
        "status": "ok" if healthy else "degraded",
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "checks": {
            name: {k: v for k, v in r.items() if k != "name"} for name, r in results.items()
        },
    }
    return JSONResponse(status_code=200 if healthy else 503, content=body)