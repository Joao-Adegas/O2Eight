from pydantic import BaseModel, Field


class HardwareSessionCreateRequest(BaseModel):
    user_id: str
    quantidade_puxadas: int = Field(ge=0)
    inicio_da_sessao: str
    fim_da_sessao: str


class HardwareSessionResponse(BaseModel):
    uuid: str
    user_id: str
    quantidade_puxadas: int
    inicio_da_sessao: str
    fim_da_sessao: str
    created_at: str | None = None
