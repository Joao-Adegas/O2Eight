from fastapi import APIRouter, Header, HTTPException

from api.schemas.ai import AIDailyTipResponse
from api.services.ai_service import generate_daily_tip

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


@router.get("/daily-tip", response_model=AIDailyTipResponse)
def get_ai_daily_tip(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return generate_daily_tip(token)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao gerar dica diaria: {str(exc)}")
