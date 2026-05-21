from fastapi import FastAPI, HTTPException, Header
from supabase import create_client, Client
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI()

supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

# 1. Gera a URL de login com Google (redireciona o usuário)
@app.get("/auth/google")
def login_google():
    response = supabase.auth.sign_in_with_oauth({
        "provider": "google",
        "options": {
            "redirect_to": "http://localhost:8000/auth/callback"
        }
    })
    return {"url": response.url}  # frontend redireciona para essa URL


# 2. Callback — após o login, Supabase redireciona aqui com o token
@app.get("/auth/callback")
def auth_callback(code: str):
    # O Supabase lida com o exchange do code automaticamente via SDK
    return {"message": "Login feito! Use o token retornado pelo Supabase no frontend."}


# 3. Rota protegida — valida o JWT do usuário logado
@app.get("/me")
def get_me(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    try:
        user = supabase.auth.get_user(token)
        return {"user": user.user}
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido")