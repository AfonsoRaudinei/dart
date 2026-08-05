# PROMPT FIX — DRAWING SOFT-DELETE SYNC (RESSURREIÇÃO)

**Fonte:** `prompt/AUDITORIA_OFFLINE_FIRST_RELATORIO.md` — Dimensão 3 (CRÍTICO)  
**Agente:** Engenheiro Sênior Flutter/Dart — Offline-First / Drawing  
**Prioridade:** 🔴 CRÍTICO — exclusão local de geometria pode ressuscitar no pull  
**Tipo:** correção de código · escopo fechado · zero improviso  
**Declaração:** `@MÓDULO: PERSISTENCIA_OFFLINE`

---

## 0️⃣ PASSO 0 — OBRIGATÓRIO

```bash
find lib/ -name "drawing_local_store.dart"
find lib/ -name "drawing_remote_store.dart"
find lib/ -name "drawing_sync_service.dart"
find lib/ -name "drawing_models.dart"
find lib/ -name "sync_status_contract.dart"
rg -n "deleted_at|getPendingSync|soft.?delete|SyncStatus\.|deleted_local" \
  lib/modules/drawing/ lib/core/services/sync_status_contract.dart
```

Ler `lib/modules/drawing/AGENTS.md` e `docs/02_ARQUITETURA_ATIVA/arquitetura-persistencia.md` §4.

---

## 1️⃣ DECLARAÇÃO

```
Módulo:       lib/modules/drawing/
Bounded ctx:  drawing (+ core SyncStatusContract)
Objetivo:     Soft-delete de drawing propaga ao remoto e não ressuscita no pull
Arquivos:     drawing_local_store.dart, drawing_remote_store.dart,
              drawing_sync_service.dart, drawing_models.dart (se necessário),
              testes em test/modules/drawing/
Contrato:     NÃO altera contratos cross-module; alinha ao SyncStatusContract
Fronteira:    NÃO
```

---

## 2️⃣ BUG CONFIRMADO (evidência da auditoria)

1. `DrawingLocalStore.delete` seta `deleted_at` + `ativo=0` **sem** `sync_status = deleted_local`  
   → `drawing_local_store.dart` ~138–143
2. `getPendingSync` = `sync_status != 'synced'` → feature já `synced` **não entra** no push após soft-delete  
   → ~194–204
3. `DrawingRemoteStore._toRemoteRow` força `'deleted_at': null`  
   → `drawing_remote_store.dart:111`
4. Pull: `getById` filtra `deleted_at IS NULL` → `local == null` → reinsere remoto → **ressurreição**  
   → `drawing_sync_service.dart` loop de pull

Contrato doc: `deleted_at` preenchido + `sync_status = deleted_local`.

---

## 3️⃣ CORREÇÃO OBRIGATÓRIA (checklist fechado)

### A) Soft-delete local canônico

Em `DrawingLocalStore.delete` (ou caminho equivalente usado pelo controller):

- Setar `deleted_at = now()` (ISO UTC)
- Setar `ativo = 0`
- Setar `sync_status` para valor canônico de delete:
  - Preferir string alinhada a `SyncStatusContract.deletedLocal` (`'deleted_local'`)
  - Se o enum `drawing_models.SyncStatus` **não** tiver `deleted_local`, adicionar o valor **ou** persistir a string canônica na coluna TEXT sem quebrar `fromJson`
- **Não** hard-delete

### B) Fila de push inclui deletes

`getPendingSync` (ou query equivalente) deve incluir registros com:

- `sync_status != 'synced'` **OU**
- `sync_status = 'deleted_local'` / equivalente **OU**
- (`deleted_at IS NOT NULL` AND ainda não confirmado remoto)

Garantir que soft-deleted (mesmo ex-`synced`) entra na fila de push.

### C) Push envia `deleted_at` real

Em `DrawingRemoteStore._toRemoteRow`:

- **Remover** o hardcode `'deleted_at': null`
- Enviar `deleted_at` da feature local (ISO UTC ou `null` se ativo)
- Manter `sync_status` **fora** do payload remoto (controle local apenas — ADR-037)

### D) Pull aplica soft-delete remoto sem ressuscitar

Em `DrawingSyncService` pull loop:

1. Se remoto tem `deleted_at != null`:
   - Aplicar soft-delete local (`deleted_at`, `ativo=0`, `sync_status=synced` após aplicar delete remoto **ou** manter `deleted_local` só até push — escolher um e documentar no PR)
   - **Não** reinserir como ativo
2. Se local está soft-deleted e remoto ainda ativo (pendência de push):
   - **Não** sobrescrever com remoto ativo (local delete vence até confirmação)
3. `getById` usado no merge de pull deve conseguir achar registro soft-deleted (query sem filtro `deleted_at IS NULL`, ou método `getByIdIncludingDeleted`)

### E) Enum / contrato

- Não introduzir `bool isSynced`
- Não inventar status fora de `SyncStatusContract` sem mapear em `normalize()`
- Se `SyncStatus.conflict` permanecer, não misturar com delete

---

## 4️⃣ PROIBIDO

- ❌ Alterar `smart_button.dart`, rotas, tema, FAB
- ❌ Hard `DELETE FROM drawings` para dado sincronizável
- ❌ Sync em `build()` / `initState` de widget
- ❌ Refatorar agronomic/agenda/ocorrências neste prompt
- ❌ Criar `OfflineSyncCoordinator` neste prompt
- ❌ `git add .` / `git add -A`

---

## 5️⃣ TESTES OBRIGATÓRIOS

Adicionar/ajustar em `test/modules/drawing/`:

1. Soft-delete de feature `synced` → fica com `deleted_local` (ou string canônica) + `deleted_at` setado  
2. Soft-deleted entra em `getPendingSync`  
3. Payload de push contém `deleted_at` não-nulo quando local deletado  
4. Pull com remoto `deleted_at` setado → local fica soft-deleted, **não** reaparece em `getAll`  
5. Pull com remoto ativo **não** ressuscita local soft-deleted pendente de push  

---

## 6️⃣ VALIDAÇÃO

```bash
flutter analyze lib/modules/drawing/
flutter test test/modules/drawing/
./tool/arch_check.sh   # Exit 0 obrigatório
```

---

## 7️⃣ CRITÉRIO DE ACEITE

- [ ] Soft-delete local usa `deleted_at` + status canônico de delete
- [ ] Delete de feature synced entra na fila de sync
- [ ] Push envia `deleted_at` real ao Supabase
- [ ] Pull não ressuscita geometria soft-deleted
- [ ] `arch_check.sh` Exit 0
- [ ] Testes novos passando
- [ ] Nenhum módulo fora de `drawing/` (+ testes) alterado sem necessidade comprovada

---

## 8️⃣ ENTREGA

Commit por arquivo/módulo, mensagem descritiva, ex.:

`fix(drawing): soft-delete canônico e anti-ressurreição no pull`

PR descreve: bug, evidência da auditoria, checklist A–E, testes.
