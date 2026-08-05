# PROMPT FIX — PULL LOCAL WINS (AGRONOMIC + AGENDA)

**Fonte:** `prompt/AUDITORIA_OFFLINE_FIRST_RELATORIO.md` — Dimensão 5 (CRÍTICO/ALTO)  
**Agente:** Engenheiro Sênior Flutter/Dart — Offline-First / Sync  
**Prioridade:** 🔴 CRÍTICO (agronomic) · 🟠 ALTO (agenda)  
**Tipo:** correção de código · escopo fechado · zero improviso  
**Declaração:** `@MÓDULO: PERSISTENCIA_OFFLINE`

---

## 0️⃣ PASSO 0 — OBRIGATÓRIO

```bash
find lib/ -name "agronomic_sync_service.dart"
find lib/ -name "agenda_sync_service.dart"
find lib/ -name "sync_status_contract.dart"
find lib/ -name "agenda_repository.dart"
rg -n "shouldApplyRemote|pending_sync|statusDirty|updated_at|sync_status" \
  lib/modules/consultoria/services/agronomic_sync_service.dart \
  lib/modules/agenda/data/services/agenda_sync_service.dart
```

Ler `docs/02_ARQUITETURA_ATIVA/arquitetura-persistencia.md` §5.2:

> "Local vence temporariamente até confirmação explícita."  
> "NUNCA sobrescrever trabalho de campo do usuário silenciosamente."

---

## 1️⃣ DECLARAÇÃO

```
Módulo:       consultoria (agronomic sync) + agenda (agenda sync)
Bounded ctx:  consultoria · agenda · core (contrato de status)
Objetivo:     Pull remoto NUNCA sobrescreve local pending/dirty sem confirmação
Arquivos:     agronomic_sync_service.dart, agenda_sync_service.dart,
              testes associados (criar se ausentes)
Contrato:     alinha comportamento ao doc de persistência; sem ADR novo se
              apenas corrigir violação já documentada
Fronteira:    NÃO (sem novos contratos cross-module)
```

---

## 2️⃣ BUG CONFIRMADO

### Agronomic — CRÍTICO

`AgronomicSyncService.shouldApplyRemote` (~391–400):

```dart
return !(localIsDirty && remoteUpdatedAt.isBefore(localUpdatedAt));
```

Efeito: se local está dirty **e** remoto é **mais novo** → aplica remoto → **perda silenciosa** de edição de campo.

### Agenda — ALTO

`AgendaSyncService` pull (~168–172):

```dart
if (remoteUpdatedAt.isAfter(localEvent.updatedAt)) {
  await _repository.updateEvent(_mapToEvent(remote));
}
```

Efeito: **sem** checagem de `pending_sync` / `local_only` — pending local pode ser sobrescrito.

Referência positiva (não alterar neste prompt, só espelhar política):

- `OccurrenceSyncService` — pending statuses skip replace  
- `VisitSyncService` — `sync_status == 1` → continue  
- `DrawingSyncService` — pending → `conflict` (não overwrite)

---

## 3️⃣ CORREÇÃO OBRIGATÓRIA

### A) Agronomic — `shouldApplyRemote`

Política canônica:

1. Se local **não** é dirty → aplicar remoto se remote newer (ou igual/ausente conforme hoje, mas documentar)
2. Se local **é dirty** (`sync_status == statusDirty` / `1`) → **NUNCA** aplicar remoto silenciosamente  
   - Retornar `false` (preservar local)  
   - Opcional: log warning com id da entidade (sem UI neste prompt)
3. Remover a lógica que permite remote-newer vencer dirty local

Atualizar testes unitários de `shouldApplyRemote` (já `@visibleForTesting`):

| local dirty | remote vs local time | resultado esperado |
|---|---|---|
| false | remote newer | apply remote = true |
| true | remote older | apply remote = false |
| true | remote newer | apply remote = **false** (NOVO — contrato) |
| true | timestamps null | preferir preservar local se dirty |

### B) Agenda — pull events (e sessions se mesmo padrão)

Antes de `updateEvent` / `updateSession` a partir do remoto:

1. Ler `sync_status` local (via entidade ou query)
2. Se `SyncStatusContract.isPending(localStatus)` **ou** status in (`pending_sync`, `pending`, `local_only`) → **skip** overwrite  
3. Opcional (não obrigatório neste prompt): marcar conflito explícito — preferir skip + log se não houver UI de conflito wired
4. Soft-deletes locais (`deleted` / `deleted_local`) **não** devem ser ressuscitados por pull de remoto ativo (alinhar ao espírito do fix drawing; mínimo = skip se pending/deleted)

### C) Escopo explícito NÃO incluir neste prompt

- Wire de `ConflictResolutionDialog` (prompt futuro)
- Soft-delete completo da agenda (listagem + push `deleted_local`) — prompt futuro
- Unificação INTEGER vs string sync_status — prompt futuro
- Drawing (já coberto no prompt de soft-delete)

---

## 4️⃣ PROIBIDO

- ❌ Sobrescrever pending/dirty “porque remoto é mais novo”
- ❌ Alterar UI / rotas / tema / `smart_button.dart`
- ❌ Hard delete
- ❌ Sync em widget lifecycle
- ❌ `git add .` / `git add -A`
- ❌ Refatoração oportunista de outros módulos

---

## 5️⃣ TESTES OBRIGATÓRIOS

1. `shouldApplyRemote`: dirty + remote newer → **false**  
2. `shouldApplyRemote`: clean + remote newer → **true**  
3. Agenda pull: evento `pending_sync` local **não** é substituído por remoto newer (teste de serviço com fake repo/supabase se padrão do módulo permitir; senão teste da função de decisão extraída)

---

## 6️⃣ VALIDAÇÃO

```bash
flutter analyze lib/modules/consultoria/services/agronomic_sync_service.dart \
  lib/modules/agenda/data/services/agenda_sync_service.dart
flutter test  # filtrar testes do módulo afetado
./tool/arch_check.sh   # Exit 0
```

---

## 7️⃣ CRITÉRIO DE ACEITE

- [ ] Dirty/pending local nunca é sobrescrito silenciosamente no pull agronomic
- [ ] Pending local nunca é sobrescrito silenciosamente no pull agenda
- [ ] Testes cobrem a matriz dirty×timestamp
- [ ] `arch_check.sh` Exit 0
- [ ] Diff limitado aos arquivos declarados (+ testes)

---

## 8️⃣ ENTREGA

Commits sugeridos:

`fix(consultoria): preservar local dirty no pull agronomic`  
`fix(agenda): skip pull overwrite quando evento pending`

PR referencia `AUDITORIA_OFFLINE_FIRST_RELATORIO.md` Dimensão 5.
