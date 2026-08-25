-- repair — migration 20260531000000 registrada mas coluna ausente no live.
alter table public.visit_sessions add column if not exists farm_id text;
notify pgrst, 'reload schema';
