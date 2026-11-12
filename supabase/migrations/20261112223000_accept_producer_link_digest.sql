-- digest() do pgcrypto fica no schema extensions no projeto hospedado.
-- A função de aceite forçava search_path = public e quebrava com
-- "function digest(text, unknown) does not exist" antes de gravar o vínculo.
-- O app mostrava só "Não foi possível vincular agora".

create or replace function public.accept_producer_link_token(p_token text)
returns public.producer_client_links
language plpgsql
security definer
set search_path = public, extensions
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

  v_hash := encode(
    extensions.digest(
      upper(regexp_replace(coalesce(p_token, ''), '[[:space:]]+', '', 'g')),
      'sha256'
    ),
    'hex'
  );

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

notify pgrst, 'reload schema';
