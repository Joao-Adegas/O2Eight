from fastapi import FastAPI
from api.v1.routes import auth
from api.v1.routes import onboarding
from api.v1.routes import ai
from api.v1.routes import hardware
from api.v1.routes import progress
from api.v1.routes import community
from api.v1.routes import chat
import sys
import os

app = FastAPI()

app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(onboarding.router, prefix="/form", tags=["Form"])
app.include_router(hardware.router, prefix="/hardware", tags=["Hardware"])
app.include_router(progress.router, prefix="/progress", tags=["Progress"])
app.include_router(community.router, prefix="/community", tags=["Community"])
app.include_router(chat.router, prefix="/chat", tags=["Chatbot"])
app.include_router(ai.router, prefix="/ai", tags=["AI"])
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

