from fastapi import FastAPI
from api.v1.routes import auth
import sys
import os

app = FastAPI()

app.include_router(auth.router, prefix="/auth", tags=["Auth"])
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

"""
Run this command to create __pycache__ in all folders:

cd backend
$folders = @("api", "api/core", "api/models", "api/schemas", "api/services", "api/repositories", "api/v1", "api/v1/routes")
foreach ($f in $folders) { New-Item -Path "$f/__init__.py" -Force }
"""