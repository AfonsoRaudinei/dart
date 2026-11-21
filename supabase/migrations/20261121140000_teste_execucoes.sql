-- ============================================================
-- SoloForte — teste_execucoes (implementação do campo de teste)
-- Espelho offline-first de TesteExecucao (SQLite local).
-- ============================================================

create table if not exists public.teste_execucoes (
  id            text primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  drawing_id    text not null,
  talhao        text,
  implementacao text,
  foto_url      text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table public.teste_execucoes enable row level security;

drop policy if exists "teste_execucoes_select_own" on public.teste_execucoes;
drop policy if exists "teste_execucoes_insert_own" on public.teste_execucoes;
drop policy if exists "teste_execucoes_update_own" on public.teste_execucoes;

create policy "teste_execucoes_select_own"
  on public.teste_execucoes for select to authenticated
  using (user_id = auth.uid());

create policy "teste_execucoes_insert_own"
  on public.teste_execucoes for insert to authenticated
  with check (user_id = auth.uid());

create policy "teste_execucoes_update_own"
  on public.teste_execucoes for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create index if not exists idx_teste_execucoes_user_updated
  on public.teste_execucoes (user_id, updated_at desc);

create index if not exists idx_teste_execucoes_drawing
  on public.teste_execucoes (drawing_id);

grant select, insert, update on public.teste_execucoes to authenticated;

-- Bucket público para foto da implementação do teste
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'teste-execucoes',
  'teste-execucoes',
  true,
  5242880,
  array['image/jpeg','image/png','image/webp','image/heic']
)
on conflict (id) do nothing;

drop policy if exists "public read teste execucao photos" on storage.objects;
create policy "public read teste execucao photos"
  on storage.objects for select
  using (bucket_id = 'teste-execucoes');

drop policy if exists "authenticated upload teste execucao photos" on storage.objects;
create policy "authenticated upload teste execucao photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'teste-execucoes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "authenticated delete teste execucao photos" on storage.objects;
create policy "authenticated delete teste execucao photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'teste-execucoes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

notify pgrst, 'reload schema';