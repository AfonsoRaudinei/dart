# PROMPT — Corrigir Regra 1: `sync_orchestrator.dart` e dependências ilegais em `core/`

**Tipo:** Correção arquitetural — inversão de dependência
**Risco:** MÉDIO — altera inicialização do orquestrador de sync
**arch_check.sh antes:** FAIL Regra 1
**arch_check.sh depois:** PASS Regra 1

---

## OBJETIVO

Remover todas as importações ilegais de `modules/` dentro de `core/`,
movendo o registro dos módulos de sync para `lib/app/sync_registration.dart`,
e movendo arquivos mal posicionados de `core/` para `lib/app/`.

---

## ARQUIVOS TOCADOS

```
lib/core/services/sync_orchestrator.dart   → remover imports de modules/
lib/core/services/sync_service.dart        → remover imports de modules/
lib/core/state/unified_map_providers.dart  → mover para lib/app/providers/
lib/core/domain/field_map_adapter.dart     → mover para lib/app/adapters/
lib/app/sync_registration.dart             → receber registro dos módulos
lib/main.dart                              → ajustar ordem de inicialização
```

---

## PASSO 1 — Limpar `sync_orchestrator.dart`

O provider em `core/` deve apenas criar o `SyncOrchestrator` vazio.

**Antes (ilegal):**
```dart
final syncOrchestratorProvider = ChangeNotifierProvider<SyncOrchestrator>((ref) {
  final orchestrator = SyncOrchestrator(ref);
  final supabase = Supabase.instance.client;
  orchestrator.registerModule(AgronomicSyncModule(supabase));  // ILEGAL
  orchestrator.registerModule(DrawingSyncModule());             // ILEGAL
  orchestrator.registerModule(OccurrenceSyncModule(supabase)); // ILEGAL
  orchestrator.registerModule(VisitSyncModule(supabase));       // ILEGAL
  orchestrator.registerModule(AgendaSyncModule(supabase));      // ILEGAL
  return orchestrator;
});
```

**Depois (legal):**
```dart
// SEM imports de modules/
final syncOrchestratorProvider = ChangeNotifierProvider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(ref);
  // Modulos registrados externamente via sync_registration.dart
});
```

Remover todos os imports de `modules/` do topo do arquivo.

---

## PASSO 2 — Limpar `sync_service.dart`

Remover estas linhas:
```dart
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_sync_service.dart';
```

Se `sync_service.dart` depende dessas implementações para funcionar,
criar interface `ISyncModule` abstrata em `core/` e fazer os módulos
implementá-la. O `sync_service.dart` passa a depender só da interface.

---

## PASSO 3 — Mover registro para `lib/app/sync_registration.dart`

`app/` pode importar `modules/` legalmente — é camada de composição.

```dart
// lib/app/sync_registration.dart
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import 'package:soloforte_app/modules/consultoria/services/agronomic_sync_service.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_sync_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_sync_service.dart';
import 'package:soloforte_app/modules/agenda/data/services/agenda_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerSyncModules(SyncOrchestrator orchestrator) {
  final supabase = Supabase.instance.client;
  orchestrator.registerModule(AgronomicSyncModule(supabase));
  orchestrator.registerModule(DrawingSyncModule());
  orchestrator.registerModule(OccurrenceSyncModule(supabase));
  orchestrator.registerModule(VisitSyncModule(supabase));
  orchestrator.registerModule(AgendaSyncModule(supabase));
}
```

---

## PASSO 4 — Ajustar `main.dart`

```dart
import 'package:soloforte_app/app/sync_registration.dart';

// Em _SoloForteAppState.initState():
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    final orchestrator = ref.read(syncOrchestratorProvider);
    registerSyncModules(orchestrator); // registro fora do core/
    ref.read(visitCompletionObserverProvider);
  }
});
```

---

## PASSO 5 — Mover `unified_map_providers.dart`

De: `lib/core/state/unified_map_providers.dart`
Para: `lib/app/providers/unified_map_providers.dart`

Atualizar todos os imports que apontavam para o caminho antigo.
Deletar arquivo original de `core/state/`.

---

## PASSO 6 — Mover `field_map_adapter.dart`

De: `lib/core/domain/field_map_adapter.dart`
Para: `lib/app/adapters/field_map_adapter.dart`

Atualizar todos os imports que apontavam para o caminho antigo.
Deletar arquivo original de `core/domain/`.

---

## FRONTEIRAS

```
core/  -> modules/  PROIBIDO (exceto app_router.dart)
app/   -> modules/  PERMITIDO — camada de composição
app/   -> core/     PERMITIDO
```

---

## VALIDACAO FINAL

- [ ] `core/services/sync_orchestrator.dart` — zero imports de modules/
- [ ] `core/services/sync_service.dart` — zero imports de modules/
- [ ] `unified_map_providers.dart` — fora de core/
- [ ] `field_map_adapter.dart` — fora de core/
- [ ] `lib/app/sync_registration.dart` — contem todo registro de modulos
- [ ] `main.dart` — chama registerSyncModules() no postFrameCallback
- [ ] `bash tool/arch_check.sh` Regra 1: PASS
- [ ] App compila sem erros
- [ ] 67 testes de consultoria/ continuam verdes
