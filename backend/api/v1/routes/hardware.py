from fastapi import APIRouter, Header, HTTPException

from api.schemas.hardware import HardwareSessionCreateRequest, HardwareSessionResponse
from api.services.hardware_service import create_hardware_session, list_my_hardware_sessions

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


@router.post("/sessions", response_model=HardwareSessionResponse)
def post_hardware_session(payload: HardwareSessionCreateRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return create_hardware_session(token, payload.model_dump())
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao registrar sessao do hardware: {str(exc)}")


@router.get("/sessions/me", response_model=list[HardwareSessionResponse])
def get_my_hardware_sessions(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return list_my_hardware_sessions(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao listar sessoes do hardware: {str(exc)}")
