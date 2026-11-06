alter table public.occurrences
  add column if not exists recomendacao_acao text,
  add column if not exists recomendacao_dose text,
  add column if not exists recomendacao_quando text;
