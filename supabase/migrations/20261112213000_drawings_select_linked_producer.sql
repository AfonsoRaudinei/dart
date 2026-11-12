-- Produtor ativo pode ler desenhos do cliente vinculado (`share_fields`).

drop policy if exists "drawings_select_linked_producer" on public.drawings;
create policy "drawings_select_linked_producer"
  on public.drawings for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.producer_client_links l
      where l.producer_user_id = auth.uid()
        and l.status = 'active'
        and l.share_fields
        and l.client_id::text = coalesce(properties->>'cliente_id', '')
    )
  );

notify pgrst, 'reload schema';
