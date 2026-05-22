from pydantic import BaseModel, Field


class PredictivePattern(BaseModel):
    weekday: int
    hour: int
    puffs_count: int
    confidence_score: float


class PredictiveAnalyzeResponse(BaseModel):
    user_id: str
    evaluated_puffs: int
    patterns: list[PredictivePattern]


class PredictiveSimulatePuffsRequest(BaseModel):
    total_puffs: int = Field(default=120, ge=10, le=5000)
    days_back: int = Field(default=21, ge=3, le=90)
    peak_weekday: int = Field(default=1, ge=0, le=6)
    peak_hour: int = Field(default=14, ge=0, le=23)
    peak_ratio: float = Field(default=0.65, ge=0.2, le=0.95)
    clear_existing: bool = False


class PredictiveSimulatePuffsResponse(BaseModel):
    user_id: str
    inserted_puffs: int
    peak_weekday: int
    peak_hour: int
    days_back: int


class PredictiveAlertGenerateRequest(BaseModel):
    lead_minutes: int = Field(default=15, ge=10, le=15)


class PredictiveAlertGenerateResponse(BaseModel):
    alert_id: str
    user_id: str
    predicted_at: str
    sent_at: str
    suggestion_text: str


class PredictiveAlertEvaluateRequest(BaseModel):
    window_minutes: int = Field(default=30, ge=10, le=120)


class PredictiveAlertEvaluateResponse(BaseModel):
    alert_id: str
    user_id: str
    result_status: str
    puffs_in_window: int


class BehavioralQuickSupportRequest(BaseModel):
    message: str = Field(min_length=3, max_length=1500)


class BehavioralQuickSupportResponse(BaseModel):
    session_id: str
    user_id: str
    user_message: str
    ai_message: str
    ai_tone_used: str
    abstinence_hours: float | None = None
    estimated_saved_money: float | None = None


class BehavioralMessageRequest(BaseModel):
    session_id: str
    message: str = Field(min_length=1, max_length=1500)


class BehavioralMessageResponse(BaseModel):
    session_id: str
    ai_message: str
    ai_tone_used: str
