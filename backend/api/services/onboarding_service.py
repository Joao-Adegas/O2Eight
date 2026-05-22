from api.core.supabase import supabase, supabase_admin
from api.schemas.onboarding import OnboardingSubmitRequest
import unicodedata


_CONSUMPTION_BY_OPTION = {
    "a": 3,
    "b": 8,
    "c": 12,
    "d": 16,
}

_CONSUMPTION_BY_TEXT = {
    "entre 1 e 5": 3,
    "entre 5 e 10": 8,
    "+ 10 cigarros": 12,
    "+ 15 cigarros": 16,
}


def _normalize_text(value: str) -> str:
    no_accents = unicodedata.normalize("NFKD", value)
    ascii_only = no_accents.encode("ascii", "ignore").decode("ascii")
    return " ".join(ascii_only.lower().split())


def _extract_user_id_from_token(token: str) -> str:
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user
    if not auth_user:
        raise ValueError("Token inválido")
    return auth_user.id


def _extract_daily_consumption(payload: OnboardingSubmitRequest) -> int | None:
    for response in payload.responses:
        if response.question_key != "cigarros_por_dia":
            continue

        if not response.answers:
            return None

        option = _normalize_text(response.answers[0])
        if option in _CONSUMPTION_BY_OPTION:
            return _CONSUMPTION_BY_OPTION[option]

        if option in _CONSUMPTION_BY_TEXT:
            return _CONSUMPTION_BY_TEXT[option]

        # Permite enviar o valor numérico diretamente pelo app.
        only_digits = "".join(char for char in option if char.isdigit())
        if only_digits:
            return int(only_digits)

    return None


def _extract_pack_price(payload: OnboardingSubmitRequest) -> float | None:
    if payload.pack_price is not None:
        return payload.pack_price

    for response in payload.responses:
        if response.question_key != "preco_maco":
            continue

        if not response.answers:
            return None

        # Aceita formatos como "20", "20.50", "R$ 20,50".
        raw_value = response.answers[0].strip().replace("R$", "").replace(" ", "")
        normalized = raw_value.replace(",", ".")

        allowed_chars = {".", "-"}
        sanitized = "".join(char for char in normalized if char.isdigit() or char in allowed_chars)
        if not sanitized:
            return None

        try:
            value = float(sanitized)
            return value if value >= 0 else None
        except ValueError:
            return None

    return None


def submit_onboarding(token: str, payload: OnboardingSubmitRequest) -> dict:
    user_id = _extract_user_id_from_token(token)

    # Garante o perfil mínimo em public.users antes de inserir no onboarding.
    supabase_admin.table("users").upsert({"id": user_id}, on_conflict="id").execute()

    response_rows: list[dict] = []
    for response in payload.responses:
        for answer in response.answers:
            response_rows.append(
                {
                    "user_id": user_id,
                    "question_key": response.question_key,
                    "answer_text": answer,
                }
            )

    # Mantém apenas o onboarding mais recente do usuário.
    supabase_admin.table("onboarding_responses").delete().eq("user_id", user_id).execute()

    if response_rows:
        supabase_admin.table("onboarding_responses").insert(response_rows).execute()

    user_update: dict = {}
    daily_consumption = _extract_daily_consumption(payload)
    if daily_consumption is not None:
        user_update["daily_cigarette_consumption"] = daily_consumption

    pack_price = _extract_pack_price(payload)
    if pack_price is not None:
        user_update["pack_price"] = pack_price

    if payload.preferred_ai_tone is not None:
        user_update["preferred_ai_tone"] = payload.preferred_ai_tone.strip() or None

    if user_update:
        supabase_admin.table("users").update(user_update).eq("id", user_id).execute()

    return {
        "user_id": user_id,
        "saved_answers": len(response_rows),
        "daily_cigarette_consumption": user_update.get("daily_cigarette_consumption"),
        "pack_price": user_update.get("pack_price"),
        "preferred_ai_tone": user_update.get("preferred_ai_tone"),
    }


def get_my_onboarding(token: str) -> dict:
    user_id = _extract_user_id_from_token(token)

    # Evita inconsistência quando o usuário autenticou, mas o perfil ainda não foi criado.
    supabase_admin.table("users").upsert({"id": user_id}, on_conflict="id").execute()

    answers_response = (
        supabase_admin.table("onboarding_responses")
        .select("question_key, answer_text, answered_at")
        .eq("user_id", user_id)
        .order("answered_at", desc=False)
        .execute()
    )

    grouped_answers: dict[str, list[str]] = {}
    for row in answers_response.data or []:
        question_key = row.get("question_key")
        answer_text = row.get("answer_text")
        if not question_key or answer_text is None:
            continue
        grouped_answers.setdefault(question_key, []).append(answer_text)

    profile_response = (
        supabase_admin.table("users")
        .select("daily_cigarette_consumption, pack_price, preferred_ai_tone")
        .eq("id", user_id)
        .limit(1)
        .execute()
    )

    profile = (profile_response.data or [{}])[0]

    return {
        "user_id": user_id,
        "responses": [
            {"question_key": key, "answers": values}
            for key, values in grouped_answers.items()
        ],
        "daily_cigarette_consumption": profile.get("daily_cigarette_consumption"),
        "pack_price": profile.get("pack_price"),
        "preferred_ai_tone": profile.get("preferred_ai_tone"),
    }
