from pydantic import BaseModel


class OnboardingResponse(BaseModel):
    id: str
    user_id: str
    question_key: str
    answer_text: str
    answered_at: str | None = None
