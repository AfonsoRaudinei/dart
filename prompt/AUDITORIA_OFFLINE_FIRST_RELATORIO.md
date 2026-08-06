# AUDITORIA OFFLINE-FIRST — SOLOFORTE

**Tipo:** AUDITORIA — leitura e análise. Sem execução de código de produção.  
**Gate:** Obrigatório antes de qualquer merge para `release/`.  
**Data:** 2026-08-05  
**Agente:** Revisor de Arquitetura Sênior Flutter/Dart — Offline-First / SQLite  
**Declaração:** `@MÓDULO: PERSISTENCIA_OFFLINE`  
**Bounded contexts:** `core` · `drawing` · `consultoria` · `agenda` · `visitas` · `map`  
**Nota:** `operacao/` = placeholder (ADR-044); sessões vivem em `visitas/` + `agenda/`.  
**Nota:** `consultoria/agenda/` **AUSENTE** (ADR-018 confirmado).

**Autoridade (ordem):**
1. `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`
2. `docs/02_ARQUITETURA_ATIVA/arquitetura-persistencia.md`
3. `docs/02_ARQUITETURA_ATIVA/arquitetura-ocorrencias.md`
4. `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`
5. `AGENTS.md` (schema **v40**)

> Se código e documento conflitarem → documento é a autoridade.

**Prompts de remediação (pós-aprovação, execução separada):**
- `prompt/sync/PROMPT_FIX_DRAWING_SOFT_DELETE_SYNC.md`
- `prompt/sync/PROMPT_FIX_PULL_LOCAL_WINS.md`
- `prompt/sync/PROMPT_FIX_PUBLICACOES_DDL_MIGRATION.md`

---

```
════════════════════════════════════════
AUDITORIA OFFLINE-FIRST — SOLOFORTE
════════════════════════════════════════

PASSO 0 — ARQUIVOS ENCONTRADOS:

database_helper.dart:
  lib/core/database/database_helper.dart

sync_*.dart:
  lib/core/services/sync_retry_runner.dart
  lib/core/services/sync_module_runner.dart
  lib/core/services/sync_orchestrator.dart
  lib/core/services/sync_service.dart
  lib/core/services/sync_status_contract.dart
  lib/app/sync_registration.dart

*_repository_impl.dart:
  lib/modules/settings/data/repositories/user_profile_repository_impl.dart
  lib/modules/planos/data/repositories/plano_repository_impl.dart
  lib/modules/consultoria/relatorios/repositories/relatorio_repository_impl.dart
  lib/modules/consultoria/publicacoes/repositories/publicacao_repository_impl.dart
  lib/modules/carteira/data/repositories/carteira_repository_impl.dart
  lib/modules/clima/data/repositories/clima_repository_impl.dart
  lib/modules/ndvi/data/repositories/ndvi_repository_impl.dart
  lib/modules/marketing/data/repositories/marketing_case_repository_impl.dart

*sync*.dart (extras de módulo):
  lib/modules/drawing/data/data_sources/drawing_sync_service.dart
  lib/modules/drawing/domain/models/drawing_sync_result.dart
  lib/modules/drawing/domain/services/async_geometry_service.dart
  lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart
  lib/modules/consultoria/services/agronomic_sync_service.dart
  lib/modules/marketing/data/services/marketing_sync_service.dart
  lib/modules/agenda/data/services/agenda_sync_service.dart
  lib/modules/visitas/data/repositories/visit_sync_service.dart

connectivity*.dart:
  lib/core/providers/connectivity_provider.dart
  lib/core/services/connectivity_service.dart

*offline*.dart:
  lib/ui/components/map/widgets/map_offline_widgets.dart
  lib/core/services/offline_tile_cache_service.dart

sync_status*.dart:
  lib/core/services/sync_status_contract.dart

*worker*.dart:
  (nenhum)

Extras relevantes:
  lib/modules/drawing/data/data_sources/drawing_remote_store.dart
  lib/ui/components/sync/conflict_resolution_dialog.dart  (zero call sites)
  android/app/src/main/AndroidManifest.xml  (SCHEDULE_EXACT_ALARM)

DIMENSÃO 1 — SYNC STATUS: ⚠️ PARCIAL
  Achados:
  - Contrato canônico existe em SyncStatusContract:
    local_only | pending_sync | synced | sync_error | deleted_local
    (+ legado pending/local). Evidência: sync_status_contract.dart:5-50
  - Sem antipadrão bool isSynced.
  - 🟠 ALTO: 3 modelos paralelos no mesmo app —
    (1) strings canônicas; (2) INTEGER 0/1/2 (agronomic/visitas/quick_photos);
    (3) enums divergentes (drawing.conflict; occurrence legado;
    map pending/conflict/error).
  - 🟡 MÉDIO: updateOccurrence escreve 'updated' (occurrence_repository.dart:86);
    toMap() chama normalize() → desconhecido vira local_only
    (occurrence.dart:243). Push ainda inclui local_only — dado não some.
  - 🟡 MÉDIO: Drawing SyncStatus.conflict fora do contrato
    (drawing_models.dart:147-151).
  Evidência: lib/core/services/sync_status_contract.dart:5-50

DIMENSÃO 2 — PERSISTÊNCIA IMEDIATA: OK
  Achados:
  - Drawing: local_only → DrawingLocalStore.insert → sync só depois. OK.
  - Ocorrência: OccurrenceController.createOccurrence → saveOccurrence SQLite.
    OccurrenceController está em consultoria; mapa só dispara. OK.
  - StartEventUseCase: agenda + sessão locais; mirror visit_sessions via
    contrato (falha engolida — ver D6). OK quanto a SQLite-first.
  - Relatório: RelatorioRepositoryImpl.save SQLite-first.
    ReportRepositoryImpl inexistente; caminho = adapter + use case. OK.
  - Sem RAM-only confirmado nos 4 fluxos do escopo.
  - Marketing saveCase (fora do escopo) mistura upsert remoto na mesma chamada.
  Evidência: drawing_local_store / occurrence_repository /
    start_event_use_case / relatorio_repository_impl / generate_relatorio_use_case

DIMENSÃO 3 — SOFT DELETE: ⚠️ PARCIAL / ❌ CRÍTICO em drawing
  Achados:
  - Fields/talhões: OK (deleted_at + dirty; listagem filtra).
  - Occurrences: OK (deleted_local + deleted_at; push inclui deleted).
  - Relatórios: soft delete local OK; mutate sem user_id (D6).
  - Agenda events: sync_status='deleted' sem deleted_at;
    getAllEvents NÃO filtra deletados (agenda_repository.dart:78-88);
    fila getPendingSyncEvents só pending_sync/pending — delete NÃO sincroniza.
  - Drawings: CRÍTICO — ver ciclo abaixo.
  - Visit sessions: só finished; sem soft-delete de domínio.
  - Hard deletes pontuais em caches (clima/ndvi) e wipe de conta: by design.

  🔴 CRÍTICO — ciclo soft-delete drawing:
  1. drawing_local_store.dart:138-143 — soft delete seta deleted_at+ativo=0
     SEM sync_status=deleted_local
  2. getPendingSync = sync_status != 'synced' (linhas 194-204) —
     feature já synced NÃO entra no push
  3. drawing_remote_store.dart:111 — push força 'deleted_at': null
  4. Pull: getById filtra deleted_at IS NULL → local==null → reinsere remoto
     → RESSURREIÇÃO
  Contrato doc §4: deleted_at + sync_status=deleted_local. Código viola.

DIMENSÃO 4 — GATILHOS DE SYNC: ⚠️ PARCIAL
  Achados:
  - Reconexão (connectivity_plus): PRESENTE
    ConnectivityService → SyncOrchestrator._initObservers
  - Cold start: PRESENTE (main.dart:332-339 + registerSyncModules)
  - Manual: PRESENTE (side menu → manualSyncProvider)
  - Timer in-process 15 min: PRESENTE (sync_orchestrator.dart:62-64)
  - WorkManager/BackgroundFetch: AUSENTE (doc exige; zero no pubspec/lib)
  - Módulos registrados: Agronomic, Drawing, Occurrence, Visit, Agenda
    (Marketing FORA do orchestrator)
  - 🟡 MÉDIO: dual listener (SyncOrchestrator + SyncService ao abrir menu)

  SCHEDULE_EXACT_ALARM: PRESENTE
  Evidência: android/app/src/main/AndroidManifest.xml:12
  Justificado para lembretes de agenda (AgendaNotificationService),
  NÃO para sync. Não é blocker de sync; Play Console ainda exige
  declaração de uso (docs/android/RELEASE.md).

DIMENSÃO 5 — RESOLUÇÃO DE CONFLITOS: ⚠️ PARCIAL / 🟠 ALTO
  Contrato: "Local vence temporariamente até confirmação explícita" /
  "NUNCA sobrescrever trabalho de campo silenciosamente"
  (arquitetura-persistencia.md:99-105).

  Achados:
  - Drawing: pending → conflict (protege); synced+remote newer → replace. OK parcial.
  - Occurrences: pending statuses skip replace. OK.
  - Visits: sync_status==1 skip. OK.
  - 🔴 CRÍTICO (agronomic): shouldApplyRemote (agronomic_sync_service.dart:391-400)
    Dirty + remote NEWER → aplica remoto — viola contrato.
  - 🟠 ALTO (agenda): pull só por updated_at (agenda_sync_service.dart:168-172)
    sem checagem pending_sync — pode sobrescrever pending local.
  - UUID collision: upsert onConflict:'id' — sobrescreve, sem fork.
  - ConflictResolutionDialog existe e NÃO é usado (zero call sites).
  - Drawing resolveUseLocal/resolveUseRemote sem UI wired.

DIMENSÃO 6 — ISOLAMENTO user_id: ⚠️ PARCIAL
  Achados:
  - 2 DBs: soloforte.db v40 + marketing_cases.db
  - Leituras principais filtram user_id / agronomist_id / ownership orphan
  - 🟠 ALTO: RelatorioRepositoryImpl.softDelete/update/markAsSynced
    filtram só por id (relatorio_repository_impl.dart:179-191)
  - Logout: invalidate → clear identity → signOut; NÃO limpa SQLite
    (by design, session_controller.dart:372-379)
  - Delete account: wipe → invalidate → signOut (ordem OK)
  - 🟡 MÉDIO: visitCompletionObserverProvider keepAlive:true
    sem registerLogoutInvalidation
  - 🟠 ALTO: StartEventUseCase engole falha do mirror agenda→visit_sessions

DIMENSÃO 7 — DRAWINGREMOTESTORE: IMPLEMENTADO
  Achados:
  - NÃO é stub. push/fetchUpdates reais via Supabase; rethrow em erro.
  - ADR-037 aprovado; baseline marca stub ENCERRADO.
  - Riscos residuais: soft-delete cycle (D3); fetchUpdates(null) full pull
    sempre (drawing_sync_service.dart:85); prompts legados ainda dizem "stub".
  Evidência: lib/modules/drawing/data/data_sources/drawing_remote_store.dart:15-66

DIMENSÃO 8 — SYNC NA CAMADA ERRADA: OK (com cheiro)
  Achados:
  - Sem sync em build()/dispose() de widgets.
  - Cold start em main.initState pós-frame = composição aceitável.
  - Manual sync via provider OK.
  - Borderline: controllers de presentation disparam orchestrator pós-CRUD;
    marketing retry em provider próprio.

DIMENSÃO 9 — SCHEMA SQLite: versão confirmada v40
  Achados:
  - Runtime: version: 40 (database_helper.dart:27). AGENTS.md alinhado.
  - Prompt de auditoria citava v38 — divergência do prompt, não do código.
  - onUpgrade → _runMigrations cases v1–v40.
  - deleted_at/sync_status presentes nas tabelas-chave
    (occurrences.deleted_at desde v38).
  - 🔴 CRÍTICO adjacente: migrateToV12 é no-op
    (database_migrations_v1_v23.dart:369-372);
    DDL de publicacoes_tecnicas só em doc (publicacao_table.dart) —
    install limpo pode crashar ao inserir publicação.
  - Sem migration de normalização de valores legados de sync_status.
  - Skill soloforte-task ainda cita v38 (doc drift).

════════════════════════════════════════
DIMENSÃO 10 — PONTO DE AMARRAÇÃO
════════════════════════════════════════

DIAGRAMA DE DEPENDÊNCIAS:

[Campo / UI]
    → [RepositoryImpl / LocalStore]  sync_status=local_only|pending
        → [DatabaseHelper soloforte.db v40]
[ConnectivityService / connectivity_plus]
    → [SyncOrchestrator]  ← cold start + reconnect + 15min + manual
        → [SyncModuleRunner por tier]
            → AgronomicSyncService / DrawingSyncService
              / OccurrenceSyncService / VisitSyncService / AgendaSyncService
                → RemoteStores / Supabase upsert
                    → sync_status → synced | conflict | (falha: pending preservado)
[clearUserLocalData] ← só deleteAccount / Settings wipe
[signOut] ← logout SEM wipe (preserva SQLite)

Elo central existente: SyncOrchestrator + SyncStatusContract + DatabaseHelper.
OfflineSyncCoordinator unificado: NÃO EXISTE.

ELOS FRACOS IDENTIFICADOS:
1. Drawing soft-delete → não entra na fila → pull ressuscita  [🔴 CRÍTICO]
2. Agronomic/Agenda pull sobrescreve pending/dirty silenciosamente  [🔴/🟠]
3. ConflictResolutionDialog morto — conflito drawing sem resolução UX  [🟠]
4. Sem WorkManager — sync só com processo vivo  [🟠]
5. Três modelos de sync_status no mesmo DB  [🟠]
6. Marketing/publicações fora do orchestrator / tabela sem CREATE  [🔴/🟠]
7. Mirror agenda→visitas engolido  [🟠]

COMPONENTE CENTRAL RECOMENDADO (NÃO CRIAR NESTA AUDITORIA):
  OfflineSyncCoordinator (core/services)
  Responsabilidades propostas:
  - Única porta de registro de módulos sync
  - Enforce SyncStatusContract + soft-delete canônico
    (deleted_local + deleted_at)
  - Política única de conflito: local pending nunca sobrescrito
    sem confirmação
  - Gatilhos: connectivity + cold start + manual (+ WorkManager futuro)
  - Hook logout: invalidar keepAlive user-scoped
  - Telemetria: contagem pending/conflict/error por módulo

ÂNCORA DE VALIDAÇÃO ATUAL:
  SyncOrchestrator.triggerSync
  + SyncStatusContract.normalize
  + soft-delete com deleted_local
  Qualquer módulo que bypassar essa tríade é elo fraco.

════════════════════════════════════════
RESUMO EXECUTIVO
════════════════════════════════════════

Itens CRÍTICOS 🔴: 3
  1. Drawing soft-delete/ressurreição
  2. Agronomic overwrite dirty (shouldApplyRemote)
  3. publicacoes_tecnicas sem CREATE na migração

Itens ALTOS 🟠: 6
  1. Agenda overwrite pending no pull
  2. Agenda delete não sincroniza / listagem não filtra
  3. Relatório mutate sem user_id
  4. Mirror StartEventUseCase engolido
  5. ConflictResolutionDialog sem call sites
  6. WorkManager ausente (doc exige)

Itens MÉDIOS 🟡: 7
  Modelos sync paralelos; 'updated'→local_only; drawing conflict;
  dual listeners; keepAlive observer; full pull drawing; doc v38 drift

Itens BAIXOS 🟢: 4
  Logout preserva SQLite (by design); nome ReportRepositoryImpl;
  filename migrations; enum morto occurrence

Próximos passos (ordenados por risco) — prompts separados:
1. prompt/sync/PROMPT_FIX_DRAWING_SOFT_DELETE_SYNC.md
2. prompt/sync/PROMPT_FIX_PULL_LOCAL_WINS.md
3. prompt/sync/PROMPT_FIX_PUBLICACOES_DDL_MIGRATION.md
4. (futuro) Unificar soft-delete agenda + filtro listagem + push
5. (futuro) Escopar user_id em mutações de relatório; mirror visit
6. (futuro) Wire ConflictResolutionDialog ou remover dívida
7. (futuro) WorkManager + OfflineSyncCoordinator
8. (futuro) Normalizar INTEGER/string sync_status

════════════════════════════════════════
ENCERRAMENTO
════════════════════════════════════════

Esta auditoria NÃO altera módulos, rotas, estado ou contratos de produção.
Produto = este RELATÓRIO + PONTO DE AMARRAÇÃO + 3 prompts de remediação.
Toda execução decorrente dos achados exige aprovação explícita do prompt
correspondente.
```
