-- ============================================================
-- SoloForte — Agronomic clients full sync
-- Data: 2026-06-05
--
-- Objetivo:
-- - Alinhar o schema remoto ao SQLite local de clientes/fazendas/talhoes.
-- - Preservar colunas legadas em ingles usadas em setups antigos.
-- - Adicionar client_culturas para sincronizacao completa do cadastro.
-- - Garantir isolamento por usuario autenticado via RLS.
-- ============================================================

alter table public.clients
  add column if not exists nome text,
  add column if not exists documento text,
  add column if not exists telefone text,
  add column if not exists cidade text,
  add column if not exists uf text,
  add column if not exists foto_path text,
  add column if not exists observacoes text,
  add column if not exists data_nascimento text,
  add column if not exists cpf_cnpj text,
  add column if not exists area_total numeric,
  add column if not exists tipo_propriedade text,
  add column if not exists sistema_irrigacao text,
  add column if not exists solo_tipo text,
  add column if not exists regiao_agricola text,
  add column if not exists safra_atual text,
  add column if not exists usa_assistencia_tecnica integer,
  add column if not exists tecnico_responsavel text,
  add column if not exists ativo integer not null default 1,
  add column if not exists deleted_at timestamptz;

update public.clients
set
  nome = coalesce(nome, name),
  telefone = coalesce(telefone, phone),
  documento = coalesce(documento, document),
  cpf_cnpj = coalesce(cpf_cnpj, document)
where nome is null
   or telefone is null
   or documento is null
   or cpf_cnpj is null;

alter table public.farms
  add column if not exists cliente_id uuid references public.clients(id) on delete cascade,
  add column if not exists nome text,
  add column if not exists municipio text,
  add column if not exists uf text,
  add column if not exists area_total numeric,
  add column if not exists deleted_at timestamptz;

update public.farms
set
  cliente_id = coalesce(cliente_id, client_id),
  nome = coalesce(nome, name),
  municipio = coalesce(municipio, city),
  uf = coalesce(uf, state),
  area_total = coalesce(area_total, area_ha)
where cliente_id is null
   or nome is null
   or municipio is null
   or uf is null
   or area_total is null;

alter table public.fields
  add column if not exists fazenda_id uuid references public.farms(id) on delete cascade,
  add column if not exists codigo text,
  add column if not exists nome text,
  add column if not exists area_produtiva numeric,
  add column if not exists bordadura_geo text,
  add column if not exists centro_geo text,
  add column if not exists deleted_at timestamptz;

update public.fields
set
  fazenda_id = coalesce(fazenda_id, farm_id),
  nome = coalesce(nome, name),
  area_produtiva = coalesce(area_produtiva, area_ha),
  bordadura_geo = coalesce(bordadura_geo, geometry::text)
where fazenda_id is null
   or nome is null
   or area_produtiva is null
   or bordadura_geo is null;

create table if not exists public.client_culturas (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,
  cultura text not null,
  area_ha numeric not null,
  variedade text,
  safra text,
  observacao text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_clients_user_id
  on public.clients(user_id);

create index if not exists idx_farms_user_id
  on public.farms(user_id);

create index if not exists idx_farms_cliente_id
  on public.farms(cliente_id);

create index if not exists idx_fields_user_id
  on public.fields(user_id);

create index if not exists idx_fields_fazenda_id
  on public.fields(fazenda_id);

create index if not exists idx_client_culturas_user_id
  on public.client_culturas(user_id);

create index if not exists idx_client_culturas_client_id
  on public.client_culturas(client_id);

alter table public.clients enable row level security;
alter table public.farms enable row level security;
alter table public.fields enable row level security;
alter table public.client_culturas enable row level security;

drop policy if exists "clients_select_own" on public.clients;
drop policy if exists "clients_insert_own" on public.clients;
drop policy if exists "clients_update_own" on public.clients;
drop policy if exists "clients_delete_own" on public.clients;

create policy "clients_select_own"
  on public.clients for select to authenticated
  using (auth.uid() = user_id);

create policy "clients_insert_own"
  on public.clients for insert to authenticated
  with check (auth.uid() = user_id);

create policy "clients_update_own"
  on public.clients for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "clients_delete_own"
  on public.clients for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists "farms_select_own" on public.farms;
drop policy if exists "farms_insert_own" on public.farms;
drop policy if exists "farms_update_own" on public.farms;
drop policy if exists "farms_delete_own" on public.farms;

create policy "farms_select_own"
  on public.farms for select to authenticated
  using (auth.uid() = user_id);

create policy "farms_insert_own"
  on public.farms for insert to authenticated
  with check (auth.uid() = user_id);

create policy "farms_update_own"
  on public.farms for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farms_delete_own"
  on public.farms for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists "fields_select_own" on public.fields;
drop policy if exists "fields_insert_own" on public.fields;
drop policy if exists "fields_update_own" on public.fields;
drop policy if exists "fields_delete_own" on public.fields;

create policy "fields_select_own"
  on public.fields for select to authenticated
  using (auth.uid() = user_id);

create policy "fields_insert_own"
  on public.fields for insert to authenticated
  with check (auth.uid() = user_id);

create policy "fields_update_own"
  on public.fields for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "fields_delete_own"
  on public.fields for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists "client_culturas_select_own" on public.client_culturas;
drop policy if exists "client_culturas_insert_own" on public.client_culturas;
drop policy if exists "client_culturas_update_own" on public.client_culturas;
drop policy if exists "client_culturas_delete_own" on public.client_culturas;

create policy "client_culturas_select_own"
  on public.client_culturas for select to authenticated
  using (auth.uid() = user_id);

create policy "client_culturas_insert_own"
  on public.client_culturas for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.clients c
      where c.id = client_id
        and c.user_id = auth.uid()
    )
  );

create policy "client_culturas_update_own"
  on public.client_culturas for update to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.clients c
      where c.id = client_id
        and c.user_id = auth.uid()
    )
  );

create policy "client_culturas_delete_own"
  on public.client_culturas for delete to authenticated
  using (auth.uid() = user_id);
