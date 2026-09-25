from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.v1.routes import auth, onboarding, ai, hardware, progress, community, chat

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
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