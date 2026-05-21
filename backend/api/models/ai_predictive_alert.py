from pydantic import BaseModel


class AIPredictiveAlert(BaseModel):
    id: str
    user_id: str
    predicted_at: str
    sent_at: str | None = None
    suggestion_text: str | None = None
    result_status: str | None = None
