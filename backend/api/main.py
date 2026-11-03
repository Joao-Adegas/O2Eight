# api/main.py
import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.v1.routes import auth, onboarding, ai, hardware, progress, community, chat, health

load_dotenv()

app = FastAPI(title="O2Eight API")

# Endereços onde a versão web do app está publicada, separados por vírgula.
# Ex.: CORS_ORIGINS=https://o2eight-app.web.app
# O app Android não precisa disso: CORS é uma regra só de navegador.
_extra_origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_extra_origins,
    # Desenvolvimento: libera qualquer porta do localhost (Flutter Web)
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(onboarding.router, prefix="/form", tags=["Form"])
app.include_router(hardware.router, prefix="/hardware", tags=["Hardware"])
app.include_router(progress.router, prefix="/progress", tags=["Progress"])
app.include_router(community.router, prefix="/community", tags=["Community"])
app.include_router(chat.router, prefix="/chat", tags=["Chatbot"])
app.include_router(ai.router, prefix="/ai", tags=["AI"])
app.include_router(health.router, prefix="/health", tags=["Health"])


@app.api_route("/", methods=["GET", "HEAD"], include_in_schema=False)
def root():
    return {"name": "O2Eight API", "docs": "/docs", "health": "/health"}