# ADR-050 — `IMarketingCaseReportsLookup` para Relatórios → Marketing

**Data:** 08/08/2026  
**Atualizado:** 15/08/2026 — aba **Marketing** (antes “Gerados”); status **Marketing** / **Não gerado**  
**Status:** APROVADO  
**Módulos:** `core/contracts/`, `marketing/`, `consultoria/relatorios/`

## Contexto

`relatorios_page.dart` importava diretamente `marketing/` (entidade, providers, `EditCaseSheet`),
violando REGRA-CROSS-MODULE-2 (`consultoria → marketing`).

## Decisão

1. DTO neutro `MarketingCaseReportSnapshot` em `core/contracts/`.
2. Interface `IMarketingCaseReportsLookup` (delete, edit sheet, **publishDraftCase**, export bundle).
3. Provider `marketingCaseReportsListProvider` para lista visível na aba **Marketing**.
4. Implementação `MarketingCaseReportsLookupAdapter` em `marketing/infra/`.
5. Registro em `main.dart` via `ProviderScope.overrides`.

`consultoria/relatorios/` consome apenas contratos em `core/contracts/`.

### UX Relatórios → Marketing (Ago/2026)

| Superfície | Valor |
|---|---|
| Segmento na barra | **Marketing** (enum interno `gerados`) |
| Aba padrão ao abrir Relatórios | Marketing |
| Case publicado | status **Marketing** |
| Rascunho | status **Não gerado**; ação **Publicar** no menu |
| Filtros de status | Todas · Marketing · Não gerados |

## Consequências

- `arch_check.sh` não acusa `consultoria → marketing` em `relatorios_page.dart`.
- Entidade `MarketingCase` permanece congelada (ADR-011); adapter traduz DTO ↔ entidade.
- Rascunhos (`draft`) listados via adapter; publicação com checagem de limite de plano.
