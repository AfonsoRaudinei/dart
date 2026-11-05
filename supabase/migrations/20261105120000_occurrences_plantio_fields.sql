alter table public.occurrences
  add column if not exists data_emergencia text,
  add column if not exists sementes_por_metro double precision,
  add column if not exists estande_plantas integer,
  add column if not exists avaliacao_plantio text,
  add column if not exists objetivo_plantio text;
