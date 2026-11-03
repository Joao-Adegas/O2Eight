# api/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.v1.routes import auth, onboarding, ai, hardware, progress, community, chat, health

app = FastAPI(title="O2Eight API")

app.add_middleware(
    CORSMiddleware,
    # Em desenvolvimento: libera qualquer porta do localhost (Flutter Web).
    # Quando a versão web do app for publicada, troque por allow_origins=["https://endereco-do-app"].
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


@app.get("/", include_in_schema=False)
def root():
    return {"name": "O2Eight API", "docs": "/docs", "health": "/health"}