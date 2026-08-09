# ADR-051 — Relatórios: visibilidade Gerados e cronologia por produtor

**Data:** 09/08/2026  
**Status:** APROVADO  
**Módulos:** `core/contracts/`, `marketing/`, `consultoria/relatorios/`

## Contexto

A aba **Relatórios** (`consultoria/relatorios/`) agrega visitas técnicas,
ocorrências, publicações de marketing e exports consolidados. Dois riscos
arquiteturais foram identificados:

1. **Gerados (Publicações):** cases em rascunho, pendentes de sync ou
   arquivados não devem aparecer na lista de publicações disponíveis ao
   consultor/produtor.
2. **Cronologia:** consolidar ou exportar dados de produtores distintos sob
   um único relatório gera HTML/CSV/JSON semanticamente incorretos.

O ADR-050 resolveu a fronteira `consultoria ↔ marketing` via contratos.
Este ADR formaliza as **regras de visibilidade e isolamento por `clientId`**
sem alterar a interface `IMarketingCaseReportsLookup`.

## Decisão

### 1. Aba Gerados (Publicações)

A lista em `marketingCaseReportsListProvider` (implementação:
`marketingCaseReportsListImplProvider` em `marketing/infra/`) expõe **somente**
cases que satisfazem **todas** as condições:

| Critério | Regra |
|---|---|
| Status | `MarketingCaseStatus.published` |
| Ativo | `ativo == true` |
| Exclusão | `deletadoEm == null` |
| ACL produtor | `MarketingCaseVisibility.isVisibleInReports` quando `UserRole.isProdutor` |

Consultores veem todos os cases elegíveis; produtores apenas os autorizados
via `authorizedClientIdsProvider`.

`consultoria/relatorios/` consome a lista via `core/contracts` (ADR-050).
A UI de Gerados **não** reimplementa filtro de status — o adapter é fonte
da verdade.

### 2. Cronologia segura por `clientId`

Qualquer operação que **agrega ou exporta** dados de múltiplos registros
deve estar vinculada a um único `clientId`:

| Aba | Escopo | Seleção obrigatória (2+ produtores) |
|---|---|---|
| **Consolidados** | Resumo da Propriedade, Histórico de Visitas, timeline | Sim — chips de produtor |
| **Ocorrências** | Lista de Ocorrências (export) e cards na lista | Sim — chips de produtor |
| **Visitas** | Lista de relatórios de visita | Sim — chips de produtor |
| **Gerados** | Publicações de marketing | Sim — chips quando 2+ `clientId` distintos |

Regras:

- **1 produtor** no dataset → auto-seleção do `clientId`; export/lista habilitados.
- **2+ produtores** → sem seleção: empty state; export e lista desabilitados.
- Nomes de produtor resolvidos via `IClientLookup` (ADR-015).

### 3. Defense-in-depth nos builders de export

Os builders em `relatorios_generated_reports.dart` refiltram por `clientId`
antes de montar HTML/JSON/CSV (`_scopeRelatoriosByClientId`,
`_scopeOccurrencesByClientId`). Se itens fora do escopo forem recebidos,
descartam-se com log (`AppLogger`) — não crasham a UI.

Exports relevantes:

- Resumo da Propriedade — CSV inclui coluna `client_id`.
- Histórico de Visitas — ordenação `periodStart` DESC; linhas com `client_id`.
- Lista de Ocorrências — ordenação `createdAt` DESC; coluna `cliente_id`.

### 4. Referências cruzadas

| ADR | Papel |
|---|---|
| **015** | `IClientLookup` — nomes de produtor nos chips e títulos de export |
| **050** | `IMarketingCaseReportsLookup` + `marketingCaseReportsListProvider` — fronteira marketing ↔ relatorios |

## Consequências

- Regras de visibilidade e cronologia documentadas e auditáveis em CI/review.
- `arch_check.sh` e testes de widget cobrem multi-produtor e status não-publicados.
- Policy de visibilidade Gerados pode ser extraída para `core/contracts`
  (`MarketingCaseReportsListPolicy`) na Fase 2 — adapter delega à policy.
- Aba **Visitas** com filtro por produtor implementado em `relatorios_visit_reports_section.dart`.
- Aba **Gerados** com filtro por produtor quando há 2+ `clientId` distintos no snapshot.
- Cases legados sem `client_id` continuam visíveis quando não há particionamento multi-produtor.
- Aba **Mídia** permanece fora do escopo (sem `clientId` consistente em fotos).
- `smart_button.dart` e Design System **não** são alterados por este ADR.

## Fora de escopo

- Novo método de listagem em `IMarketingCaseReportsLookup` (provider já cumpre).
- Migração/backfill de `client_id` em marketing cases legados.
- Filtro da aba Mídia por produtor.
