-- O2Eight core + AI tables (English naming, Supabase compatible)
-- Run in Supabase SQL Editor.

create extension if not exists pgcrypto;

-- 1) Core user profile table linked to SSO (auth.users)
create table if not exists public.users (
    id uuid primary key references auth.users (id) on delete cascade,
    name varchar(150),
    created_at timestamptz not null default timezone('utc', now()),
    daily_cigarette_consumption int,
    pack_price numeric(10, 2),
    preferred_ai_tone varchar(50),
    constraint users_daily_cigarette_consumption_non_negative
        check (daily_cigarette_consumption is null or daily_cigarette_consumption >= 0),
    constraint users_pack_price_non_negative
        check (pack_price is null or pack_price >= 0)
);

alter table public.users
    add column if not exists name varchar(150),
    add column if not exists created_at timestamptz not null default timezone('utc', now()),
    add column if not exists daily_cigarette_consumption int,
    add column if not exists pack_price numeric(10, 2),
    add column if not exists preferred_ai_tone varchar(50);

-- Keep public.users synced with new SSO signups.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.users (id, name)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name')
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_auth_user();

-- 2) Onboarding responses
create table if not exists public.onboarding_responses (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    question_key varchar(120) not null,
    answer_text text,
    answered_at timestamptz not null default timezone('utc', now())
);

-- 3) Hardware puff time-series
create table if not exists public.hardware_puffs (
    id bigint generated always as identity primary key,
    user_id uuid not null references public.users (id) on delete cascade,
    happened_at timestamptz not null default timezone('utc', now())
);

-- 4) Predictive AI - user triggers
create table if not exists public.user_triggers (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    happened_at timestamptz not null default timezone('utc', now()),
    trigger_type varchar(100) not null,
    intensity int not null,
    constraint user_triggers_intensity_range check (intensity between 1 and 5)
);

-- 5) Predictive AI alerts
create table if not exists public.ai_predictive_alerts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    predicted_at timestamptz not null,
    sent_at timestamptz not null default timezone('utc', now()),
    suggestion_text text,
    result_status varchar(50)
);

-- 6) Behavioral AI chat sessions
create table if not exists public.chat_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    started_at timestamptz not null default timezone('utc', now()),
    ended_at timestamptz,
    initial_emotion varchar(50),
    final_status varchar(50)
);

-- 7) Behavioral AI chat messages
create table if not exists public.chat_messages (
    id bigint generated always as identity primary key,
    session_id uuid not null references public.chat_sessions (id) on delete cascade,
    sender varchar(20) not null,
    message_text text not null,
    created_at timestamptz not null default timezone('utc', now()),
    constraint chat_messages_sender_check check (sender in ('user', 'ai'))
);

-- Indexes for common query paths
create index if not exists idx_onboarding_responses_user_id on public.onboarding_responses (user_id);
create index if not exists idx_hardware_puffs_user_id_happened_at on public.hardware_puffs (user_id, happened_at desc);
create index if not exists idx_user_triggers_user_id_happened_at on public.user_triggers (user_id, happened_at desc);
create index if not exists idx_ai_predictive_alerts_user_id_predicted_at on public.ai_predictive_alerts (user_id, predicted_at desc);
create index if not exists idx_chat_sessions_user_id_started_at on public.chat_sessions (user_id, started_at desc);
create index if not exists idx_chat_messages_session_id_created_at on public.chat_messages (session_id, created_at);

-- RLS (recommended for Supabase app access)
alter table public.users enable row level security;
alter table public.onboarding_responses enable row level security;
alter table public.hardware_puffs enable row level security;
alter table public.user_triggers enable row level security;
alter table public.ai_predictive_alerts enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;

-- Policies (read/write only own records)
drop policy if exists users_select_own on public.users;
create policy users_select_own on public.users
for select using (auth.uid() = id);

drop policy if exists users_update_own on public.users;
create policy users_update_own on public.users
for update using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists onboarding_responses_rw_own on public.onboarding_responses;
create policy onboarding_responses_rw_own on public.onboarding_responses
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists hardware_puffs_rw_own on public.hardware_puffs;
create policy hardware_puffs_rw_own on public.hardware_puffs
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists user_triggers_rw_own on public.user_triggers;
create policy user_triggers_rw_own on public.user_triggers
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists ai_predictive_alerts_rw_own on public.ai_predictive_alerts;
create policy ai_predictive_alerts_rw_own on public.ai_predictive_alerts
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists chat_sessions_rw_own on public.chat_sessions;
create policy chat_sessions_rw_own on public.chat_sessions
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists chat_messages_rw_own on public.chat_messages;
create policy chat_messages_rw_own on public.chat_messages
for all using (
    exists (
        select 1
        from public.chat_sessions cs
        where cs.id = chat_messages.session_id
          and cs.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.chat_sessions cs
        where cs.id = chat_messages.session_id
          and cs.user_id = auth.uid()
    )
);
