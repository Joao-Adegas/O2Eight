import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

_missing = [name for name, value in {
    "SUPABASE_URL": SUPABASE_URL,
    "SUPABASE_ANON_KEY": SUPABASE_ANON_KEY,
    "SUPABASE_SERVICE_ROLE_KEY": SUPABASE_SERVICE_ROLE_KEY,
}.items() if not value]
if _missing:
    raise RuntimeError(f"Variaveis faltando no .env: {', '.join(_missing)}")

# Cliente publico: validar tokens (auth.get_user)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

# Cliente admin: operacoes no banco (passa pelo RLS). Nunca expor ao app.
supabase_admin: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)