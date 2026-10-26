-- ============================================================
-- SoloForte — ADR-052: espelho remoto de relatórios combinados
-- Data: 2026-10-26
--
-- Espelha a tabela SQLite relatorios_combinados (schema v46).
-- chapters_json é jsonb (array de chaves estáveis). HTML não é persistido.
-- user_id uuid REFERENCES auth.users. client_id text sem FK.
-- RLS authenticated: SELECT/INSERT/UPDATE com user_id = auth.uid().
-- Sem policy de DELETE. Sem policy anônima.
-- Não aplicar este arquivo no projeto live a partir do app.
-- ============================================================

create table if not exists public.relatorios_combinados (
  id text primary key,
  user_id uuid not null references auth.users(id),
  client_id text not null,
  title text not null,
  chapters_json jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz
);

alter table public.relatorios_combinados enable row level security;

drop policy if exists "relatorios_combinados_select_own" on public.relatorios_combinados;
drop policy if exists "relatorios_combinados_insert_own" on public.relatorios_combinados;
drop policy if exists "relatorios_combinados_update_own" on public.relatorios_combinados;

create policy "relatorios_combinados_select_own"
  on public.relatorios_combinados for select to authenticated
  using (user_id = auth.uid());

create policy "relatorios_combinados_insert_own"
  on public.relatorios_combinados for insert to authenticated
  with check (user_id = auth.uid());

create policy "relatorios_combinados_update_own"
  on public.relatorios_combinados for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update on public.relatorios_combinados to authenticated;
