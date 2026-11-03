-- Dados de EXEMPLO para testar a página de Insights.
-- Troque o e-mail abaixo pelo da sua conta de teste e rode no SQL Editor do Supabase.
-- Cria 24 momentos de vontade nos últimos 14 dias, concentrados por volta das 20h
-- e depois do almoço (13h), para o app prever esses horários de risco.

with u as (
  select id from auth.users where email = 'SEU_EMAIL_DE_TESTE@gmail.com'
),
base(dias_atras, hora, minuto, outcome, dur) as (
  values
    (0, 20, 15, 'overcome', 420), (1, 20, 40, 'overcome', 300), (1, 13, 10, 'overcome', 240),
    (2, 21, 5, 'smoked', 120),   (2, 13, 30, 'overcome', 360), (3, 20, 20, 'overcome', 480),
    (4, 20, 50, 'overcome', 300), (4, 9, 0, 'overcome', 180),  (5, 13, 45, 'smoked', 90),
    (5, 21, 10, 'overcome', 400), (6, 20, 5, 'overcome', 350), (7, 20, 30, 'smoked', 60),
    (7, 13, 20, 'overcome', 300), (8, 21, 40, 'overcome', 420), (9, 13, 5, 'overcome', 200),
    (9, 20, 25, 'overcome', 380), (10, 16, 0, 'overcome', 240), (10, 20, 55, 'overcome', 310),
    (11, 13, 35, 'overcome', 270), (11, 21, 15, 'smoked', 100), (12, 20, 10, 'overcome', 330),
    (12, 8, 30, 'overcome', 150), (13, 20, 45, 'overcome', 290), (13, 14, 0, 'abandoned', 30)
)
insert into craving_events (user_id, started_at, outcome, duration_seconds, source)
select u.id,
       -- horário de Brasília (UTC-3) convertido para UTC
       (date_trunc('day', now() at time zone 'America/Sao_Paulo')
          - make_interval(days => b.dias_atras)
          + make_interval(hours => b.hora, mins => b.minuto)) at time zone 'America/Sao_Paulo',
       b.outcome, b.dur, 'app'
from u, base b;

-- Para apagar depois só os dados de exemplo dessa conta:
-- delete from craving_events
-- where user_id = (select id from auth.users where email = 'SEU_EMAIL_DE_TESTE@gmail.com');
