-- Diagnóstico de perfil de atendimento (consultoria / clients)
alter table public.clients
  add column if not exists perfil_dominante text,
  add column if not exists perfil_secundario text,
  add column if not exists perfil_pontos_a integer,
  add column if not exists perfil_pontos_b integer,
  add column if not exists perfil_pontos_c integer,
  add column if not exists perfil_pontos_d integer,
  add column if not exists perfil_atualizado_em timestamptz;

notify pgrst, 'reload schema';