-- O2Eight backend restructure
-- Date: 2026-05-25

create extension if not exists pgcrypto;

-- Keep users linked to Supabase auth and remove onboarding-specific columns.
alter table if exists public.users
    drop column if exists daily_cigarette_consumption,
    drop column if exists pack_price,
    drop column if exists preferred_ai_tone;

-- Form table (new onboarding model).
create table if not exists public.forms (
    uuid uuid primary key default gen_random_uuid(),
    user_uuid uuid not null unique references public.users (id) on delete cascade,
    smoking_time varchar(40) not null,
    cigarettes_per_day varchar(40) not null,
    cigarette_type text[] not null default '{}',
    motivations_to_quit text[] not null default '{}',
    pack_price numeric(10, 2) not null,
    triggers text[] not null default '{}',
    family_health_history text[] not null default '{}',
    time_smoke_the_most varchar(20) not null,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint forms_pack_price_non_negative check (pack_price >= 0),
    constraint forms_smoking_time_check check (
        smoking_time in ('+ de 1 ano', '1 dia a 1 semana', '1 mes a 1 ano')
    ),
    constraint forms_cigarettes_per_day_check check (
        cigarettes_per_day in ('Entre 1 e 5', 'Entre 5 e 10', '+ 10 cigarros', '+ 15 cigarros', '+ 20 cigarros')
    ),
    constraint forms_time_smoke_the_most_check check (
        time_smoke_the_most in ('De manha', 'De tarde', 'De noite')
    )
);

create index if not exists idx_forms_user_uuid on public.forms (user_uuid);

-- Hardware sessions table.
create table if not exists public.hardware_sessions (
    uuid uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    quantidade_puxadas int not null,
    inicio_da_sessao timestamptz not null,
    fim_da_sessao timestamptz not null,
    created_at timestamptz not null default timezone('utc', now()),
    constraint hardware_sessions_quantidade_non_negative check (quantidade_puxadas >= 0),
    constraint hardware_sessions_time_order check (fim_da_sessao >= inicio_da_sessao)
);

create index if not exists idx_hardware_sessions_user_id_inicio on public.hardware_sessions (user_id, inicio_da_sessao desc);

-- User progress table.
create table if not exists public.user_progress (
    uuid uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references public.users (id) on delete cascade,
    clean_days int not null default 0,
    last_smoked_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint user_progress_clean_days_non_negative check (clean_days >= 0)
);

create index if not exists idx_user_progress_user_id on public.user_progress (user_id);

-- Community posts and comments.
create table if not exists public.community_posts (
    uuid uuid primary key default gen_random_uuid(),
    user_uuid uuid not null references public.users (id) on delete cascade,
    dias_limpos int not null default 0,
    comment text not null,
    created_at timestamptz not null default timezone('utc', now()),
    likes int not null default 0,
    constraint community_posts_likes_non_negative check (likes >= 0),
    constraint community_posts_dias_limpos_non_negative check (dias_limpos >= 0)
);

create index if not exists idx_community_posts_created_at on public.community_posts (created_at desc);
create index if not exists idx_community_posts_user_uuid on public.community_posts (user_uuid);

create table if not exists public.community_comments (
    uuid uuid primary key default gen_random_uuid(),
    post_uuid uuid not null references public.community_posts (uuid) on delete cascade,
    user_uuid uuid not null references public.users (id) on delete cascade,
    comment text not null,
    created_at timestamptz not null default timezone('utc', now()),
    likes int not null default 0,
    constraint community_comments_likes_non_negative check (likes >= 0)
);

create index if not exists idx_community_comments_post_uuid on public.community_comments (post_uuid, created_at asc);

-- Chat tables in requested structure.
create table if not exists public.chat_sessions_new (
    uuid uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.users (id) on delete cascade,
    titulo varchar(200),
    created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.chat_messages_new (
    uuid uuid primary key default gen_random_uuid(),
    sessao_id uuid not null references public.chat_sessions_new (uuid) on delete cascade,
    remetente varchar(20) not null,
    conteudo text not null,
    enviado_em timestamptz not null default timezone('utc', now()),
    constraint chat_messages_new_sender_check check (remetente in ('usuario', 'bot'))
);

create index if not exists idx_chat_sessions_new_usuario_id on public.chat_sessions_new (usuario_id, created_at desc);
create index if not exists idx_chat_messages_new_sessao_id on public.chat_messages_new (sessao_id, enviado_em asc);

-- RLS
alter table public.forms enable row level security;
alter table public.hardware_sessions enable row level security;
alter table public.user_progress enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
alter table public.chat_sessions_new enable row level security;
alter table public.chat_messages_new enable row level security;

-- Forms policies.
drop policy if exists forms_rw_own on public.forms;
create policy forms_rw_own on public.forms
for all using (auth.uid() = user_uuid)
with check (auth.uid() = user_uuid);

-- Hardware policies.
drop policy if exists hardware_sessions_rw_own on public.hardware_sessions;
create policy hardware_sessions_rw_own on public.hardware_sessions
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- User progress policies.
drop policy if exists user_progress_rw_own on public.user_progress;
create policy user_progress_rw_own on public.user_progress
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Community policies.
drop policy if exists community_posts_rw_own on public.community_posts;
create policy community_posts_rw_own on public.community_posts
for all using (auth.uid() = user_uuid)
with check (auth.uid() = user_uuid);

-- Allow any authenticated user to read posts/comments.
drop policy if exists community_posts_select_authenticated on public.community_posts;
create policy community_posts_select_authenticated on public.community_posts
for select using (auth.role() = 'authenticated');

drop policy if exists community_comments_rw_own on public.community_comments;
create policy community_comments_rw_own on public.community_comments
for all using (auth.uid() = user_uuid)
with check (auth.uid() = user_uuid);

drop policy if exists community_comments_select_authenticated on public.community_comments;
create policy community_comments_select_authenticated on public.community_comments
for select using (auth.role() = 'authenticated');

-- Chat policies.
drop policy if exists chat_sessions_new_rw_own on public.chat_sessions_new;
create policy chat_sessions_new_rw_own on public.chat_sessions_new
for all using (auth.uid() = usuario_id)
with check (auth.uid() = usuario_id);

drop policy if exists chat_messages_new_rw_own on public.chat_messages_new;
create policy chat_messages_new_rw_own on public.chat_messages_new
for all using (
    exists (
        select 1
        from public.chat_sessions_new cs
        where cs.uuid = chat_messages_new.sessao_id
          and cs.usuario_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.chat_sessions_new cs
        where cs.uuid = chat_messages_new.sessao_id
          and cs.usuario_id = auth.uid()
    )
);
