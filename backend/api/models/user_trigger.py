from pydantic import BaseModel


class UserTrigger(BaseModel):
    id: str
    user_id: str
    happened_at: str
    trigger_type: str
    intensity: int
