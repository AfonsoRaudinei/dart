create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  type text,
  message text not null,
  rating integer,
  created_at timestamptz default now()
);

alter table public.feedback
  add column if not exists module text,
  add column if not exists impact text;

alter table public.feedback enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'feedback'
      and policyname = 'feedback_insert'
  ) then
    create policy "feedback_insert"
      on public.feedback
      for insert
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'feedback'
      and policyname = 'feedback_own_select'
  ) then
    create policy "feedback_own_select"
      on public.feedback
      for select
      using (auth.uid() = user_id);
  end if;
end $$;
