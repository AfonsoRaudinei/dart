-- ============================================================
-- SoloForte — Colunas do payload agronômico remoto
-- Data: 2026-08-25
--
-- Alinhamento ao payload do IPA 225 + PT da 20260605.
-- O app novo faz push só PT; aliases EN existem para o live
-- continuar aceitando IPA 225 e pull de schema legado.
-- Sem UPDATE em colunas EN (podem não existir). Sem DROP.
-- ============================================================

alter table public.clients
  add column if not exists cidade text,
  add column if not exists uf text,
  add column if not exists foto_path text,
  add column if not exists observacoes text,
  add column if not exists data_nascimento text,
  add column if not exists cpf_cnpj text,
  add column if not exists area_total numeric,
  add column if not exists tipo_propriedade text,
  add column if not exists sistema_irrigacao text,
  add column if not exists solo_tipo text,
  add column if not exists regiao_agricola text,
  add column if not exists safra_atual text,
  add column if not exists usa_assistencia_tecnica integer,
  add column if not exists tecnico_responsavel text,
  add column if not exists ativo integer not null default 1,
  add column if not exists name text,
  add column if not exists document text,
  add column if not exists phone text,
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists area_ha numeric;

alter table public.farms
  add column if not exists client_id uuid,
  add column if not exists name text,
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists area_ha numeric;

alter table public.fields
  add column if not exists farm_id uuid,
  add column if not exists name text,
  add column if not exists area_ha numeric,
  add column if not exists geometry jsonb;

notify pgrst, 'reload schema';
