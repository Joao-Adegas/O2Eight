from fastapi import APIRouter, Header, HTTPException

from api.schemas.onboarding import (
    OnboardingMeResponse,
    OnboardingSubmitRequest,
    OnboardingSubmitResponse,
)
from api.services.onboarding_service import get_my_onboarding, submit_onboarding

router = APIRouter()


@router.get("/me", response_model=OnboardingMeResponse)
def get_onboarding_me(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)

    try:
        return get_my_onboarding(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao buscar onboarding: {str(exc)}")


@router.post("/submit", response_model=OnboardingSubmitResponse)
def submit_onboarding_answers(
    payload: OnboardingSubmitRequest,
    authorization: str = Header(...),
):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)

    try:
        return submit_onboarding(token, payload)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao salvar onboarding: {str(exc)}")
