-- Ocorrências sem client_id preenchido ainda pertencem ao cliente quando o
-- field_id aponta para um talhão da fazenda vinculada.

alter table public.occurrences
  add column if not exists field_id text;

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
         and (l.share_fields or l.share_occurrences)
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
      where link.producer_user_id = auth.uid()
        and link.status = 'active'
        and link.share_occurrences
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
