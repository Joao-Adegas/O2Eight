from pydantic import BaseModel


class UserProgress(BaseModel):
    uuid: str
    user_id: str
    clean_days: int
    last_smoked_at: str | None = None
    created_at: str | None = None
    updated_at: str | None = None
