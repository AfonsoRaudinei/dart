-- ============================================================
-- SoloForte — Marketing cases: janela pública (TTL) por tier
-- Data: 2026-07-23
--
-- Regras de produto:
--   Ouro 6 meses · Prata 4 meses · Bronze 2 meses
--   Expirar = soft-hide do público (NUNCA hard delete)
--   Owner pode renovar (atualiza liberado_em / publico_ate)
-- ============================================================

alter table public.marketing_cases
  add column if not exists liberado_em timestamptz;

alter table public.marketing_cases
  add column if not exists publico_ate timestamptz;

create index if not exists idx_marketing_cases_publico_ate
  on public.marketing_cases(publico_ate)
  where deletado_em is null and ativo = true;

-- Backfill legado: âncora = criado_em + meses do tier
update public.marketing_cases
set
  liberado_em = coalesce(liberado_em, criado_em),
  publico_ate = coalesce(
    publico_ate,
    case lower(coalesce(visibilidade, ''))
      when 'ouro' then criado_em + interval '6 months'
      when 'prata' then criado_em + interval '4 months'
      when 'bronze' then criado_em + interval '2 months'
      else criado_em + interval '4 months'
    end
  )
where deletado_em is null;

-- Leitura anônima: Ouro + janela pública ativa
drop policy if exists "ouro public read" on public.marketing_cases;
create policy "ouro public read"
  on public.marketing_cases
  for select
  using (
    visibilidade = 'ouro'
    and ativo = true
    and deletado_em is null
    and (publico_ate is null or publico_ate > now())
  );

comment on column public.marketing_cases.liberado_em is
  'Início da janela pública (liberação ou renovação).';
comment on column public.marketing_cases.publico_ate is
  'Fim da janela pública. Expirar oculta do público; não apaga o registro.';
