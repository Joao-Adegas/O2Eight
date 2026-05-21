from api.core.supabase import supabase

def get_google_oauth_url(redirect_to: str) -> str:
    response = supabase.auth.sign_in_with_oauth({
        "provider": "google",
        "options": {
            "redirect_to": redirect_to
        }
    })
    return response.url

def get_current_user(token: str):
    return supabase.auth.get_user(token)