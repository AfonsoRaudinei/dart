-- Ocorrência no vínculo: consultor precisa Bronze+ ativo (ou admin).

create or replace function public.consultor_pode_compartilhar_ocorrencias(p_consultor_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
        from auth.users u
       where u.id = p_consultor_id
         and lower(
           coalesce(
             u.raw_user_meta_data->>'role',
             u.raw_app_meta_data->>'role',
             ''
           )
         ) = 'admin'
    )
    or exists (
      select 1
        from public.user_plans up
       where up.user_id = p_consultor_id
         and up.ativo = true
         and up.expira_em > now()
         and up.plano in ('bronze', 'prata', 'ouro')
    );
$$;

grant execute on function public.consultor_pode_compartilhar_ocorrencias(uuid) to authenticated;

create or replace function public.list_occurrence_share_client_ids_for_producer()
returns table(client_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  select distinct link.client_id
    from public.producer_client_links link
   where link.producer_user_id = auth.uid()
     and link.status = 'active'
     and link.share_occurrences
     and public.consultor_pode_compartilhar_ocorrencias(link.consultor_user_id);
$$;

grant execute on function public.list_occurrence_share_client_ids_for_producer() to authenticated;

drop policy if exists occurrences_select_authorized on public.occurrences;
create policy occurrences_select_authorized
  on public.occurrences for select to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1
      from public.producer_client_links link
      where link.producer_user_id = auth.uid()
        and link.status = 'active'
        and link.share_occurrences
        and public.consultor_pode_compartilhar_ocorrencias(link.consultor_user_id)
        and (
          link.client_id = occurrences.client_id
          or exists (
            select 1
              from public.farms f
              join public.fields fi on fi.fazenda_id = f.id
             where f.cliente_id = link.client_id
               and fi.id::text = occurrences.field_id
               and f.deleted_at is null
               and fi.deleted_at is null
          )
        )
    )
  );

notify pgrst, 'reload schema';