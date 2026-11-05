alter table public.occurrences
  add column if not exists audio_path text,
  add column if not exists audio_duration_sec integer;
