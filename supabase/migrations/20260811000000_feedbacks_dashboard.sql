-- Tabela oficial de feedback (app mobile + dashboard GitHub Pages).
-- Colunas em português alinhadas ao index.html do repositório Feedback.

create table if not exists public.feedbacks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  tipo text not null check (tipo in ('Bug', 'Sugestão', 'Elogios')),
  modulo text not null,
  impacto text not null check (impacto in ('Baixo', 'Médio', 'Alto', 'Crítico')),
  mensagem text not null,
  created_at timestamptz not null default now()
);

create index if not exists feedbacks_created_at_idx
  on public.feedbacks (created_at desc);

alter table public.feedbacks enable row level security;

drop policy if exists feedbacks_insert_own on public.feedbacks;
drop policy if exists feedbacks_select_dashboard on public.feedbacks;

create policy feedbacks_insert_own
  on public.feedbacks
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Dashboard GitHub Pages (anon key) e estatísticas agregadas no app.
create policy feedbacks_select_dashboard
  on public.feedbacks
  for select
  to anon, authenticated
  using (true);
