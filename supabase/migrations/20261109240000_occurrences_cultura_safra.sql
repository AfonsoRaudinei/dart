alter table public.occurrences
  add column if not exists cultura text,
  add column if not exists safra text;
