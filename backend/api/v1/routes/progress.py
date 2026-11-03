# api/v1/routes/progress.py
from fastapi import APIRouter, Header, HTTPException

from api.schemas.progress import (
    BiologicalRecoveryResponse,
    CravingCreateRequest,
    CravingResultResponse,
    ProgressDashboardResponse,
    UserProgressResponse,
)
from api.services.progress_service import (
    check_in_clean_day,
    get_biological_recovery,
    get_dashboard,
    get_my_progress,
    mark_smoked,
    record_craving,
)

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


@router.get("/me", response_model=UserProgressResponse)
def get_progress_me(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return get_my_progress(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao buscar progresso: {str(exc)}")


@router.get("/dashboard", response_model=ProgressDashboardResponse)
def get_progress_dashboard(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return get_dashboard(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao montar dashboard: {str(exc)}")


@router.post("/check-in", response_model=UserProgressResponse)
def progress_check_in(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return check_in_clean_day(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao atualizar check-in: {str(exc)}")


@router.post("/mark-smoked", response_model=UserProgressResponse)
def progress_mark_smoked(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return mark_smoked(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao marcar recaida: {str(exc)}")


@router.get("/recovery", response_model=BiologicalRecoveryResponse)
def progress_biological_recovery(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return get_biological_recovery(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao gerar recuperacao biologica: {str(exc)}")


@router.post("/cravings", response_model=CravingResultResponse)
def progress_record_craving(payload: CravingCreateRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return record_craving(
            token,
            payload.outcome,
            payload.started_at,
            payload.duration_seconds,
        )
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao registrar vontade: {str(exc)}")