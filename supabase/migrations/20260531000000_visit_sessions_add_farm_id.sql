-- Mantém o contexto completo do check-in durante sincronização entre dispositivos.
alter table public.visit_sessions
  add column if not exists farm_id text;
