-- Leitura do vínculo ativo não depende mais dos 7 dias do token.
-- expires_at continua valendo só em accept_producer_link_token, enquanto
-- o convite está pending.

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
    )
  );

notify pgrst, 'reload schema';
