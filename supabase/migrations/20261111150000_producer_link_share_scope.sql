-- O consultor escolhe o que o convite libera.
-- Outro consultor também pode aceitar o token. A leitura continua só o que foi marcado.

alter table public.producer_client_links
  add column if not exists share_farms boolean not null default true;

alter table public.producer_client_links
  add column if not exists share_fields boolean not null default true;

alter table public.producer_client_links
  add column if not exists share_occurrences boolean not null default true;

alter table public.producer_client_links
  add column if not exists share_reports boolean not null default true;

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
      and lower(p.role) in ('produtor', 'consultor')
  ) then
    raise exception 'share_role_required';
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

drop policy if exists "farms_select_linked_producer" on public.farms;
create policy "farms_select_linked_producer"
  on public.farms for select to authenticated
  using (
    exists (
      select 1 from public.producer_client_links l
      where l.client_id = farms.cliente_id
        and l.producer_user_id = auth.uid()
        and l.status = 'active'
        and (l.share_farms or l.share_fields)
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
         and l.share_fields
    )
  );

drop policy if exists occurrences_select_authorized on public.occurrences;
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
        and link.share_occurrences
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
        and l.share_reports
    )
  );

notify pgrst, 'reload schema';
