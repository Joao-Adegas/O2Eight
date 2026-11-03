# O₂Eight - Backend

API REST do O₂Eight, desenvolvida em Python com FastAPI. Responsável por validar a autenticação dos usuários, persistir os dados no Supabase (PostgreSQL), calcular os indicadores de progresso e integrar o modelo de linguagem da Groq.

## Sumário

- [Início rápido](#início-rápido)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Variáveis de ambiente](#variáveis-de-ambiente)
- [Execução](#execução)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Autenticação](#autenticação)
- [Tabelas](#tabelas)
- [Rotas](#rotas)
- [Ajustes de banco](#ajustes-de-banco)
- [Solução de problemas](#solução-de-problemas)

## Início rápido

Sequência completa para a primeira execução, no PowerShell, a partir da raiz do repositório:

```powershell
cd backend
python -m venv env
.\env\Scripts\activate
pip install -r requirements.txt
Copy-Item .env.example .env
```

Abra o arquivo `.env` criado, preencha as chaves (ver [Variáveis de ambiente](#variáveis-de-ambiente)) e inicie o servidor:

```powershell
uvicorn api.main:app --reload --port 8000
```

Nas execuções seguintes, basta:

```powershell
cd backend
.\env\Scripts\activate
uvicorn api.main:app --reload --port 8000
```

## Requisitos

- Python 3.11 ou superior
- Projeto no Supabase com as tabelas descritas neste documento
- Chave de API da Groq (gratuita em https://console.groq.com)

## Instalação

Todos os comandos abaixo são para o PowerShell do Windows e devem ser executados a partir da pasta `backend`.

1. Crie o ambiente virtual (apenas na primeira vez):

   ```powershell
   python -m venv env
   ```

2. Ative o ambiente virtual (sempre que abrir um novo terminal):

   ```powershell
   .\env\Scripts\activate
   ```

   O prefixo `(env)` aparece no terminal quando o ambiente está ativo.

3. Instale as dependências:

   ```powershell
   pip install -r requirements.txt
   ```

   Caso o arquivo `requirements.txt` ainda não exista, instale os pacotes principais e gere o arquivo para os demais membros da equipe:

   ```powershell
   pip install fastapi uvicorn supabase python-dotenv
   pip freeze > requirements.txt
   ```

## Variáveis de ambiente

O repositório inclui o arquivo `.env.example`, um modelo com todas as variáveis necessárias e sem chaves reais. Para configurar o ambiente:

1. Na pasta `backend`, crie o `.env` a partir do modelo:

   ```powershell
   Copy-Item .env.example .env
   ```

   Também é possível duplicar o arquivo pelo explorador e renomear a cópia para `.env`. Prefira copiar em vez de renomear o original: o `.env.example` deve continuar no repositório para os demais membros da equipe.

2. Abra o `.env` e substitua cada valor de exemplo pela chave correspondente:

| Variável | Onde encontrar | Uso |
|---|---|---|
| `SUPABASE_URL` | Supabase > Project Settings > API | Endereço do projeto |
| `SUPABASE_ANON_KEY` | Supabase > Project Settings > API Keys | Validação dos tokens dos usuários |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase > Project Settings > API Keys | Operações no banco com permissão sobre o RLS |
| `GROQ_API_KEY` | console.groq.com > API Keys | Acesso ao modelo de linguagem |
| `GROQ_MODEL` | console.groq.com/docs/models | Modelo utilizado; o padrão é `openai/gpt-oss-20b` |

Observações importantes:

- O arquivo `.env` e a pasta `env/` não devem ser versionados. O `.env.example` deve ser versionado. O `.gitignore` do backend deve conter:

  ```
  .env
  env/
  ```

- Ao adicionar uma nova variável ao projeto, inclua-a também no `.env.example`, com um valor de exemplo, para que os demais membros saibam que ela existe.
- A chave `service_role` ignora as políticas de segurança do banco. Ela deve existir apenas no backend e nunca no aplicativo.
- O servidor não recarrega o `.env` automaticamente. Após alterá-lo, reinicie o uvicorn.

## Execução

Com o ambiente virtual ativo e a partir da pasta `backend`:

```powershell
uvicorn api.main:app --reload --port 8000
```

O comando deve ser executado na pasta `backend`, e não dentro de `api`, pois os imports do projeto partem do pacote `api`.

| Endereço | Conteúdo |
|---|---|
| `http://localhost:8000/docs` | Documentação interativa (Swagger) |
| `http://localhost:8000/redoc` | Documentação em formato de leitura |

Para verificar a conexão com a Groq sem subir o servidor:

```powershell
python -c "from dotenv import load_dotenv;load_dotenv();from api.services.ai_service import _call_groq_chat;print(_call_groq_chat('Responda em uma frase.','Diga oi.'))"
```

## Estrutura de pastas

```
backend/
├── api/
│   ├── main.py            Criação da aplicação, CORS e registro das rotas
│   ├── core/
│   │   └── supabase.py    Clientes Supabase (anon e admin)
│   ├── prompts/           Prompts dos modelos de linguagem
│   ├── schemas/           Modelos Pydantic de entrada e saída
│   ├── services/          Regras de negócio e acesso ao banco
│   └── v1/routes/         Definição das rotas
├── .env.example           Modelo das variáveis de ambiente (versionado)
├── .env                   Variáveis de ambiente reais (não versionar)
├── env/                   Ambiente virtual (não versionar)
└── requirements.txt
```

## Autenticação

O login é realizado pelo aplicativo diretamente no Supabase Auth (Google OAuth ou e-mail e senha). A API não participa do fluxo de login: ela recebe o token de acesso gerado pelo Supabase e o valida a cada requisição.

Todas as rotas, exceto a documentação, exigem o cabeçalho:

```
Authorization: Bearer <access_token>
```

O backend utiliza dois clientes Supabase, definidos em `api/core/supabase.py`:

| Cliente | Chave | Uso |
|---|---|---|
| `supabase` | anon | Validação de tokens (`auth.get_user`) |
| `supabase_admin` | service_role | Leitura e escrita nas tabelas |

Formato padrão de erro:

```json
{
  "detail": "mensagem de erro"
}
```

## Tabelas

### users

Perfil do usuário autenticado. O e-mail é obtido do Supabase Auth e não é armazenado nesta tabela.

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK, referência a `auth.users.id` |
| `name` | varchar | Preenchido a partir do Google ou do cadastro |
| `created_at` | timestamptz | |

### forms

Formulário de onboarding. Um registro por usuário.

| Campo | Tipo | Observação |
|---|---|---|
| `uuid` | uuid | PK |
| `user_uuid` | uuid | FK para `users.id`, único |
| `smoking_time` | varchar | Valores aceitos abaixo |
| `cigarettes_per_day` | varchar | Valores aceitos abaixo |
| `cigarette_type` | text[] | |
| `motivations_to_quit` | text[] | |
| `pack_price` | numeric | Preço do maço ou refil, em reais |
| `triggers` | text[] | |
| `family_health_history` | text[] | |
| `time_smoke_the_most` | varchar | Valores aceitos abaixo |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

Valores aceitos pela API (definidos em `api/schemas/onboarding.py`):

| Campo | Valores |
|---|---|
| `smoking_time` | `1 dia a 1 semana`, `1 semana a 1 mês`, `1 mês a 3 meses`, `3 meses a 1 ano`, `Mais de 1 ano` |
| `cigarettes_per_day` | `Entre 1 e 5`, `Entre 5 e 10`, `Entre 10 e 15`, `Entre 15 e 20`, `Mais de 20` |
| `time_smoke_the_most` | `De manhã`, `De tarde`, `De noite` |

Os textos do aplicativo devem ser idênticos a esses valores. Ao alterar uma opção, atualize também o mapeamento `_CIGARETTES_PER_DAY_TO_AVERAGE` em `api/services/onboarding_service.py`.

### user_progress

Progresso do usuário. Um registro por usuário, criado automaticamente no primeiro acesso ao painel.

| Campo | Tipo | Observação |
|---|---|---|
| `uuid` | uuid | PK |
| `user_id` | uuid | FK para `users.id`, único |
| `clean_days` | int | Sincronizado automaticamente a cada consulta ao painel |
| `last_smoked_at` | timestamptz | Data da última recaída; nulo se nunca houve |
| `created_at` | timestamptz | Início do acompanhamento |
| `updated_at` | timestamptz | |

Os dias sem fumar são calculados pela data: contam a partir de `last_smoked_at` ou, se ele for nulo, a partir de `created_at`.

### hardware_sessions

Sessões de uso registradas pelo dispositivo.

| Campo | Tipo |
|---|---|
| `uuid` | uuid (PK) |
| `user_id` | uuid (FK para `users.id`) |
| `quantidade_puxadas` | int |
| `inicio_da_sessao` | timestamptz |
| `fim_da_sessao` | timestamptz |
| `created_at` | timestamptz |

### chat_sessions_new

| Campo | Tipo | Observação |
|---|---|---|
| `uuid` | uuid | PK |
| `usuario_id` | uuid | FK para `users.id` |
| `titulo` | varchar | Preenchido com a primeira mensagem da conversa |
| `created_at` | timestamptz | |

### chat_messages_new

| Campo | Tipo | Observação |
|---|---|---|
| `uuid` | uuid | PK |
| `sessao_id` | uuid | FK para `chat_sessions_new.uuid` |
| `remetente` | varchar | `usuario` ou `bot` |
| `conteudo` | text | |
| `enviado_em` | timestamptz | |

### community_posts e community_comments

| Tabela | Campos |
|---|---|
| `community_posts` | `uuid`, `user_uuid`, `dias_limpos`, `comment`, `created_at`, `likes` |
| `community_comments` | `uuid`, `post_uuid`, `user_uuid`, `comment`, `created_at`, `likes` |

## Rotas

### Auth (`/auth`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/auth/register-sso` | Cria o registro em `users` no primeiro acesso. Idempotente: se já existir, apenas retorna os dados |
| GET | `/auth/me` | Retorna `id`, `email`, `name` e `created_at` do usuário. Retorna 404 se o usuário ainda não foi registrado |

### Formulário (`/form`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/form/submit` | Cria ou atualiza o formulário do usuário |
| GET | `/form/me` | Retorna o formulário. Retorna 404 se ainda não foi preenchido; o aplicativo usa isso para decidir se exibe o onboarding |
| GET | `/form/savings` | Economia estimada com base em `clean_days` |

Exemplo de corpo para `POST /form/submit`:

```json
{
  "smoking_time": "Mais de 1 ano",
  "cigarettes_per_day": "Entre 10 e 15",
  "cigarette_type": ["Cigarro", "VAPE"],
  "motivations_to_quit": ["Saúde", "Família"],
  "pack_price": 12.0,
  "triggers": ["Estresse", "Depois do café"],
  "family_health_history": ["Asma"],
  "time_smoke_the_most": "De noite"
}
```

### Progresso (`/progress`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/progress/dashboard` | Dados do painel: dias sem fumar, data de início, custo diário e dinheiro economizado |
| GET | `/progress/me` | Registro bruto de `user_progress` |
| POST | `/progress/mark-smoked` | Registra uma recaída e reinicia o contador |
| GET | `/progress/recovery` | Marcos de recuperação biológica gerados por IA |
| POST | `/progress/check-in` | Mantida por compatibilidade; os dias agora são calculados pela data |

Cálculo da economia em `GET /progress/dashboard`:

```
custo diário = (média de cigarros por dia / 20) x preço do maço
economizado  = dias sem fumar (com fração do dia) x custo diário
```

Exemplo de resposta:

```json
{
  "user_id": "uuid-do-usuario",
  "clean_days": 10,
  "clean_since": "2026-09-15T14:02:11+00:00",
  "daily_cost": 7.2,
  "estimated_saved_money": 72.0,
  "has_form": true
}
```

### Chatbot (`/chat`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/chat/sessions` | Cria uma conversa. Corpo: `{"titulo": null}` |
| GET | `/chat/sessions` | Lista as conversas do usuário, da mais recente para a mais antiga |
| GET | `/chat/sessions/{session_id}` | Retorna a conversa e suas mensagens |
| POST | `/chat/sessions/{session_id}/messages` | Envia uma mensagem e retorna `[mensagem do usuário, resposta do bot]` |

Comportamento do envio de mensagens:

- O modelo recebe o perfil do usuário (dias sem fumar, gatilhos e motivações) e as 10 últimas mensagens da conversa.
- A resposta é gerada antes da gravação. Se a IA falhar, nenhuma mensagem é salva e a rota retorna 502.
- A primeira mensagem da conversa passa a ser o título da sessão.

### IA (`/ai`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/ai/daily-tip` | Dica diária personalizada a partir do formulário, do progresso e das sessões do dispositivo |

### Hardware (`/hardware`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/hardware/sessions` | Registra uma sessão de uso do dispositivo |
| GET | `/hardware/sessions/me` | Lista as sessões do usuário |

Em desenvolvimento: pareamento do dispositivo com a conta do usuário, para que o ESP32 envie as sessões sem depender do token de login, e reinício do contador de dias a cada sessão registrada, simulando o efeito de um cigarro fumado.

### Comunidade (`/community`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/community/posts` | Cria uma publicação; `dias_limpos` é preenchido automaticamente |
| GET | `/community/posts` | Lista publicações com comentários |
| POST | `/community/posts/{post_id}/comments` | Comenta uma publicação |
| POST | `/community/posts/{post_id}/like` | Curte uma publicação |
| POST | `/community/comments/{comment_id}/like` | Curte um comentário |

## Ajustes de banco

A estrutura inicial está em `supabase/migrations/20260525_backend_restructure.sql`. Após essa migração, os ajustes abaixo foram aplicados pelo SQL Editor do Supabase. Recomenda-se salvá-los em um novo arquivo de migração para que o ambiente possa ser reproduzido.

```sql
-- Valores padrão para chaves e datas
alter table public.forms alter column uuid set default gen_random_uuid();
alter table public.forms alter column created_at set default now();

alter table public.user_progress alter column uuid set default gen_random_uuid();
alter table public.user_progress alter column created_at set default now();

alter table public.chat_sessions_new alter column uuid set default gen_random_uuid();
alter table public.chat_sessions_new alter column created_at set default now();

alter table public.chat_messages_new alter column uuid set default gen_random_uuid();
alter table public.chat_messages_new alter column enviado_em set default now();
```

A restrição de unicidade `forms_user_uuid_key`, exigida pelo upsert do formulário, já faz parte da migração inicial.

Registros de `forms` criados antes da atualização dos valores aceitos (por exemplo, `+ de 1 ano` ou `De manha`) causam erro 500 em `GET /form/me` e devem ser atualizados ou removidos.

## Solução de problemas

| Sintoma | Causa | Solução |
|---|---|---|
| `Could not import module "main"` | Comando executado com o caminho errado | Na pasta `backend`, use `uvicorn api.main:app` |
| `No module named 'api'` | Comando executado de dentro da pasta `api` | Volte para `backend` com `cd ..` |
| `OPTIONS ... 405 Method Not Allowed` | CORS não configurado | Confirme o `CORSMiddleware` em `api/main.py` |
| `new row violates row-level security policy` (42501) | Operação feita com a chave anon | Use `supabase_admin` nos services e confira `SUPABASE_SERVICE_ROLE_KEY` |
| `there is no unique or exclusion constraint matching the ON CONFLICT` | Falta a restrição única em `forms.user_uuid` | Crie a restrição `forms_user_uuid_key` |
| Chat retorna 502 | Falha na chamada à Groq | Execute o teste de conexão da seção Execução |
| `model_not_found` | Modelo descontinuado ou indisponível | Ajuste `GROQ_MODEL` no `.env` e reinicie o servidor |
| Alterações no `.env` sem efeito | O servidor não recarrega o `.env` | Reinicie o uvicorn |