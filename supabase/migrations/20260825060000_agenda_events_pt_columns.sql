-- ============================================================
-- SoloForte — Colunas PT do payload agenda_events remoto
-- Data: 2026-08-25
--
-- Live tem schema EN legado (producer_id, area_id, activity_type,
-- scheduled_date, description, realized_at). App novo envia PT;
-- aliases EN no push; pull com fallback PT→EN.
-- ============================================================

alter table public.agenda_events
  add column if not exists tipo text,
  add column if not exists cliente_id uuid,
  add column if not exists fazenda_id uuid,
  add column if not exists talhao_id uuid,
  add column if not exists titulo text,
  add column if not exists data_inicio_planejada timestamptz,
  add column if not exists data_fim_planejada timestamptz,
  add column if not exists serie_id uuid,
  add column if not exists start_time text,
  add column if not exists end_time text,
  add column if not exists priority text,
  add column if not exists latitude float8,
  add column if not exists longitude float8;

update public.agenda_events
set
  tipo = coalesce(tipo, activity_type),
  cliente_id = coalesce(cliente_id, producer_id),
  talhao_id = coalesce(talhao_id, area_id),
  titulo = coalesce(titulo, description, ''),
  data_inicio_planejada = coalesce(data_inicio_planejada, scheduled_date),
  data_fim_planejada = coalesce(
    data_fim_planejada,
    realized_at,
    scheduled_date + interval '1 hour'
  )
where
  tipo is null
  or cliente_id is null
  or data_inicio_planejada is null;

notify pgrst, 'reload schema';
