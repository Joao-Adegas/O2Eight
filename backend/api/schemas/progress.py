# api/schemas/progress.py
from pydantic import BaseModel


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