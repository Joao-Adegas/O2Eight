from pydantic import BaseModel


class ChatMessage(BaseModel):
    uuid: str
    sessao_id: str
    remetente: str
    conteudo: str
    enviado_em: str | None = None
