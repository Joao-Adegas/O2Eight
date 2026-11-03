# api/schemas/progress.py
from typing import Literal

from pydantic import BaseModel, Field

CravingOutcome = Literal["overcome", "smoked", "abandoned"]


class UserProgressResponse(BaseModel):
    uuid: str
    user_id: str
    clean_days: int
    last_smoked_at: str | None = None
    updated_at: str | None = None


class BiologicalRecoveryResponse(BaseModel):
    user_id: str
    clean_days: int
    recuperation: list[str]


class ProgressDashboardResponse(BaseModel):
    user_id: str
    clean_days: int
    clean_since: str
    daily_cost: float
    estimated_saved_money: float
    has_form: bool


class CravingCreateRequest(BaseModel):
    # overcome = a vontade passou; smoked = fumou; abandoned = saiu sem responder
    outcome: CravingOutcome
    started_at: str | None = None
    duration_seconds: int = Field(default=0, ge=0)


class CravingResultResponse(BaseModel):
    outcome: CravingOutcome
    overcome_total: int  # quantas vontades o usuário já venceu
    previous_clean_days: int | None = None  # preenchido quando outcome = smoked