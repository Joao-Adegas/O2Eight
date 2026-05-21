from supabase import create_client, Client
from dotenv import load_dotenv
import os

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_KEY")
supabase_service_role_key = (
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    or os.getenv("SERVICE_ROLE_KEY")
    or os.getenv("service_role")
)

supabase: Client = create_client(
    supabase_url,
    supabase_key
)

supabase_admin: Client = create_client(
    supabase_url,
    supabase_service_role_key or supabase_key
)