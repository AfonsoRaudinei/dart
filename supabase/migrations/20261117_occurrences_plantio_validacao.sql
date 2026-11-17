alter table if exists occurrences
  add column if not exists data_validacao text,
  add column if not exists avaliacao_emergencia text;