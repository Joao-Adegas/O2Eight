# O2Eight Backend API - Documentacao de Rotas

## 1) Visao Geral

Base URL local:
- http://localhost:8000

Formato de autenticacao (rotas protegidas):
- Header: Authorization: Bearer <access_token>

Formato padrao de erro (FastAPI):
```json
{
  "detail": "mensagem de erro"
}
```

## 2) Auth

### GET /auth/google
Objetivo:
- Gerar URL de login OAuth Google.

Body de entrada:
- Nao possui.

Exemplo de saida:
```json
{
  "url": "https://<supabase-auth-url>"
}
```

Campos da saida:
- url: URL que o frontend deve abrir para iniciar login com Google.

---

### GET /auth/callback?code=...
Objetivo:
- Trocar o code do OAuth por sessao (tokens).

Body de entrada:
- Nao possui.
- Parametro de query obrigatorio: code.

Exemplo de saida:
```json
{
  "message": "Login realizado com sucesso! Use o access_token para /auth/register-sso.",
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "email": "usuario@email.com"
}
```

Campos da saida:
- message: instrucoes do proximo passo no fluxo de login.
- access_token: token JWT para chamar rotas protegidas.
- refresh_token: token usado para renovar sessao.
- token_type: tipo do token (normalmente bearer).
- expires_in: tempo de expiracao do access_token, em segundos.
- user_id: id do usuario autenticado.
- email: email do usuario autenticado.

---

### POST /auth/register-sso
Objetivo:
- Garantir/sincronizar a linha do usuario em public.users apos login SSO.

Headers:
- Authorization: Bearer <access_token>

Body de entrada:
- Nao possui.

Exemplo de saida:
```json
{
  "id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "email": "usuario@email.com",
  "phone": null,
  "name": "Nome Usuario",
  "created_at": "2026-05-22T01:10:52.000Z",
  "daily_cigarette_consumption": 8,
  "pack_price": 20.5,
  "preferred_ai_tone": "empatico"
}
```

Campos da saida:
- id: id unico do usuario (igual ao auth.users).
- email: email do usuario.
- phone: telefone (se existir no provedor auth).
- name: nome do perfil do usuario.
- created_at: data de criacao do perfil em public.users.
- daily_cigarette_consumption: consumo diario derivado do onboarding.
- pack_price: preco do maco.
- preferred_ai_tone: tom de comunicacao preferido da IA.

---

### GET /auth/me
Objetivo:
- Retornar dados do usuario autenticado (auth + perfil).

Headers:
- Authorization: Bearer <access_token>

Body de entrada:
- Nao possui.

Exemplo de saida:
```json
{
  "id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "email": "usuario@email.com",
  "phone": null,
  "name": "Nome Usuario",
  "created_at": "2026-05-22T01:10:52.000Z",
  "daily_cigarette_consumption": 8,
  "pack_price": 20.5,
  "preferred_ai_tone": "energetico"
}
```

Campos da saida:
- Mesmo significado de /auth/register-sso.

## 3) Onboarding

Question keys aceitas em responses:
- tempo_fumante
- cigarros_por_dia
- preco_maco
- tipo_cigarro
- historico_familiar_saude
- horario_que_mais_fuma
- motivacao_parar
- gatilho_emocional

### POST /onboarding/submit
Objetivo:
- Salvar respostas detalhadas do onboarding.
- Atualizar campos derivados no usuario:
  - daily_cigarette_consumption
  - pack_price
  - preferred_ai_tone

Headers:
- Authorization: Bearer <access_token>

Exemplo de body:
```json
{
  "responses": [
    { "question_key": "tempo_fumante", "answers": ["+ de 1 ano"] },
    { "question_key": "cigarros_por_dia", "answers": ["Entre 5 e 10"] },
    { "question_key": "preco_maco", "answers": ["R$ 20,50"] },
    { "question_key": "tipo_cigarro", "answers": ["Cigarro"] },
    { "question_key": "historico_familiar_saude", "answers": ["Nao possuo"] },
    { "question_key": "horario_que_mais_fuma", "answers": ["De noite"] },
    { "question_key": "motivacao_parar", "answers": ["Saude"] },
    { "question_key": "gatilho_emocional", "answers": ["Ansiedade", "Estresse"] }
  ],
  "preferred_ai_tone": "empatico"
}
```

Campos do body:
- responses: lista com respostas por pergunta.
- responses[].question_key: identificador da pergunta.
- responses[].answers: lista de respostas da pergunta (permite multipla selecao).
- pack_price: opcional legado; se enviado, tambem atualiza users.pack_price.
- preferred_ai_tone: tom preferido da IA (ex.: empatico, energetico).

Exemplo de saida:
```json
{
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "saved_answers": 9,
  "daily_cigarette_consumption": 8,
  "pack_price": 20.5,
  "preferred_ai_tone": "empatico"
}
```

Campos da saida:
- user_id: usuario dono do onboarding salvo.
- saved_answers: total de linhas gravadas em onboarding_responses.
- daily_cigarette_consumption: valor final calculado e salvo em users.
- pack_price: preco de maco final salvo em users.
- preferred_ai_tone: tom salvo em users.

---

### GET /onboarding/me
Objetivo:
- Retornar onboarding atual do usuario e campos derivados do perfil.

Headers:
- Authorization: Bearer <access_token>

Body de entrada:
- Nao possui.

Exemplo de saida:
```json
{
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "responses": [
    { "question_key": "tempo_fumante", "answers": ["+ de 1 ano"] },
    { "question_key": "cigarros_por_dia", "answers": ["Entre 5 e 10"] },
    { "question_key": "motivacao_parar", "answers": ["Saude"] },
    { "question_key": "gatilho_emocional", "answers": ["Ansiedade", "Estresse"] }
  ],
  "daily_cigarette_consumption": 8,
  "pack_price": 20.5,
  "preferred_ai_tone": "empatico"
}
```

Campos da saida:
- user_id: id do usuario autenticado.
- responses: respostas agrupadas por question_key.
- responses[].question_key: identificador da pergunta.
- responses[].answers: respostas registradas para essa pergunta.
- daily_cigarette_consumption: consumo diario salvo no perfil.
- pack_price: preco do maco salvo no perfil.
- preferred_ai_tone: tom da IA salvo no perfil.

## 4) IA Preditiva

### POST /ai/predictive/analyze
Objetivo:
- Analisar tragadas em hardware_puffs (ultimos 30 dias).
- Detectar padroes por dia da semana e hora.

Headers:
- Authorization: Bearer <access_token>

Body de entrada:
- Nao possui.

Exemplo de saida:
```json
{
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "evaluated_puffs": 142,
  "patterns": [
    {
      "weekday": 1,
      "hour": 14,
      "puffs_count": 55,
      "confidence_score": 0.387
    },
    {
      "weekday": 4,
      "hour": 18,
      "puffs_count": 20,
      "confidence_score": 0.141
    }
  ]
}
```

Campos da saida:
- user_id: usuario analisado.
- evaluated_puffs: total de tragadas consideradas na analise.
- patterns: lista de padroes encontrados.
- patterns[].weekday: dia da semana (0=segunda ... 6=domingo).
- patterns[].hour: hora do pico (0 a 23).
- patterns[].puffs_count: quantidade de tragadas naquele slot.
- patterns[].confidence_score: peso relativo do padrao no total analisado.

---

### POST /ai/predictive/simulate-puffs
Objetivo:
- Inserir tragadas sintéticas para testar analise preditiva sem IoT.

Headers:
- Authorization: Bearer <access_token>

Exemplo de body:
```json
{
  "total_puffs": 140,
  "days_back": 21,
  "peak_weekday": 1,
  "peak_hour": 14,
  "peak_ratio": 0.7,
  "clear_existing": true
}
```

Campos do body:
- total_puffs: total de registros que serao inseridos.
- days_back: janela de dias para distribuir as tragadas.
- peak_weekday: dia principal de pico (0=segunda ... 6=domingo).
- peak_hour: hora principal de pico (0-23).
- peak_ratio: percentual das tragadas concentradas no pico.
- clear_existing: se true, remove tragadas existentes do usuario antes de inserir.

Exemplo de saida:
```json
{
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "inserted_puffs": 140,
  "peak_weekday": 1,
  "peak_hour": 14,
  "days_back": 21
}
```

Campos da saida:
- user_id: dono dos dados simulados.
- inserted_puffs: quantidade efetivamente inserida.
- peak_weekday: dia de pico usado na simulacao.
- peak_hour: hora de pico usada na simulacao.
- days_back: janela usada na simulacao.

---

### POST /ai/predictive/alerts/generate
Objetivo:
- Gerar alerta preventivo para proxima janela de risco prevista.
- Salvar alerta em ai_predictive_alerts.

Headers:
- Authorization: Bearer <access_token>

Exemplo de body:
```json
{
  "lead_minutes": 15
}
```

Campos do body:
- lead_minutes: antecedencia em minutos do alerta (10 a 15).

Exemplo de saida:
```json
{
  "alert_id": "954f61bf-b3af-4f2c-a9c6-3fb6ea0a2b56",
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "predicted_at": "2026-05-27T13:45:00Z",
  "sent_at": "2026-05-22T03:18:12Z",
  "suggestion_text": "Agora: beba agua e saia do ambiente gatilho. Em 5 minutos: caminhe e respire fundo. Voce ja avancou muito."
}
```

Campos da saida:
- alert_id: id do alerta gerado.
- user_id: usuario alvo do alerta.
- predicted_at: inicio previsto da janela critica (considerando lead_minutes).
- sent_at: horario em que o alerta foi gerado/enviado.
- suggestion_text: texto de acao alternativa personalizada.

---

### POST /ai/predictive/alerts/{alert_id}/evaluate
Objetivo:
- Medir resultado do alerta apos janela de risco.
- Atualizar result_status em ai_predictive_alerts.

Headers:
- Authorization: Bearer <access_token>

Exemplo de body:
```json
{
  "window_minutes": 30
}
```

Campos do body:
- window_minutes: tamanho da janela apos predicted_at para avaliar recaida/controle.

Exemplo de saida:
```json
{
  "alert_id": "954f61bf-b3af-4f2c-a9c6-3fb6ea0a2b56",
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "result_status": "overcame_window",
  "puffs_in_window": 0
}
```

Campos da saida:
- alert_id: alerta avaliado.
- user_id: dono do alerta.
- result_status: resultado da janela.
  - overcame_window: nao houve tragadas no periodo.
  - relapse_risk: houve tragadas no periodo.
- puffs_in_window: quantidade de tragadas detectadas na janela.

## 5) IA Comportamental

### POST /ai/behavioral/quick-support
Objetivo:
- Fluxo de crise imediata (botao "To quase fumando").
- Abre sessao de chat e retorna resposta da IA com contexto real do usuario.

Headers:
- Authorization: Bearer <access_token>

Exemplo de body:
```json
{
  "message": "To com muita vontade de fumar agora"
}
```

Campos do body:
- message: relato inicial do usuario sobre a crise atual.

Exemplo de saida:
```json
{
  "session_id": "4a6f13db-1fa2-4c04-88fd-7d8af2f9d8ca",
  "user_id": "b0dd8b7a-ee86-4b70-8e24-9898da62c9b8",
  "user_message": "To com muita vontade de fumar agora",
  "ai_message": "Vamos atravessar essa onda juntos...",
  "ai_tone_used": "empatico",
  "abstinence_hours": 36.5,
  "estimated_saved_money": 14.6
}
```

Campos da saida:
- session_id: id da sessao criada em chat_sessions.
- user_id: usuario que iniciou o suporte.
- user_message: mensagem inicial recebida.
- ai_message: resposta gerada pela IA.
- ai_tone_used: tom aplicado na resposta (empatico/energetico).
- abstinence_hours: horas aproximadas sem fumar desde ultima tragada.
- estimated_saved_money: economia estimada com base em consumo diario e preco do maco.

---

### POST /ai/behavioral/message
Objetivo:
- Continuar conversa em sessao existente.

Headers:
- Authorization: Bearer <access_token>

Exemplo de body:
```json
{
  "session_id": "4a6f13db-1fa2-4c04-88fd-7d8af2f9d8ca",
  "message": "A vontade caiu para 6/10"
}
```

Campos do body:
- session_id: sessao de chat existente do usuario.
- message: nova mensagem do usuario na conversa.

Exemplo de saida:
```json
{
  "session_id": "4a6f13db-1fa2-4c04-88fd-7d8af2f9d8ca",
  "ai_message": "Excelente progresso. Agora vamos para uma tecnica de 2 minutos...",
  "ai_tone_used": "empatico"
}
```

Campos da saida:
- session_id: sessao em que a resposta foi registrada.
- ai_message: resposta da IA para a mensagem enviada.
- ai_tone_used: tom aplicado na resposta.

## 6) Fluxo recomendado de uso (frontend)

1. Login OAuth:
- GET /auth/google
- GET /auth/callback?code=...
- POST /auth/register-sso

2. Perfil inicial e onboarding:
- POST /onboarding/submit
- GET /onboarding/me
- GET /auth/me

3. Teste preditivo sem IoT:
- POST /ai/predictive/simulate-puffs
- POST /ai/predictive/analyze
- POST /ai/predictive/alerts/generate
- POST /ai/predictive/alerts/{alert_id}/evaluate

4. Fluxo de crise (comportamental):
- POST /ai/behavioral/quick-support
- POST /ai/behavioral/message

## 7) Observacoes tecnicas

- As rotas protegidas exigem JWT valido do Supabase Auth.
- O backend garante criacao minima de public.users quando necessario.
- A integracao com Groq depende de variaveis de ambiente:
  - GROQ_API_KEY
  - GROQ_MODEL (opcional)
- Sem GROQ_API_KEY, a aplicacao usa respostas fallback para nao interromper o fluxo.
