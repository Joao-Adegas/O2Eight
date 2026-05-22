from pydantic import BaseModel, Field, field_validator
from typing import Literal

QuestionKey = Literal[
    "tempo_fumante",
    "cigarros_por_dia",
    "preco_maco",
    "tipo_cigarro",
    "historico_familiar_saude",
    "horario_que_mais_fuma",
    "motivacao_parar",
    "gatilho_emocional",
]


class OnboardingAnswerInput(BaseModel):
    question_key: QuestionKey
    answers: list[str] = Field(min_length=1)

    @field_validator("answers")
    @classmethod
    def normalize_answers(cls, value: list[str]) -> list[str]:
        cleaned = [item.strip() for item in value if item and item.strip()]
        if not cleaned:
            raise ValueError("answers deve conter ao menos uma resposta válida")
        return cleaned


class OnboardingSubmitRequest(BaseModel):
    responses: list[OnboardingAnswerInput] = Field(min_length=1)
    pack_price: float | None = Field(default=None, ge=0)
    preferred_ai_tone: str | None = Field(default=None, max_length=50)


class OnboardingSubmitResponse(BaseModel):
    user_id: str
    saved_answers: int
    daily_cigarette_consumption: int | None = None
    pack_price: float | None = None
    preferred_ai_tone: str | None = None


class OnboardingAnswerGroup(BaseModel):
    question_key: QuestionKey
    answers: list[str]


class OnboardingMeResponse(BaseModel):
    user_id: str
    responses: list[OnboardingAnswerGroup]
    daily_cigarette_consumption: int | None = None
    pack_price: float | None = None
    preferred_ai_tone: str | None = None
