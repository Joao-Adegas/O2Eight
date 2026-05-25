from typing import Literal

from pydantic import BaseModel, Field, field_validator

SmokingTime = Literal["+ de 1 ano", "1 dia a 1 semana", "1 mes a 1 ano"]
CigarettesPerDay = Literal[
    "Entre 1 e 5",
    "Entre 5 e 10",
    "+ 10 cigarros",
    "+ 15 cigarros",
    "+ 20 cigarros",
]
TimeSmokeMost = Literal["De manha", "De tarde", "De noite"]


class FormUpsertRequest(BaseModel):
    smoking_time: SmokingTime
    cigarettes_per_day: CigarettesPerDay
    cigarette_type: list[str] = Field(min_length=1)
    motivations_to_quit: list[str] = Field(min_length=1)
    pack_price: float = Field(ge=0)
    triggers: list[str] = Field(min_length=1)
    family_health_history: list[str] = Field(min_length=1)
    time_smoke_the_most: TimeSmokeMost

    @field_validator(
        "cigarette_type",
        "motivations_to_quit",
        "triggers",
        "family_health_history",
    )
    @classmethod
    def clean_list_values(cls, value: list[str]) -> list[str]:
        cleaned = [item.strip() for item in value if item and item.strip()]
        if not cleaned:
            raise ValueError("A lista deve conter pelo menos um item")
        return cleaned


class FormResponse(BaseModel):
    uuid: str
    user_uuid: str
    smoking_time: SmokingTime
    cigarettes_per_day: CigarettesPerDay
    cigarette_type: list[str]
    motivations_to_quit: list[str]
    pack_price: float
    triggers: list[str]
    family_health_history: list[str]
    time_smoke_the_most: TimeSmokeMost
    created_at: str | None = None
    updated_at: str | None = None


class FormSavingsResponse(BaseModel):
    user_uuid: str
    clean_days: int
    estimated_saved_money: float
