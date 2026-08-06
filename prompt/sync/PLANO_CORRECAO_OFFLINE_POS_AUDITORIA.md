# PLANO DE CORREÇÃO — OFFLINE-FIRST (PÓS-AUDITORIA)

**Fonte:** `prompt/AUDITORIA_OFFLINE_FIRST_RELATORIO.md`  
**Atualizado:** 2026-08-06  
**Branch:** `cursor/offline-audit-fixes-aaf2`  
**Schema:** SQLite **v41**

---

## Checklist final

| # | Correção | Risco | Status | % |
|---|---|---|---|---|
| Docs | Relatório + 3 prompts de remediação | — | FEITO | 100% |
| 1 | Drawing soft-delete canônico + anti-ressurreição | 🔴 | FEITO | 100% |
| 2 | Agenda soft-delete `deleted_local` + filtro + push | 🟠 | FEITO | 100% |
| 3 | VisitController invalidação no logout | 🟡 | FEITO | 100% |
| 4 | Agronomic pull: dirty local nunca sobrescrito | 🔴 | FEITO | 100% |
| 5 | Agenda pull: pending local nunca sobrescrito | 🟠 | FEITO | 100% |
| 6 | Migração real `publicacoes_tecnicas` (v41) | 🔴 | FEITO | 100% |
| 7 | Relatório mutate com escopo `agronomist_id` | 🟠 | FEITO | 100% |
| 8 | StartEventUseCase: mirror não engole falha (rethrow) | 🟠 | FEITO | 100% |
| 9 | ConflictResolutionDialog wired no sheet drawing | 🟠 | FEITO | 100% |
| 10 | WorkManager / sync em background | 🟠 | **ADIADO** | 0% |
| 11 | Unificar INTEGER vs string `sync_status` | 🟡 | **ADIADO** | 0% |
| 12 | Occurrence `'updated'` → `pending_sync` | 🟡 | FEITO | 100% |
| 13 | OfflineSyncCoordinator unificado | 🟢 | **ADIADO** | 0% |

### Consolidado

| Camada | Feito | Total | % |
|---|---|---|---|
| Documentação | 4/4 | 4 | **100%** |
| Código gate release (críticos+altos #1–9, #12) | 11/11 | 11 | **100%** |
| Dívida controlada (#10, #11, #13) | 0/3 | 3 | **0%** |
| **Geral (docs + código gate)** | **15/15** | 15 | **100%** |
| **Geral incluindo dívida futura** | **15/18** | 18 | **~83%** |

---

## Ainda falta (dívida controlada — NÃO bloqueia gate mínimo)

1. **WorkManager / BackgroundFetch** — sync só com app vivo (timer 15 min + reconnect + cold start + manual). Avaliação Play/iOS pendente.
2. **Unificação INTEGER vs string `sync_status`** — agronomic/visitas ainda usam 0/1; contrato canônico é string. Migration + adapters.
3. **`OfflineSyncCoordinator`** — consolidação opcional; hoje `SyncOrchestrator` + `SyncStatusContract` funcionam como âncora.

---

## Gate `release/` offline-first

- [x] Soft-delete drawing
- [x] Soft-delete agenda + pull local-wins
- [x] Agronomic local-wins
- [x] DDL publicações v41
- [x] Relatório scoped
- [x] Mirror visit observável
- [x] Conflict UI wired
- [x] Occurrence pending_sync canônico
- [ ] WorkManager (opcional / fase futura)

**Veredito:** gate mínimo de correção crítica/alta da auditoria — **APROVADO** (dívida #10/#11/#13 documentada).
