from pydantic import BaseModel


class HardwareSession(BaseModel):
    uuid: str
    user_id: str
    quantidade_puxadas: int
    inicio_da_sessao: str
    fim_da_sessao: str
    created_at: str | None = None
