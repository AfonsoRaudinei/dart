-- Ocorrência no vínculo: consultor e produtor precisam Bronze+ ativo (ou admin).
-- consultor_pode_compartilhar_ocorrencias = gate de plano Bronze+ para qualquer usuário.

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
     and public.consultor_pode_compartilhar_ocorrencias(link.consultor_user_id)
     and public.consultor_pode_compartilhar_ocorrencias(auth.uid());
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
        and public.consultor_pode_compartilhar_ocorrencias(auth.uid())
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
