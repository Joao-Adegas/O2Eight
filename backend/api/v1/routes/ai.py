from fastapi import APIRouter, Header, HTTPException

from api.schemas.ai import (
    BehavioralMessageRequest,
    BehavioralMessageResponse,
    BehavioralQuickSupportRequest,
    BehavioralQuickSupportResponse,
    PredictiveAlertEvaluateRequest,
    PredictiveAlertEvaluateResponse,
    PredictiveAlertGenerateRequest,
    PredictiveAlertGenerateResponse,
    PredictiveAnalyzeResponse,
    PredictiveSimulatePuffsRequest,
    PredictiveSimulatePuffsResponse,
)
from api.services.ai_service import (
    analyze_predictive_patterns,
    evaluate_predictive_alert,
    generate_predictive_alert,
    send_behavioral_message,
    simulate_hardware_puffs,
    start_behavioral_quick_support,
)

router = APIRouter()


def _bearer_to_token(authorization: str) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=400, detail="Authorization deve ser 'Bearer <access_token>'")
    return authorization.replace("Bearer ", "", 1)


@router.post("/predictive/analyze", response_model=PredictiveAnalyzeResponse)
def predictive_analyze(authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return analyze_predictive_patterns(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha na análise preditiva: {str(exc)}")


@router.post("/predictive/simulate-puffs", response_model=PredictiveSimulatePuffsResponse)
def predictive_simulate_puffs(payload: PredictiveSimulatePuffsRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return simulate_hardware_puffs(
            token=token,
            total_puffs=payload.total_puffs,
            days_back=payload.days_back,
            peak_weekday=payload.peak_weekday,
            peak_hour=payload.peak_hour,
            peak_ratio=payload.peak_ratio,
            clear_existing=payload.clear_existing,
        )
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao simular tragadas: {str(exc)}")


@router.post("/predictive/alerts/generate", response_model=PredictiveAlertGenerateResponse)
def predictive_generate_alert(payload: PredictiveAlertGenerateRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return generate_predictive_alert(token, payload.lead_minutes)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao gerar alerta preditivo: {str(exc)}")


@router.post("/predictive/alerts/{alert_id}/evaluate", response_model=PredictiveAlertEvaluateResponse)
def predictive_evaluate_alert(
    alert_id: str,
    payload: PredictiveAlertEvaluateRequest,
    authorization: str = Header(...),
):
    token = _bearer_to_token(authorization)
    try:
        return evaluate_predictive_alert(token, alert_id, payload.window_minutes)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao avaliar alerta: {str(exc)}")


@router.post("/behavioral/quick-support", response_model=BehavioralQuickSupportResponse)
def behavioral_quick_support(payload: BehavioralQuickSupportRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return start_behavioral_quick_support(token, payload.message)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha no suporte comportamental: {str(exc)}")


@router.post("/behavioral/message", response_model=BehavioralMessageResponse)
def behavioral_send_message(payload: BehavioralMessageRequest, authorization: str = Header(...)):
    token = _bearer_to_token(authorization)
    try:
        return send_behavioral_message(token, payload.session_id, payload.message)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Falha ao enviar mensagem para IA: {str(exc)}")
