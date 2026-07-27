-- ============================================================
-- SoloForte — ADR-048: ACL edição / aprovação cruzada marketing
-- Data: 2026-07-27
-- ============================================================

alter table public.marketing_cases
  add column if not exists pending_edit_json jsonb;

alter table public.marketing_cases
  add column if not exists pending_edit_by uuid;

alter table public.marketing_cases
  add column if not exists pending_edit_at timestamptz;

comment on column public.marketing_cases.pending_edit_json is
  'Payload JSON da edição proposta pela contraparte (ADR-048).';
comment on column public.marketing_cases.pending_edit_by is
  'user_id de quem propôs a edição pendente.';
comment on column public.marketing_cases.pending_edit_at is
  'Timestamp da proposta de edição.';
