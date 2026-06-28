-- SoloForte — vinculo produtor-consultor por token
-- Permite que uma conta produtor veja, em leitura, dados de um client
-- cadastrado pelo consultor apos aceitar um convite.

create extension if not exists pgcrypto;

create table if not exists public.producer_client_links (
  id uuid primary key default gen_random_uuid(),
  consultor_user_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,
  producer_user_id uuid references auth.users(id) on delete set null,
  token_hash text not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'active', 'revoked', 'expired')),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_producer_links_consultor
  on public.producer_client_links(consultor_user_id, status);

create index if not exists idx_producer_links_producer
  on public.producer_client_links(producer_user_id, status);

create index if not exists idx_producer_links_client
  on public.producer_client_links(client_id);

alter table public.producer_client_links enable row level security;

drop policy if exists "producer_links_select_consultor" on public.producer_client_links;
drop policy if exists "producer_links_insert_consultor" on public.producer_client_links;
drop policy if exists "producer_links_update_consultor" on public.producer_client_links;
drop policy if exists "producer_links_select_producer" on public.producer_client_links;

create policy "producer_links_select_consultor"
  on public.producer_client_links for select to authenticated
  using (auth.uid() = consultor_user_id);

create policy "producer_links_insert_consultor"
  on public.producer_client_links for insert to authenticated
  with check (
    auth.uid() = consultor_user_id
    and exists (
      select 1 from public.perfis p
      where p.id = auth.uid()
        and lower(p.role) = 'consultor'
    )
    and exists (
      select 1 from public.clients c
      where c.id = client_id
        and c.user_id = auth.uid()
        and c.deleted_at is null
    )
  );

create policy "producer_links_update_consultor"
  on public.producer_client_links for update to authenticated
  using (
    auth.uid() = consultor_user_id
    and exists (
      select 1 from public.perfis p
      where p.id = auth.uid()
        and lower(p.role) = 'consultor'
    )
  )
  with check (
    auth.uid() = consultor_user_id
    and exists (
      select 1 from public.perfis p
      where p.id = auth.uid()
        and lower(p.role) = 'consultor'
    )
  );

create policy "producer_links_select_producer"
  on public.producer_client_links for select to authenticated
  using (auth.uid() = producer_user_id and status = 'active');

create or replace function public.accept_producer_link_token(p_token text)
returns public.producer_client_links
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hash text;
  v_link public.producer_client_links;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1 from public.perfis p
    where p.id = auth.uid()
      and lower(p.role) = 'produtor'
  ) then
    raise exception 'producer_role_required';
  end if;

  v_hash := encode(digest(upper(regexp_replace(coalesce(p_token, ''), '[[:space:]]+', '', 'g')), 'sha256'), 'hex');

  select *
    into v_link
    from public.producer_client_links
   where token_hash = v_hash
     and status = 'pending'
     and expires_at > now()
   limit 1
   for update;

  if not found then
    raise exception 'invalid_or_expired_token';
  end if;

  if v_link.consultor_user_id = auth.uid() then
    raise exception 'self_link_not_allowed';
  end if;

  update public.producer_client_links
     set producer_user_id = auth.uid(),
         status = 'active',
         used_at = now(),
         updated_at = now()
   where id = v_link.id
   returning * into v_link;

  return v_link;
end;
$$;

revoke all on function public.accept_producer_link_token(text) from public;
revoke all on function public.accept_producer_link_token(text) from anon;
grant execute on function public.accept_producer_link_token(text) to authenticated;

drop policy if exists "clients_select_linked_producer" on public.clients;
create policy "clients_select_linked_producer"
  on public.clients for select to authenticated
  using (
    exists (
      select 1 from public.producer_client_links l
      where l.client_id = clients.id
        and l.producer_user_id = auth.uid()
        and l.status = 'active'
    )
  );

drop policy if exists "farms_select_linked_producer" on public.farms;
create policy "farms_select_linked_producer"
  on public.farms for select to authenticated
  using (
    exists (
      select 1 from public.producer_client_links l
      where l.client_id = farms.cliente_id
        and l.producer_user_id = auth.uid()
        and l.status = 'active'
    )
  );

drop policy if exists "fields_select_linked_producer" on public.fields;
create policy "fields_select_linked_producer"
  on public.fields for select to authenticated
  using (
    exists (
      select 1
        from public.farms f
        join public.producer_client_links l on l.client_id = f.cliente_id
       where f.id = fields.fazenda_id
         and l.producer_user_id = auth.uid()
         and l.status = 'active'
    )
  );
