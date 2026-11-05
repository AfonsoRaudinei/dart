alter table public.occurrences
  add column if not exists amostra_codigo text,
  add column if not exists amostra_coletor text,
  add column if not exists amostra_tramite text,
  add column if not exists amostra_laudo_texto text,
  add column if not exists amostra_analises_json text;
