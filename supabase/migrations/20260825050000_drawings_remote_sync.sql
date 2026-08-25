-- ============================================================
-- SoloForte — ADR-021/027 · drawing sync via DrawingRemoteStore
-- Data: 2026-08-25
--
-- Espelho remoto de DrawingFeature (SQLite local).
-- Sem sync_status remoto — controle local apenas.
-- Sem DELETE físico — exclusão lógica via deleted_at.
-- Políticas idempotentes com to authenticated (padrão ADR-051).
-- ============================================================

create table if not exists public.drawings (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  geometry    jsonb not null default '{}',
  properties  jsonb not null default '{}',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

alter table public.drawings enable row level security;

drop policy if exists "drawings_select" on public.drawings;
drop policy if exists "drawings_insert" on public.drawings;
drop policy if exists "drawings_update" on public.drawings;
drop policy if exists "drawings_select_own" on public.drawings;
drop policy if exists "drawings_insert_own" on public.drawings;
drop policy if exists "drawings_update_own" on public.drawings;

create policy "drawings_select_own"
  on public.drawings for select to authenticated
  using (user_id = auth.uid());

create policy "drawings_insert_own"
  on public.drawings for insert to authenticated
  with check (user_id = auth.uid());

create policy "drawings_update_own"
  on public.drawings for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create index if not exists idx_drawings_user_updated
  on public.drawings (user_id, updated_at desc);

create index if not exists idx_drawings_user_deleted
  on public.drawings (user_id, deleted_at);

grant select, insert, update on public.drawings to authenticated;

notify pgrst, 'reload schema';
