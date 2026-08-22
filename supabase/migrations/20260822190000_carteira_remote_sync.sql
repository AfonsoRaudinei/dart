-- ============================================================
-- SoloForte — ADR-051: espelho remoto da Carteira
-- Data: 2026-08-22
--
-- Espelha as 7 tabelas SQLite já existentes (v22–v39).
-- Só acrescenta metadados de sync: sync_status, deleted_at, updated_at.
-- Sem FK para public.clients (cliente_id sem referência — evita ordem de pull).
-- Sem DELETE físico. Sem policy anônima.
-- INTEGER 0/1 do SQLite → smallint (consistente no Dart).
-- ============================================================

create table if not exists public.carteira_tipos_produto (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  codigo text not null,
  label text not null,
  converte_sacas_ha smallint not null default 0,
  sistema smallint not null default 0,
  ativo smallint not null default 1,
  ordem integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz,
  unique (user_id, codigo)
);

create table if not exists public.carteira_categorias (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  nome text not null,
  cor text not null default '#4ADE80',
  ativo smallint not null default 1,
  ordem integer not null default 0,
  valor_real numeric,
  valor_dolar numeric,
  sacas_por_ha numeric,
  unidade text,
  valor_referencia numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz
);

create table if not exists public.carteira_config (
  user_id uuid primary key references auth.users(id),
  valor_grao numeric not null default 0,
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz
);

create table if not exists public.carteira_safras (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  nome text not null,
  data_inicio timestamptz not null,
  data_fim timestamptz not null,
  ativa smallint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz
);

create table if not exists public.carteira_metas (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  safra_id uuid not null,
  categoria_id uuid not null,
  quantidade numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz,
  unique (user_id, safra_id, categoria_id)
);

create table if not exists public.carteira_cliente_categorias (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  cliente_id text not null,
  categoria_id uuid not null,
  percentual_fechado integer not null default 0,
  observacao text,
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz
);

create table if not exists public.carteira_lancamentos (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  safra_id uuid not null,
  categoria_id uuid not null,
  cliente_id text not null,
  quantidade numeric not null,
  observacao text,
  data_lancamento timestamptz not null,
  created_at timestamptz not null default now(),
  tipo_fechamento text,
  nome_concorrente text,
  motivo_fechamento text,
  data_fechamento timestamptz,
  closed_percent numeric not null default 0,
  updated_at timestamptz not null default now(),
  sync_status text not null default 'pending_sync',
  deleted_at timestamptz
);

create index if not exists idx_carteira_tipos_produto_user
  on public.carteira_tipos_produto(user_id);

create index if not exists idx_carteira_categorias_user
  on public.carteira_categorias(user_id);

create index if not exists idx_carteira_safras_user
  on public.carteira_safras(user_id);

create index if not exists idx_carteira_metas_user
  on public.carteira_metas(user_id);

create index if not exists idx_carteira_cliente_categorias_user
  on public.carteira_cliente_categorias(user_id);

create index if not exists idx_carteira_lancamentos_user
  on public.carteira_lancamentos(user_id);

alter table public.carteira_tipos_produto enable row level security;
alter table public.carteira_categorias enable row level security;
alter table public.carteira_config enable row level security;
alter table public.carteira_safras enable row level security;
alter table public.carteira_metas enable row level security;
alter table public.carteira_cliente_categorias enable row level security;
alter table public.carteira_lancamentos enable row level security;

drop policy if exists "carteira_tipos_produto_select_own" on public.carteira_tipos_produto;
drop policy if exists "carteira_tipos_produto_insert_own" on public.carteira_tipos_produto;
drop policy if exists "carteira_tipos_produto_update_own" on public.carteira_tipos_produto;

create policy "carteira_tipos_produto_select_own"
  on public.carteira_tipos_produto for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_tipos_produto_insert_own"
  on public.carteira_tipos_produto for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_tipos_produto_update_own"
  on public.carteira_tipos_produto for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "carteira_categorias_select_own" on public.carteira_categorias;
drop policy if exists "carteira_categorias_insert_own" on public.carteira_categorias;
drop policy if exists "carteira_categorias_update_own" on public.carteira_categorias;

create policy "carteira_categorias_select_own"
  on public.carteira_categorias for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_categorias_insert_own"
  on public.carteira_categorias for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_categorias_update_own"
  on public.carteira_categorias for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "carteira_config_select_own" on public.carteira_config;
drop policy if exists "carteira_config_insert_own" on public.carteira_config;
drop policy if exists "carteira_config_update_own" on public.carteira_config;

create policy "carteira_config_select_own"
  on public.carteira_config for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_config_insert_own"
  on public.carteira_config for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_config_update_own"
  on public.carteira_config for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "carteira_safras_select_own" on public.carteira_safras;
drop policy if exists "carteira_safras_insert_own" on public.carteira_safras;
drop policy if exists "carteira_safras_update_own" on public.carteira_safras;

create policy "carteira_safras_select_own"
  on public.carteira_safras for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_safras_insert_own"
  on public.carteira_safras for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_safras_update_own"
  on public.carteira_safras for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "carteira_metas_select_own" on public.carteira_metas;
drop policy if exists "carteira_metas_insert_own" on public.carteira_metas;
drop policy if exists "carteira_metas_update_own" on public.carteira_metas;

create policy "carteira_metas_select_own"
  on public.carteira_metas for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_metas_insert_own"
  on public.carteira_metas for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_metas_update_own"
  on public.carteira_metas for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "carteira_cliente_categorias_select_own" on public.carteira_cliente_categorias;
drop policy if exists "carteira_cliente_categorias_insert_own" on public.carteira_cliente_categorias;
drop policy if exists "carteira_cliente_categorias_update_own" on public.carteira_cliente_categorias;

create policy "carteira_cliente_categorias_select_own"
  on public.carteira_cliente_categorias for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_cliente_categorias_insert_own"
  on public.carteira_cliente_categorias for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_cliente_categorias_update_own"
  on public.carteira_cliente_categorias for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "carteira_lancamentos_select_own" on public.carteira_lancamentos;
drop policy if exists "carteira_lancamentos_insert_own" on public.carteira_lancamentos;
drop policy if exists "carteira_lancamentos_update_own" on public.carteira_lancamentos;

create policy "carteira_lancamentos_select_own"
  on public.carteira_lancamentos for select to authenticated
  using (user_id = auth.uid());
create policy "carteira_lancamentos_insert_own"
  on public.carteira_lancamentos for insert to authenticated
  with check (user_id = auth.uid());
create policy "carteira_lancamentos_update_own"
  on public.carteira_lancamentos for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update on public.carteira_tipos_produto to authenticated;
grant select, insert, update on public.carteira_categorias to authenticated;
grant select, insert, update on public.carteira_config to authenticated;
grant select, insert, update on public.carteira_safras to authenticated;
grant select, insert, update on public.carteira_metas to authenticated;
grant select, insert, update on public.carteira_cliente_categorias to authenticated;
grant select, insert, update on public.carteira_lancamentos to authenticated;
