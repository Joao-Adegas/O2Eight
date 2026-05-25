from pydantic import BaseModel


class AIDailyTipResponse(BaseModel):
    user_id: str
    clean_days: int
    tip: str
    biological_recovery: list[str]
