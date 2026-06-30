-- ============================================================
-- SoloForte — Security hardening: marketing RLS + storage ownership
-- Data: 2026-06-04
--
-- Objetivo:
-- - Fechar escrita ampla em marketing_cases e marketing_avaliacoes.
-- - Garantir que uploads/deletes no bucket marketing-cases sejam restritos
--   ao prefixo do usuario autenticado.
-- - Preservar leitura publica/autenticada de cases publicados ja existente.
-- ============================================================

alter table public.marketing_cases
  add column if not exists user_id uuid references auth.users(id) on delete set null;

alter table public.marketing_avaliacoes
  add column if not exists user_id uuid references auth.users(id) on delete set null;

create index if not exists idx_marketing_cases_user_id
  on public.marketing_cases(user_id);

create index if not exists idx_marketing_avaliacoes_user_id
  on public.marketing_avaliacoes(user_id);

update public.marketing_avaliacoes ma
set user_id = mc.user_id
from public.marketing_cases mc
where ma.case_id = mc.id
  and ma.user_id is null
  and mc.user_id is not null;

drop policy if exists "authenticated insert cases" on public.marketing_cases;
drop policy if exists "authenticated update cases" on public.marketing_cases;
drop policy if exists "authenticated insert avaliacoes" on public.marketing_avaliacoes;
drop policy if exists "authenticated update avaliacoes" on public.marketing_avaliacoes;
drop policy if exists "avaliacoes_insert_own" on public.marketing_avaliacoes;
drop policy if exists "avaliacoes_update_own" on public.marketing_avaliacoes;

create policy "authenticated insert cases"
  on public.marketing_cases
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "authenticated update cases"
  on public.marketing_cases
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "authenticated insert avaliacoes"
  on public.marketing_avaliacoes
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.marketing_cases mc
      where mc.id = case_id
        and mc.user_id = auth.uid()
    )
  );

create policy "authenticated update avaliacoes"
  on public.marketing_avaliacoes
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.marketing_cases mc
      where mc.id = case_id
        and mc.user_id = auth.uid()
    )
  );

drop policy if exists "authenticated upload marketing photos" on storage.objects;
drop policy if exists "authenticated delete marketing photos" on storage.objects;

create policy "authenticated upload marketing photos"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'marketing-cases'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "authenticated delete marketing photos"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'marketing-cases'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
