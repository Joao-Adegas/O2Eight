from fastapi import FastAPI
from api.v1.routes import auth
from api.v1.routes import onboarding
import sys
import os

app = FastAPI()

app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

