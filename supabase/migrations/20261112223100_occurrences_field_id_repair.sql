-- Reparo idempotente: alinha policy com field_id text (já aplicado manualmente em 122030 no remoto).

alter table public.occurrences
  add column if not exists field_id text;

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
