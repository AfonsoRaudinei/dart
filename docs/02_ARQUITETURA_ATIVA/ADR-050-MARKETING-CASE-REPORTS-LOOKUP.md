# ADR-050 — `IMarketingCaseReportsLookup` para Relatórios → Gerados

**Data:** 08/08/2026  
**Status:** APROVADO  
**Módulos:** `core/contracts/`, `marketing/`, `consultoria/relatorios/`

## Contexto

`relatorios_page.dart` importava diretamente `marketing/` (entidade, providers, `EditCaseSheet`),
violando REGRA-CROSS-MODULE-2 (`consultoria → marketing`).

## Decisão

1. DTO neutro `MarketingCaseReportSnapshot` em `core/contracts/`.
2. Interface `IMarketingCaseReportsLookup` (delete, edit sheet, export bundle).
3. Provider `marketingCaseReportsListProvider` para lista visível na aba Gerados.
4. Implementação `MarketingCaseReportsLookupAdapter` em `marketing/infra/`.
5. Registro em `main.dart` via `ProviderScope.overrides`.

`consultoria/relatorios/` consome apenas contratos em `core/contracts/`.

## Consequências

- `arch_check.sh` não acusa `consultoria → marketing` em `relatorios_page.dart`.
- Entidade `MarketingCase` permanece congelada (ADR-011); adapter traduz DTO ↔ entidade.
