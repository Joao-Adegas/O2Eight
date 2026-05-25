from fastapi import APIRouter, Header, HTTPException

from api.schemas.onboarding import (
    FormResponse,
    FormSavingsResponse,
    FormUpsertRequest,
)
from api.services.onboarding_service import get_form_savings, get_my_form, upsert_form

router = APIRouter()


@router.get("/me", response_model=FormResponse)
def get_form_me(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)

    try:
        return get_my_form(token)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao buscar formulario: {str(exc)}")


@router.post("/submit", response_model=FormResponse)
def submit_form(
    payload: FormUpsertRequest,
    authorization: str = Header(...),
):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)

    try:
        return upsert_form(token, payload)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao salvar formulario: {str(exc)}")


@router.get("/savings", response_model=FormSavingsResponse)
def get_form_money_savings(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")

    token = authorization.replace("Bearer ", "", 1)
    try:
        return get_form_savings(token)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao calcular economia: {str(exc)}")
