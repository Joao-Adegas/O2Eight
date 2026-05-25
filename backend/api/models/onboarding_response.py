from pydantic import BaseModel


class Form(BaseModel):
    uuid: str
    user_uuid: str
    smoking_time: str
    cigarettes_per_day: str
    cigarette_type: list[str]
    motivations_to_quit: list[str]
    pack_price: float
    triggers: list[str]
    family_health_history: list[str]
    time_smoke_the_most: str
    created_at: str | None = None
    updated_at: str | None = None
