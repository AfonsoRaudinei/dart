-- Confirmação da visita pelo consultor, lida pelo produtor vinculado.
-- ADR-061

create table if not exists public.visit_producer_confirmations (
  id uuid primary key,
  visit_session_id uuid not null unique,
  client_id uuid not null,
  consultor_user_id uuid not null references auth.users(id) on delete cascade,
  confirmed_at timestamptz not null,
  visited_at timestamptz not null,
  farm_name text,
  field_name text,
  created_at timestamptz not null default now()
);

alter table public.visit_producer_confirmations enable row level security;

drop policy if exists visit_producer_confirmations_select
  on public.visit_producer_confirmations;
create policy visit_producer_confirmations_select
  on public.visit_producer_confirmations
  for select to authenticated
  using (
    consultor_user_id = auth.uid()
    or exists (
      select 1
        from public.producer_client_links l
       where l.client_id = visit_producer_confirmations.client_id
         and l.producer_user_id = auth.uid()
         and l.status = 'active'
    )
  );

drop policy if exists visit_producer_confirmations_insert
  on public.visit_producer_confirmations;
create policy visit_producer_confirmations_insert
  on public.visit_producer_confirmations
  for insert to authenticated
  with check (consultor_user_id = auth.uid());

drop policy if exists visit_producer_confirmations_update
  on public.visit_producer_confirmations;
create policy visit_producer_confirmations_update
  on public.visit_producer_confirmations
  for update to authenticated
  using (consultor_user_id = auth.uid())
  with check (consultor_user_id = auth.uid());
