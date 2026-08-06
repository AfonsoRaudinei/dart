# PLANO DE CORREÇÃO — OFFLINE-FIRST (PÓS-AUDITORIA)

**Fonte:** `prompt/AUDITORIA_OFFLINE_FIRST_RELATORIO.md`  
**Data:** 2026-08-06  
**MacBook:** sincronizado com `origin/main` (SHA match) + branch `cursor/offline-audit-fixes-aaf2` com fixes parciais  
**Escopo:** apenas itens ainda abertos após commits de soft-delete drawing/agenda e logout visitas

---

## Checklist de progresso (auditoria → código)

| # | Correção | Risco | Status | % |
|---|---|---|---|---|
| 1 | Drawing soft-delete canônico + anti-ressurreição | 🔴 | **FEITO** (branch fixes) | 100% |
| 2 | Agenda soft-delete `deleted_local` + filtro listagem + push | 🟠 | **FEITO** (branch fixes) | 100% |
| 3 | InvalidController invalidação no logout | 🟡 | **FEITO** (branch fixes) | 100% |
| 4 | Agronomic pull: dirty local nunca sobrescrito | 🔴 | **PENDENTE** | 0% |
| 5 | Agenda pull: pending local nunca sobrescrito | 🟠 | **PENDENTE** | 0% |
| 6 | Migração real `publicacoes_tecnicas` (v41) | 🔴 | **PENDENTE** | 0% |
| 7 | Relatório mutate com escopo `user_id`/`agronomist_id` | 🟠 | **PENDENTE** | 0% |
| 8 | StartEventUseCase: não engolir falha do mirror | 🟠 | **PENDENTE** | 0% |
| 9 | Wire ou remover `ConflictResolutionDialog` | 🟠 | **PENDENTE** | 0% |
| 10 | WorkManager / sync em background | 🟠 | **PENDENTE** | 0% |
| 11 | Unificar INTEGER vs string `sync_status` | 🟡 | **PENDENTE** | 0% |
| 12 | Occurrence `'updated'` → contrato canônico | 🟡 | **PENDENTE** | 0% |
| 13 | OfflineSyncCoordinator unificado | 🟢 | **PENDENTE** (dívida) | 0% |

**Consolidado**

| Camada | Feito | Total | % |
|---|---|---|---|
| Documentação (relatório + 3 prompts) | 4/4 | 4 | **100%** |
| Correções de código críticas (#1–6) | 2/6 | 6 | **33%** |
| Correções de código altas (#7–10) | 0/4 | 4 | **0%** |
| Médias/baixas (#11–13) | 0/3 | 3 | **0%** |
| **Geral (código da auditoria)** | **3/13** | 13 | **~23%** |
| **Geral (docs + código)** | **7/17** | 17 | **~41%** |

---

## O que já foi commitado nesta rodada

Branch: `cursor/offline-audit-fixes-aaf2`

- Drawing: `deleted_local`, fila de push, `deleted_at` no remote, pull anti-ressurreição, testes
- Agenda: `deleted_local`, filtro listagens, push tombstone + purge, testes
- Visitas: `registerLogoutInvalidation` do `visitControllerProvider`, teste

---

## Plano de correção restante (ordenado por risco)

### FASE A — Críticos restantes (obrigatório antes de `release/`)

#### A1. Agronomic `shouldApplyRemote` — local dirty vence

**Prompt:** `prompt/sync/PROMPT_FIX_PULL_LOCAL_WINS.md` (parte agronomic)  
**Arquivo:** `lib/modules/consultoria/services/agronomic_sync_service.dart` ~391–400  

**Regra:** se `localIsDirty` → `return false` (nunca aplicar remoto silenciosamente).  
**Teste:** matriz dirty × timestamp (dirty+remote newer = false).

#### A2. Agenda pull — skip pending

**Prompt:** `prompt/sync/PROMPT_FIX_PULL_LOCAL_WINS.md` (parte agenda)  
**Arquivo:** `lib/modules/agenda/data/services/agenda_sync_service.dart` ~176–180  

**Regra:** antes de `updateEvent`/`updateSession` por remoto newer, se `SyncStatusContract.isPending(local)` → skip.  
**Nota:** soft-delete push já foi feito; falta só blindagem do pull.

#### A3. Migração `publicacoes_tecnicas` v41

**Prompt:** `prompt/sync/PROMPT_FIX_PUBLICACOES_DDL_MIGRATION.md`  
**Arquivos:** `database_helper.dart` (bump 41), `database_migrations_*.dart`, comentário em `publicacao_table.dart`  

**Regra:** `CREATE TABLE IF NOT EXISTS publicacoes_tecnicas` com DDL do módulo; `migrateToV12` permanece histórico no-op.

---

### FASE B — Altos (logo após A)

#### B1. Relatório — mutações com `agronomist_id`/`user_id`

`RelatorioRepositoryImpl.softDelete` / `update` / `markAsSynced` hoje filtram só por `id`.

#### B2. StartEventUseCase — mirror visit_sessions

Não engolir falha do mirror; falhar de forma observável ou retry/flag `sync_error`.

#### B3. ConflictResolutionDialog

Wire no fluxo drawing `conflict` **ou** remover widget morto + documentar resolução só via API.

#### B4. WorkManager (avaliação)

Doc exige; hoje só timer in-process 15 min. Avaliar impacto iOS/Android + Play Console antes de implementar.

---

### FASE C — Médios (estabilização)

- Normalizar INTEGER/string `sync_status` (migration + `SyncStatusContract`)
- Occurrence: parar de escrever `'updated'`; usar `pending_sync`
- Dual listener SyncService/Orchestrator
- `OfflineSyncCoordinator` (opcional, consolidação)

---

## Critério de gate `release/`

Mínimo sugerido:

- [x] MacBook SHA = `origin/main` (confirmado)
- [x] Soft-delete drawing (fase A do prompt drawing) — nesta branch
- [x] Soft-delete agenda listagem/push — nesta branch
- [ ] **A1** agronomic local-wins
- [ ] **A2** agenda pull local-wins
- [ ] **A3** DDL publicações

Sem A1–A3, gate offline-first permanece **bloqueado** para `release/`.

---

## Como executar

1. Merge/PR de `cursor/offline-audit-fixes-aaf2`  
2. Executar prompts na ordem: `PROMPT_FIX_PULL_LOCAL_WINS` → `PROMPT_FIX_PUBLICACOES_DDL_MIGRATION`  
3. Reavaliar % e só então liberar `release/`
