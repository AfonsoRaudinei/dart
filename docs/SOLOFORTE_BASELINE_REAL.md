# SOLOFORTE Baseline Real
<!-- Última verificação: Jun/2026 -->
<!-- Commit de referência: d1fbaf9 | Branch: release/v1.1 -->

## Snapshot Oficial — Jun/2026

Este documento substitui o snapshot de Março/2026 como baseline operacional.
O estado atual foi sincronizado a partir do PRD de Auditoria SoloForte v1.0
e das verificações locais executadas nesta sessão.

| Item | Valor |
|---|---|
| Mapa padrão | Google Satellite (`MapConfig.googleSatelliteUrl`) — padrão global |
| Arquivos Dart em `lib/` | 520 |
| Módulos em `lib/modules/` | 16 (agenda, agenda_ai, auth, carteira, clima, consultoria, dashboard, drawing, feedback, map, marketing, ndvi, planos, public, settings, visitas) |
| Banco de dados | `soloforte.db` único — SQLite (sqflite) |
| Schema DB versão atual | **v33** (`_migrateToV33` — contexto opcional de fazenda em visitas) |
| flutter analyze — erros | 0 |
| flutter analyze — issues totais | Sem erros novos documentados no PRD |
| arch_check.sh | ✅ APROVADO — EXIT 0 |
| Testes verdes | 702 aprovados + 1 ignorado ✅ |
| TODOs em produção | A recalcular na próxima auditoria completa |
| Providers keepAlive | 30 ocorrências locais |
| Interfaces formais DIP | 15 ocorrências locais por padrão `abstract class I*` |
| Arquivos >900 linhas (legados) | 5 monitorados (WARN controlado) |
| .baseline_marker | ✅ Criado em 23/03/2026 |
| repairOrphanUserIds | ✅ Implementado (`database_helper.dart` linha 1133) |
| Logout seguro | ✅ clear → invalidate → signOut (`session_controller.dart`) |
| Isolamento user_id | ✅ 6 repositórios corrigidos (Sessão 3) |
| Build iOS | `pubspec.yaml` 1.1.0+111 — IPA pendente de submissão via Transporter |
| `private_map_screen.dart` | 373 linhas — ADR-030/ADR-031 encerrados |

---

## Schema DB — Histórico de Versões Confirmadas

| Versão | Conteúdo | Status |
|---|---|---|
| v17–v33 | Migrações incrementais confirmadas no código; padrão atual com operações idempotentes | ✅ Aplicado |
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
| v30 | Migração intermediária confirmada no código | ✅ Aplicado |
| v31 | Arquivamento idempotente da tabela legada `visit_reports` para `visit_reports_legacy_v31` | ✅ Aplicado |
| v32 | Tabela ativa de relatórios | ✅ Aplicado |
| v33 | `visit_sessions.farm_id` opcional | ✅ Aplicado |

> **Nota:** O baseline anterior documentava `marketing_cases.db` e `visitas_tecnicas.db` como bancos separados.
> Verificação 0.16 confirma que há **apenas `soloforte.db`** — banco único. A dívida documental foi corrigida aqui.
>
> **ADR-034:** `lib/modules/consultoria/reports/` foi removido do mapeamento ativo. A tabela `visit_reports`
> não é schema ativo; qualquer referência remanescente em `database_helper.dart` pertence à migração v31 de legado.

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
| ADR-021 | ⚠️ Presente em documentação histórica |
| ADR-022 | ✅ Referenciado |
| ADR-027 | ✅ Referenciado — padrão visual unificado e REGRA-SHEET-1 |
| ADR-028 | ✅ Referenciado em documentação ativa |
| ADR-029 | ✅ Referenciado em documentação ativa |
| ADR-030 | ✅ Referenciado — decomposição do mapa |
| ADR-031 | ✅ ENCERRADO — `private_map_sheets` decomposto |
| ADR-032 | ✅ Referenciado — settings/user profile |
| ADR-034 | ✅ ENCERRADO — `reports/` removido e `visit_reports` arquivado |

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
| `drawing/presentation/controllers/drawing_controller.dart` | 1.497 | ⚠️ WARN (exceção legada) |
| `core/database/database_helper.dart` | 1.397 | ⚠️ WARN (exceção legada — ADR: banco legado monolítico) |
| `drawing/presentation/widgets/drawing_sheet.dart` | 1.345 | ⚠️ WARN (exceção legada) |
| `drawing/domain/drawing_utils.dart` | 1.171 | ⚠️ WARN (exceção legada) |
| `ui/components/map/map_occurrence_sheet.dart` | 1.094 | ⚠️ WARN (exceção legada) |

> arch_check confirma: "Nenhum arquivo **novo** ultrapassa 900 linhas" — enforcement funciona.
> `private_map_screen.dart` saiu da lista de risco: 373 linhas em Mai/2026.

---

## Enum do Mapa — Divergência Documentada

> ⚠️ **DIVERGÊNCIA CONFIRMADA (verificação 0.15)**
>
> - **Contrato anterior documentava:** `enum MapContext { tecnico, clima, ocorrencias, publicacoes, ndvi }`
> - **Código real usa:** `enum ArmedMode { none, occurrences, marketing }` — localizado em `private_map_screen.dart:65`
> - **Status:** divergência de nomenclatura e valores — o código funciona, mas o contrato estava desatualizado
> - **Ação sugerida:** ADR formal para renomear `ArmedMode` → `MapContext` ou atualizar contrato

---

## Estado de Saúde — Auditoria Jun/2026

| Verificação | Resultado |
|---|---|
| flutter analyze — erros | ✅ 0 erros |
| flutter analyze — issues totais | Sem erros novos documentados no PRD |
| arch_check.sh | ✅ EXIT 0 — APROVADO; REGRA-SHEET-1 ativa |
| Testes | 702 aprovados + 1 ignorado ✅ |
| Schema DB | v33 — soloforte.db (banco único) |
| ADRs formais confirmados | 008–022, 027–033, 037; ADR-031, ADR-034 e DT-028 encerrados |
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
| Supabase Redirect URLs ausentes (`soloforte://reset-password`, `soloforte://login`) | **Crítico** | Supabase Auth URL Configuration | Configurar manualmente no dashboard |
| `user_plans.is_admin` ausente no Supabase | **Crítico** | Supabase SQL Editor | Executar `ALTER TABLE ... ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE` e atualizar UUID admin |
| IPA build 111 pendente | **Alto** | `build/ios/ipa/*.ipa` | Submeter via Transporter |
| `GeneratedPluginRegistrant.swift` rastreado pelo Git | **Médio** | `macos/Flutter/GeneratedPluginRegistrant.swift` | Adicionar ao `.gitignore` e remover do tracking |
| Golden de auth (`register_golden_test.dart`) falhando fora do escopo de occurrences | **Médio** — dívida técnica conhecida | `test/auth/register_golden_test.dart` | Investigar causa raiz e atualizar golden apenas em task dedicada |
| Sub-rota `publicacao/edit` dentro de `/map` | **Alto** — viola contrato Map-First | `app_router.dart:102` | Remover GoRoute, converter para overlay |
| `visit_controller` usa `AgendaRepository` concreto | **Médio** — ADR-018 regredido | `visitas/presentation/controllers/visit_controller.dart:38` | Migrar para `IAgendaRepository` |
| `occurrence_list_sheet` importa `visitas/` diretamente | **Médio** — violação de bounded context | `occurrence_list_sheet.dart:11` | Usar contrato em `core/contracts/` |
| `relatorios` sem coluna `user_id` — usa `agronomist_id` como isolamento | **Médio** — isolamento parcial funciona, mas sem coluna canônica | `relatorio_table.dart` | ADR futuro + migração de schema |
| `ArmedMode` vs `MapContext` — divergência de nomenclatura | **Baixo** | `private_map_screen.dart:65` | Alinhar nome via ADR ou atualizar contrato |
| 3 FABs no overlay de desenho | **Médio** — viola contrato FAB único | `map_controls_overlay.dart` | Refatorar para SmartButton único |
| 2 falhas em testes do módulo drawing | **Médio** — pré-existentes, não relacionadas à Sessão 3 | `drawing_intersection_realtime_test.dart`, `drawing_import_service_test.dart` | Investigar e corrigir |

### ✅ Resolvidas na Fase 2

| Item | Resolução |
|---|---|
| DT-028 — `showRadarProvider` fora de `MapContext.clima` | ✅ ENCERRADO — radar consome `armedModeProvider == ArmedMode.clima`; `showRadarProvider` não existe como provider ativo |
| `DrawingRemoteStore` stub | ✅ ENCERRADO — implementação Supabase com `SupabaseClient` injetável, push/upsert, fetch por usuário e erro explícito em auth/payload inválido |
| ADRs críticos da Fase 3 | ✅ ADR-033 (`visitas/`) e ADR-037 (`DrawingRemoteStore`) documentados |
| Coverage gate CI | ✅ Fase 4: ratchet incremental implementado em `.github/workflows/architecture.yml`; baseline mínimo 36,46%, alvo 60% |

---

*Atualizado em: Jun/2026 | Branch: `release/v1.1` | PRD Auditoria v1.0 | Schema v33 | Testes 702 aprovados + 1 ignorado*
*Histórico preservado: pós-auditoria 23/03/2026 + Sessões 1, 2, 3 + vínculo opcional de cliente em occurrences + carteira v29*
