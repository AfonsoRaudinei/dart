-- Pin Bronze no mapa: produtor do vínculo vê se o consultor tem Bronze+ ativo.
-- Não exige plano do produtor (diferente de ocorrência compartilhada).

create or replace function public.list_bronze_pin_client_ids_for_producer()
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
     and public.consultor_pode_compartilhar_ocorrencias(link.consultor_user_id);
$$;

grant execute on function public.list_bronze_pin_client_ids_for_producer() to authenticated;

notify pgrst, 'reload schema';