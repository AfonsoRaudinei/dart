# SOLOFORTE Baseline Real
<!-- Última verificação: Março/2026 (pós-auditoria) -->
<!-- Commit de referência: 51c5c99 | Branch: release/v1.1 -->

| Item | Valor |
|---|---|
| Mapa padrão | Google Satellite (`MapConfig.googleSatelliteUrl`) — padrão global |
| Arquivos Dart em `lib/` | 436 |
| Módulos em `lib/modules/` | 17 (agenda, auth, carteira, clima, consultoria, dashboard, drawing, feedback, map, marketing, ndvi, operacao, planos, public, settings, visitas) |
| Banco de dados | `soloforte.db` único — SQLite (sqflite) |
| Schema DB versão atual | **v29** (`_migrateToV29` — `closed_percent` em `carteira_lancamentos`) |
| flutter analyze — erros | 0 |
| flutter analyze — issues totais | 65 (infos/warnings pré-existentes, nenhum erro) |
| arch_check.sh | ✅ APROVADO — EXIT 0 |
| Testes verdes | 612 ✅ — 2 falhas pré-existentes (drawing_intersection + drawing_import — não relacionadas à Sessão 3) |
| TODOs em produção | 45 |
| Providers keepAlive | 21 |
| Interfaces formais DIP | 26 |
| Arquivos >900 linhas (legados) | 5 monitorados (WARN controlado) |
| .baseline_marker | ✅ Criado em 23/03/2026 |
| repairOrphanUserIds | ✅ Implementado (`database_helper.dart` linha 1133) |
| Logout seguro | ✅ clear → invalidate → signOut (`session_controller.dart`) |
| Isolamento user_id | ✅ 6 repositórios corrigidos (Sessão 3) |

---

## Schema DB — Histórico de Versões Confirmadas

| Versão | Conteúdo | Status |
|---|---|---|
| v17–v20 | Migrações diversas (confirmado no código) | ✅ Aplicado |
| v21 | `user_id` adicionado em todas as tabelas locais | ✅ Aplicado |
| v22 | Migração de schema (confirmado no código) | ✅ Aplicado |
| v23 | Migração de schema (confirmado no código) | ✅ Aplicado |
| v24 | Migração de schema (confirmado no código) | ✅ Aplicado |
| v25 | Migração de schema (confirmado no código) | ✅ Aplicado |
| v26 | Migração de schema (confirmado no código) | ✅ Aplicado |
| v27 | NDVI: recriação de `ndvi_cache` (schema atualizado) | ✅ Aplicado |
| v28 | `occurrences.client_id` (nullable, vínculo opcional com cliente) | ✅ Aplicado |
| v29 | `carteira_lancamentos.closed_percent` (nullable) | ✅ Aplicado |

> **Nota:** O baseline anterior documentava `marketing_cases.db` e `visitas_tecnicas.db` como bancos separados.
> Verificação 0.16 confirma que há **apenas `soloforte.db`** — banco único. A dívida documental foi corrigida aqui.

---

## ADRs Referenciados no Código (confirmados por grep)

| ADR | Status no código |
|---|---|
| ADR-007 | ✅ Referenciado |
| ADR-008 | ✅ Referenciado |
| ADR-009 | ✅ Referenciado (relatorios — offline-first) |
| ADR-010 | ✅ Referenciado |
| ADR-012 | ✅ Referenciado (planos/) |
| ADR-014 | ✅ Referenciado |
| ADR-015 | ✅ Referenciado (client_stats_service) |
| ADR-016 | ✅ Referenciado |
| ADR-017 | ✅ Referenciado |
| ADR-019 | ✅ Referenciado (IVisitClientLookup) |
| ADR-020 | ✅ Referenciado (consultoria↔visitas desacoplado) |
| ADR-022 | ✅ Referenciado |
| ADR-018/021 | ⚠️ Presentes nos ADRs mas não encontrados no código — podem ser dos docs/ |

---

## Features — Status Pós-Auditoria (24/03/2026)

| Feature | Status | Localização |
|---|---|---|
| Occurrence Client Link (cliente opcional em ocorrência) | ✅ IMPLEMENTADO | `database_helper.dart` (v28), `occurrence.dart` (`clientId`), `occurrence_sync_service.dart` (`client_id` push/pull), `occurrence_client_selector.dart`, `occurrence_creation_sheet.dart` |
| GPS Walk / Gravar Rota | ✅ IMPLEMENTADO | `drawing/domain/models/gps_walk_session.dart`, `gps_walk_controller.dart`, `gps_walk_providers.dart`, `gps_walk_metrics_bar.dart`, `gps_walk_bottom_bar.dart`, `gps_walk_controls_overlay.dart` |
| NDVI Panel | ✅ IMPLEMENTADO | `lib/modules/ndvi/presentation/widgets/ndvi_panel_widget.dart` (444 linhas, provider real, 0 TODOs) |
| Marketing PASSO 6 (long press → NovoCaseSheet) | ✅ IMPLEMENTADO | `private_map_screen.dart` + `private_map_sheets.dart` |
| Marketing PASSO 7 (pins no mapa) | ✅ IMPLEMENTADO | `isolated_marker_layers.dart` via `marketingCasesProvider` |
| Planos pagos (Bronze/Prata/Ouro) | ✅ IMPLEMENTADO | `lib/modules/planos/` — ADR-012 |
| repairOrphanUserIds no login | ✅ IMPLEMENTADO | `database_helper.dart:1133` + chamada em `session_controller.dart:85` |
| Logout seguro (clear→invalidate→signOut) | ✅ IMPLEMENTADO | `session_controller.dart` |

---

## Arquivos >900 Linhas (Monitorados pelo arch_check)

| Arquivo | Linhas | Status |
|---|---|---|
| `drawing/presentation/controllers/drawing_controller.dart` | 1.492 | ⚠️ WARN (exceção legada) |
| `drawing/presentation/widgets/drawing_sheet.dart` | 1.318 | ⚠️ WARN (exceção legada) |
| `core/database/database_helper.dart` | 1.177 | ⚠️ WARN (exceção legada — ADR: banco legado monolítico) |
| `drawing/domain/drawing_utils.dart` | 1.171 | ⚠️ WARN (exceção legada) |
| `ui/components/map/map_occurrence_sheet.dart` | 1.089 | ⚠️ WARN (exceção legada) |

> arch_check confirma: "Nenhum arquivo **novo** ultrapassa 900 linhas" — enforcement funciona.

---

## Enum do Mapa — Divergência Documentada

> ⚠️ **DIVERGÊNCIA CONFIRMADA (verificação 0.15)**
>
> - **Contrato anterior documentava:** `enum MapContext { tecnico, clima, ocorrencias, publicacoes, ndvi }`
> - **Código real usa:** `enum ArmedMode { none, occurrences, marketing }` — localizado em `private_map_screen.dart:65`
> - **Status:** divergência de nomenclatura e valores — o código funciona, mas o contrato estava desatualizado
> - **Ação sugerida:** ADR formal para renomear `ArmedMode` → `MapContext` ou atualizar contrato

---

## Estado de Saúde — Pós-Auditoria Mar/2026

| Verificação | Resultado |
|---|---|
| flutter analyze — erros | ✅ 0 erros |
| flutter analyze — issues totais | 65 (todos `info`/`deprecated_member_use` pré-existentes) |
| arch_check.sh | ✅ EXIT 0 — APROVADO |
| Testes | 612 ✅ / 2 ❌ (falhas pré-existentes em drawing — não relacionadas à Sessão 3) |
| Schema DB | v29 — soloforte.db (banco único) |
| ADRs formais confirmados no código | 12 (ADR-007 a ADR-022) |
| .baseline_marker | ✅ Ativo — enforcement REGRA 3 funciona |
| repairOrphanUserIds | ✅ Implementado |
| Logout seguro | ✅ Implementado |
| Isolamento user_id — 6 repos | ✅ Corrigido (Sessão 3) |

---

## Dívidas Técnicas — Estado Atual

### ✅ Resolvidas (Sessões 1–3)

| Item | Resolução |
|---|---|
| ~~Logout sem clear/invalidate~~ | ✅ RESOLVIDO — Sessão 2 |
| ~~SELECTs sem user_id em 6 repositórios~~ | ✅ RESOLVIDO — Sessão 3 (`visit_repository`, `occurrence_repository`, `sqlite_report_repository`, `relatorio_repository_impl`, `publicacao_repository_impl`, `client_stats_service`) |
| ~~repairOrphanUserIds ausente~~ | ✅ RESOLVIDO — Sessão 3 |
| ~~.baseline_marker ausente~~ | ✅ RESOLVIDO — Sessão 2 |

### ⏳ Pendentes

| Item | Prioridade | Arquivo | Ação necessária |
|---|---|---|---|
| Golden de auth (`register_golden_test.dart`) falhando fora do escopo de occurrences | **Médio** — dívida técnica conhecida | `test/auth/register_golden_test.dart` | Investigar causa raiz e atualizar golden apenas em task dedicada |
| Sub-rota `publicacao/edit` dentro de `/map` | **Alto** — viola contrato Map-First | `app_router.dart:102` | Remover GoRoute, converter para overlay |
| `visit_controller` usa `AgendaRepository` concreto | **Médio** — ADR-018 regredido | `visitas/presentation/controllers/visit_controller.dart:38` | Migrar para `IAgendaRepository` |
| `occurrence_list_sheet` importa `visitas/` diretamente | **Médio** — violação de bounded context | `occurrence_list_sheet.dart:11` | Usar contrato em `core/contracts/` |
| `relatorios` sem coluna `user_id` — usa `agronomist_id` como isolamento | **Médio** — isolamento parcial funciona, mas sem coluna canônica | `relatorio_table.dart` | ADR futuro + migração de schema |
| `ArmedMode` vs `MapContext` — divergência de nomenclatura | **Baixo** | `private_map_screen.dart:65` | Alinhar nome via ADR ou atualizar contrato |
| 3 FABs no overlay de desenho | **Médio** — viola contrato FAB único | `map_controls_overlay.dart` | Refatorar para SmartButton único |
| 2 falhas em testes do módulo drawing | **Médio** — pré-existentes, não relacionadas à Sessão 3 | `drawing_intersection_realtime_test.dart`, `drawing_import_service_test.dart` | Investigar e corrigir |

---

*Atualizado em: 24/04/2026 | Branch: `release/v1.1` | Pós-feature Occurrence Client Link + schema v29*
*Pós-auditoria 23/03/2026 + Sessões 1, 2, 3 + vínculo opcional de cliente em occurrences + carteira v29*
