-- Caderno de Solo -> SoloForte: ocorrencias externas e acesso compartilhado.

create extension if not exists pgcrypto;

alter table public.occurrences
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists type text,
  add column if not exists description text,
  add column if not exists photo_path text,
  add column if not exists category text,
  add column if not exists status text,
  add column if not exists cultivar text,
  add column if not exists data_plantio text,
  add column if not exists estadio_fenologico text,
  add column if not exists tipo_ocorrencia text,
  add column if not exists amostra_solo boolean not null default false,
  add column if not exists recomendacoes text,
  add column if not exists metricas_json jsonb,
  add column if not exists nutrientes_json jsonb,
  add column if not exists categorias_json jsonb,
  add column if not exists notas_categorias_json jsonb,
  add column if not exists fotos_categorias_json jsonb,
  add column if not exists external_source text,
  add column if not exists external_analysis_id text,
  add column if not exists analysis_payload jsonb,
  add column if not exists deleted_at timestamptz;

-- Analises sem coordenadas continuam validas e nao geram pin.
alter table public.occurrences alter column geometry drop not null;

update public.occurrences
set latitude = null,
    longitude = null
where (latitude is null) <> (longitude is null)
   or latitude not between -90 and 90
   or longitude not between -180 and 180
   or (latitude = 0 and longitude = 0);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'occurrences_valid_coordinates'
      and conrelid = 'public.occurrences'::regclass
  ) then
    alter table public.occurrences
      add constraint occurrences_valid_coordinates check (
        (latitude is null and longitude is null)
        or (
          latitude between -90 and 90
          and longitude between -180 and 180
          and (latitude <> 0 or longitude <> 0)
        )
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'occurrences_external_identity_unique'
      and conrelid = 'public.occurrences'::regclass
  ) then
    alter table public.occurrences
      add constraint occurrences_external_identity_unique
      unique (external_source, user_id, external_analysis_id);
  end if;
end
$$;

create index if not exists idx_occurrences_user_id
  on public.occurrences(user_id);
create index if not exists idx_occurrences_client_id
  on public.occurrences(client_id);
create index if not exists idx_occurrences_coordinates
  on public.occurrences(latitude, longitude)
  where latitude is not null and longitude is not null and deleted_at is null;
create index if not exists idx_occurrences_external_ids
  on public.occurrences(external_source, external_analysis_id);

create or replace function public.keep_newest_external_occurrence()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if old.external_source is not null
     and new.external_source = old.external_source
     and new.external_analysis_id = old.external_analysis_id
     and new.updated_at < old.updated_at then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists occurrences_keep_newest_external on public.occurrences;
create trigger occurrences_keep_newest_external
before update on public.occurrences
for each row execute function public.keep_newest_external_occurrence();

create table if not exists public.external_analysis_integrations (
  id uuid primary key default gen_random_uuid(),
  external_source text not null,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  credential_hash text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_user_id, external_source)
);

alter table public.external_analysis_integrations enable row level security;
revoke all on public.external_analysis_integrations from anon, authenticated;

alter table public.occurrences enable row level security;

drop policy if exists occurrences_user_policy on public.occurrences;
drop policy if exists occurrences_select_authorized on public.occurrences;
drop policy if exists occurrences_insert_owner on public.occurrences;
drop policy if exists occurrences_update_owner on public.occurrences;
drop policy if exists occurrences_delete_owner on public.occurrences;

create policy occurrences_select_authorized
  on public.occurrences for select to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1
      from public.producer_client_links link
      where link.client_id = occurrences.client_id
        and link.producer_user_id = auth.uid()
        and link.status = 'active'
        and link.expires_at > now()
    )
  );

create policy occurrences_insert_owner
  on public.occurrences for insert to authenticated
  with check (auth.uid() = user_id);

create policy occurrences_update_owner
  on public.occurrences for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy occurrences_delete_owner
  on public.occurrences for delete to authenticated
  using (auth.uid() = user_id);
