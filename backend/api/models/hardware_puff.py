from pydantic import BaseModel


class HardwarePuff(BaseModel):
    id: int
    user_id: str
    happened_at: str
