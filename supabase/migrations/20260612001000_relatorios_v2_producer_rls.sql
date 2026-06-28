-- SoloForte — leitura de relatorios_v2 para produtor vinculado.
-- Mantem o produtor restrito aos relatorios do cliente aceito via token.

create table if not exists public.relatorios_v2 (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  titulo text not null,
  descricao text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete cascade,
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz,
  visit_session_id uuid,
  occurrence_ids text
);

alter table public.relatorios_v2
  add column if not exists client_id uuid references public.clients(id) on delete set null;

create index if not exists idx_relatorios_v2_client_id
  on public.relatorios_v2(client_id);

create index if not exists idx_relatorios_v2_created_by
  on public.relatorios_v2(created_by);

alter table public.relatorios_v2 enable row level security;

drop policy if exists "relatorios_v2_select_owner" on public.relatorios_v2;
create policy "relatorios_v2_select_owner"
  on public.relatorios_v2 for select to authenticated
  using (created_by = auth.uid() and deleted_at is null);

drop policy if exists "relatorios_v2_insert_owner" on public.relatorios_v2;
create policy "relatorios_v2_insert_owner"
  on public.relatorios_v2 for insert to authenticated
  with check (
    created_by = auth.uid()
    and client_id is not null
    and exists (
      select 1 from public.clients c
      where c.id = client_id
        and c.user_id = auth.uid()
        and c.deleted_at is null
    )
  );

drop policy if exists "relatorios_v2_update_owner" on public.relatorios_v2;
create policy "relatorios_v2_update_owner"
  on public.relatorios_v2 for update to authenticated
  using (created_by = auth.uid())
  with check (
    created_by = auth.uid()
    and client_id is not null
    and exists (
      select 1 from public.clients c
      where c.id = client_id
        and c.user_id = auth.uid()
        and c.deleted_at is null
    )
  );

drop policy if exists "relatorios_v2_select_linked_producer" on public.relatorios_v2;
create policy "relatorios_v2_select_linked_producer"
  on public.relatorios_v2 for select to authenticated
  using (
    deleted_at is null
    and exists (
      select 1
      from public.producer_client_links l
      where l.client_id = relatorios_v2.client_id
        and l.producer_user_id = auth.uid()
        and l.status = 'active'
    )
  );
