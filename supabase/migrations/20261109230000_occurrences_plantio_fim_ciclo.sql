alter table public.occurrences
  add column if not exists data_fim_plantio text,
  add column if not exists ciclo_dias integer;
