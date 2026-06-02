# O2Eight Backend API - Tabelas e Rotas (Reestruturado)

## 1) Visao Geral

Base URL local:
- http://localhost:8000

Autenticacao para rotas protegidas:
- Header: Authorization: Bearer <access_token>

Formato padrao de erro:
```json
{
  "detail": "mensagem de erro"
}
```

## 2) Estrutura das Tabelas

### 2.1 users
Mantem o usuario SSO (Google/Supabase Auth).

Campos:
- id (uuid, PK, FK para auth.users.id)
- name (varchar)
- created_at (timestamptz)

Observacao:
- Campos removidos desta tabela: daily_cigarette_consumption, pack_price, preferred_ai_tone.

### 2.2 forms
Formulario inicial do usuario (1 registro por usuario).

Campos:
- uuid (uuid, PK)
- user_uuid (uuid, FK para users.id, unique)
- smoking_time (enum textual):
  - + de 1 ano
  - 1 dia a 1 semana
  - 1 mes a 1 ano
- cigarettes_per_day (enum textual):
  - Entre 1 e 5
  - Entre 5 e 10
  - + 10 cigarros
  - + 15 cigarros
  - + 20 cigarros
- cigarette_type (text[])
- motivations_to_quit (text[])
- pack_price (numeric)
- triggers (text[])
- family_health_history (text[])
- time_smoke_the_most (enum textual):
  - De manha
  - De tarde
  - De noite
- created_at (timestamptz)
- updated_at (timestamptz)

### 2.3 hardware_sessions
Eventos enviados pelo hardware com sessoes de uso.

Campos:
- uuid (uuid, PK)
- user_id (uuid, FK para users.id)
- quantidade_puxadas (int)
- inicio_da_sessao (timestamptz)
- fim_da_sessao (timestamptz)
- created_at (timestamptz)

### 2.4 user_progress
Progresso diario do usuario.

Campos:
- uuid (uuid, PK)
- user_id (uuid, FK para users.id, unique)
- clean_days (int)
- last_smoked_at (timestamptz)
- created_at (timestamptz)
- updated_at (timestamptz)

### 2.5 community_posts
Postagens da comunidade.

Campos:
- uuid (uuid, PK)
- user_uuid (uuid, FK para users.id)
- dias_limpos (int)
- comment (text)
- created_at (timestamptz)
- likes (int, default 0)

### 2.6 community_comments
Comentarios da comunidade.

Campos:
- uuid (uuid, PK)
- post_uuid (uuid, FK para community_posts.uuid)
- user_uuid (uuid, FK para users.id)
- comment (text)
- created_at (timestamptz)
- likes (int, default 0)

### 2.7 chat_sessions_new
Sessoes do chatbot.

Campos:
- uuid (uuid, PK)
- usuario_id (uuid, FK para users.id)
- titulo (varchar)
- created_at (timestamptz)

### 2.8 chat_messages_new
Mensagens do chatbot.

Campos:
- uuid (uuid, PK)
- sessao_id (uuid, FK para chat_sessions_new.uuid)
- remetente (enum textual): usuario | bot
- conteudo (text)
- enviado_em (timestamptz)

## 3) Rotas de Auth

### GET /auth/google
Retorna URL de login OAuth Google.

### GET /auth/callback?code=...
Troca code OAuth por access_token e refresh_token.

### POST /auth/register-sso
Garante/sincroniza registro em public.users.

### POST /auth/register-email
Cadastro simples com email e senha usando Supabase Auth.

Este endpoint cria o usuario ja confirmado e retorna sessao de login.

Body:
```json
{
  "email": "usuario@exemplo.com",
  "password": "SenhaForte123",
  "name": "Nome Opcional"
}
```

Retorno:
- Dados basicos do usuario criado.
- Tokens de sessao (`access_token` e `refresh_token`) para uso imediato.

### POST /auth/login-email
Login com email e senha.

Body:
```json
{
  "email": "usuario@exemplo.com",
  "password": "SenhaForte123"
}
```

Retorno:
- Tokens de sessao (`access_token` e `refresh_token`).

### GET /auth/me
Retorna dados do usuario autenticado (auth + users).

## 4) Rotas de Formulario

Prefixo: /form

### POST /form/submit
Cria ou atualiza o formulario do usuario (upsert por user_uuid).

Exemplo de body:
```json
{
  "smoking_time": "+ de 1 ano",
  "cigarettes_per_day": "Entre 5 e 10",
  "cigarette_type": ["Cigarro", "VAPE"],
  "motivations_to_quit": ["Saude", "Familia"],
  "pack_price": 25.0,
  "triggers": ["Estresse", "Cafe"],
  "family_health_history": ["Asma"],
  "time_smoke_the_most": "De noite"
}
```

### GET /form/me
Retorna o formulario atual do usuario.

### GET /form/savings
Retorna economia estimada por nao fumar:
- clean_days (de user_progress)
- estimated_saved_money (calculado com pack_price + cigarro/dia)

## 5) Rotas de Hardware

Prefixo: /hardware

### POST /hardware/sessions
Registra sessao enviada pelo hardware.

Exemplo de body:
```json
{
  "user_id": "uuid-do-usuario",
  "quantidade_puxadas": 14,
  "inicio_da_sessao": "2026-05-25T20:00:00Z",
  "fim_da_sessao": "2026-05-25T20:08:00Z"
}
```

### GET /hardware/sessions/me
Lista sessoes de hardware do usuario autenticado.

## 6) Rotas de Progresso

Prefixo: /progress

### GET /progress/me
Retorna progresso atual do usuario.

### POST /progress/check-in
Incrementa clean_days em +1 (uma vez por dia).

### POST /progress/mark-smoked
Zera clean_days e atualiza last_smoked_at.

### GET /progress/recovery
Retorna recuperacao biologica baseada em clean_days.

Exemplo de saida:
```json
{
  "user_id": "uuid-do-usuario",
  "clean_days": 3,
  "recuperation": [
    "Pressao arterial normalizada",
    "Oxigenio no sangue normalizado",
    "Nicotina eliminada do corpo"
  ]
}
```

## 7) Rotas de Comunidade

Prefixo: /community

### POST /community/posts
Cria post na comunidade.
- dias_limpos eh preenchido automaticamente a partir de user_progress.

Body:
```json
{
  "comment": "Hoje completei mais um dia sem fumar!"
}
```

### GET /community/posts
Lista posts com comentarios embutidos.

### POST /community/posts/{post_id}/comments
Cria comentario em post.

Body:
```json
{
  "comment": "Parabens, continue firme!"
}
```

### POST /community/comments/{comment_id}/like
Incrementa em +1 o numero de curtidas de um comentario.

Retorno:
- O comentario atualizado (incluindo o campo `likes`).

### POST /community/posts/{post_id}/like
Incrementa em +1 o numero de curtidas de um post.

Retorno:
- O post atualizado (incluindo o campo `likes`).

## 8) Rotas de Chatbot

Prefixo: /chat

### POST /chat/sessions
Cria sessao do chatbot.

Body:
```json
{
  "titulo": "Crise da noite"
}
```

### GET /chat/sessions
Lista sessoes do usuario.

### POST /chat/sessions/{session_id}/messages
Envia mensagem do usuario e salva resposta do bot (Groq).

Body:
```json
{
  "conteudo": "Estou com muita vontade de fumar agora"
}
```

### GET /chat/sessions/{session_id}
Retorna sessao e historico de mensagens.

## 9) Rotas de IA (Groq)

Prefixo: /ai

### GET /ai/daily-tip
Analisa:
- respostas do formulario (forms)
- progresso (user_progress)
- sessoes do hardware (hardware_sessions)

Retorna:
- dica diaria para evitar gatilhos
- lista de recuperacao biologica para o dia

Exemplo de saida:
```json
{
  "user_id": "uuid-do-usuario",
  "clean_days": 5,
  "tip": "No horario de maior gatilho, faca 3 minutos de respiracao...",
  "biological_recovery": [
    "Pressao arterial normalizada",
    "Oxigenio no sangue normalizado",
    "Nicotina eliminada do corpo"
  ]
}
```

## 10) Migrações

Arquivo principal da reestruturacao:
- supabase/migrations/20260525_backend_restructure.sql

Esse arquivo cria as novas tabelas, constraints, indices e politicas RLS alinhadas com este documento.
