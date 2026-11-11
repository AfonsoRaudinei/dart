# ADR-060 — NDVI Sentinel refinado (plano Ouro)

**Status:** Aceito  
**Data:** Nov/2026

## Contexto

Usuários Ouro devem receber NDVI Sentinel com catálogo mais rigoroso (nuvem < 30 %),
evalscript com faixa 0,2–0,4 distinta e metadados de cobertura real, sem custo Planet
adicional (mesma resolução 10 m).

## Decisão

1. Edge `ndvi-fetch`: JWT opcional; com usuário autenticado, consulta `user_plans`
   (`plano=ouro`, `ativo=true`, `expira_em > now()`). Admin **não** habilita refinado.
2. Caminho `sentinel_refined` tentado antes do Sentinel padrão (80 %); falha cai no
   fluxo legado, não pula para Planet.
3. App: contrato `INdviRefinedEntitlement` em `core/contracts/`; adapter em `planos/`
   registrado no `main.dart`. Módulo `ndvi/` não importa `planos/`.
4. Cache NDVI: fingerprint `bbox|geometry|standard|refined` conforme entitlement.
5. UI/máscara: `sentinel_refined` com rótulo, pílulas 10 m e hint cobertura baixa;
   máscara verde inclui amarelo-esverdeado do colormap refinado.

## Consequências

- Upgrade Ouro invalida cache NDVI (tier no fingerprint).
- Deploy Supabase obrigatório para `ndvi-fetch` com auth + evalscript refinado.
