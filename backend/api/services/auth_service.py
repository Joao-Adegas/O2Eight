from api.core.supabase import supabase, supabase_admin

def get_google_oauth_url(redirect_to: str) -> str:
    response = supabase.auth.sign_in_with_oauth({
        "provider": "google",
        "options": {
            "redirect_to": redirect_to
        }
    })
    return response.url

def get_current_user(token: str):
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user

    # Keep SSO behavior intact even if the profile row does not exist yet.
    merged_user = {
        "id": auth_user.id,
        "email": auth_user.email,
        "phone": auth_user.phone,
    }

    try:
        profile_response = (
            supabase_admin.table("users")
            .select("name, created_at, daily_cigarette_consumption, pack_price, preferred_ai_tone")
            .eq("id", auth_user.id)
            .limit(1)
            .execute()
        )

        if profile_response.data:
            merged_user.update(profile_response.data[0])
    except Exception:
        # Authentication should continue to work even if profile lookup fails.
        pass

    return merged_user


def register_sso_user(token: str):
    auth_response = supabase.auth.get_user(token)
    auth_user = auth_response.user

    user_metadata = getattr(auth_user, "user_metadata", None) or {}
    full_name = user_metadata.get("full_name") or user_metadata.get("name")

    payload = {"id": auth_user.id}
    if full_name:
        payload["name"] = full_name

    supabase_admin.table("users").upsert(payload, on_conflict="id").execute()

    return get_current_user(token)


def exchange_callback_code_for_session(code: str):
    response = supabase.auth.exchange_code_for_session({"auth_code": code})

    if not response or not response.session:
        raise ValueError("Falha ao trocar o code por sessão de autenticação")

    return {
        "access_token": response.session.access_token,
        "refresh_token": response.session.refresh_token,
        "token_type": response.session.token_type,
        "expires_in": response.session.expires_in,
        "user_id": response.user.id if response.user else None,
        "email": response.user.email if response.user else None,
    }