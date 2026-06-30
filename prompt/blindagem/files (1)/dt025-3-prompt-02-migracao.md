# PROMPT 02 — MIGRAÇÃO: DT-025-3 + DT-023-5
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Cirurgia de Acoplamento
**Arquivos alvo:**
  - `lib/ui/components/map/map_bottom_sheet.dart`
  - `lib/ui/screens/private_map_screen.dart`
  - `lib/modules/map/presentation/widgets/visit_active_card.dart`
**Tipo:** ALTERAÇÃO ESTRUTURAL — substituição de imports diretos por contratos
**Pré-requisito:** PROMPT 01 executado — Diagnóstico A confirmado
**Risco:** Médio — arquivos críticos de apresentação; `private_map_screen` em 904 linhas

---

## OBJETIVO

Remover os imports diretos de `visitas/` nos 3 arquivos alvo,
substituindo controllers pelo contrato neutro `visitSessionLookupProvider`
e corrigindo o path de `visit_sheet.dart` para `map/presentation/widgets/`.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não alterar lógica de nenhum widget
❌ Não criar contratos novos — todos já existem
❌ Não adicionar linhas inline em `private_map_screen.dart`
❌ Não ultrapassar 900 linhas em nenhum arquivo alterado
❌ Se encontrar uso de `VisitController` que não tem equivalente
   em `IVisitSessionLookup` → PARAR e reportar antes de continuar

---

## PASSO 0 — LEITURA E MAPA DE SUBSTITUIÇÃO

```bash
# Ler estado atual dos imports nos 3 arquivos
grep -n "import.*modules/visitas" \
  lib/ui/components/map/map_bottom_sheet.dart \
  lib/ui/screens/private_map_screen.dart \
  lib/modules/map/presentation/widgets/visit_active_card.dart

# Confirmar path real de visit_sheet.dart
find lib/ -name "visit_sheet.dart" | sort

# Confirmar contratos disponíveis
cat lib/core/contracts/i_visit_session_lookup.dart
grep -n "visitSessionLookupProvider" \
  lib/core/contracts/i_visit_session_lookup_provider.dart \
  2>/dev/null || find lib/core/contracts/ -name "*visit_session*" | xargs grep -l "Provider"
```

Antes de editar, confirmar:
1. `visit_sheet.dart` vive em `lib/modules/map/presentation/widgets/`
   (não em `lib/modules/visitas/`) — se sim, o import é path errado, não fronteira violada
2. `visitSessionLookupProvider` existe e é acessível
3. `IVisitSessionLookup` expõe o suficiente para substituir
   `visitControllerProvider` nos usos identificados

---

## PASSO 1 — MIGRAR `map_bottom_sheet.dart`

### Imports a remover:
```dart
// REMOVER:
import 'package:soloforte_app/modules/visitas/presentation/widgets/visit_sheet.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
```

### Imports a adicionar:
```dart
// ADICIONAR (visit_sheet já está em map/):
import 'package:soloforte_app/modules/map/presentation/widgets/visit_sheet.dart';

// ADICIONAR (contrato neutro para visit_controller):
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
```

### Atualizar uso do provider (linha ~341):

```bash
# Identificar usos concretos de visitControllerProvider
grep -n "visitControllerProvider\|visitController\b\|endSession\|notifier" \
  lib/ui/components/map/map_bottom_sheet.dart
```

Para `ref.watch(visitControllerProvider)`:
```dart
// ANTES
final visitState = ref.watch(visitControllerProvider);

// DEPOIS
final visitSession = ref.watch(visitSessionLookupProvider);
```

Para `ref.read(visitControllerProvider.notifier).endSession()`:

⚠️ `IVisitSessionLookup` é lookup (leitura) — não tem `endSession()`.
Verificar se `endSession` tem equivalente nos contratos:

```bash
grep -rn "endSession\|finalizarVisita\|checkOut" \
  lib/core/contracts/ --include="*.dart"
```

Se não existir → PARAR. `endSession()` é escrita — precisa de
`IVisitWriter` ou similar. Reportar antes de continuar.

Se existir → usar o contrato correspondente.

---

## PASSO 2 — MIGRAR `private_map_screen.dart`

⚠️ Arquivo em 904 linhas. Cada remoção de import reduz 1 linha.
Meta: terminar abaixo de 900.

### Imports a remover:
```dart
// REMOVER:
import 'package:soloforte_app/modules/visitas/presentation/controllers/geofence_controller.dart';
import 'package:soloforte_app/modules/visitas/presentation/widgets/visit_sheet.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
```

### Imports a adicionar:
```dart
// visit_sheet — corrigir path (já está em map/):
import 'package:soloforte_app/modules/map/presentation/widgets/visit_sheet.dart';

// geofence_controller — substituir pelo provider neutro:
import 'package:soloforte_app/core/contracts/i_field_lookup_geofence_provider.dart';

// visit_controller — substituir pelo lookup:
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
```

### Atualizar usos:

```bash
# Identificar todos os usos dos controllers no arquivo
grep -n "geofenceControllerProvider\|visitControllerProvider\|geofenceController\b\|visitController\b" \
  lib/ui/screens/private_map_screen.dart
```

Para `ref.watch(geofenceControllerProvider)` (linha ~442):
```dart
// ANTES
final geofenceState = ref.watch(geofenceControllerProvider);

// DEPOIS
final fieldLookup = ref.watch(iFieldLookupGeofenceProvider);
```

Para `ref.watch(visitControllerProvider.select(...))` (linha ~756):
```dart
// ANTES
final isActive = ref.watch(visitControllerProvider.select((s) => s.isActive));

// DEPOIS — verificar se IVisitSessionLookup expõe isActive
final session = ref.watch(visitSessionLookupProvider);
final isActive = session?.isActive ?? false;
```

### Verificar contagem após edições:
```bash
wc -l lib/ui/screens/private_map_screen.dart
```

Meta: ≤ 900. Se ficou abaixo → remover comentário de governance
do PROMPT 04 do ADR-025 (já não é necessário):

```bash
grep -n "GOVERNANCE ADR-025" lib/ui/screens/private_map_screen.dart
# Se < 900 linhas → remover o bloco de comentário (3 linhas)
# Se ainda ≥ 900 → manter o comentário
```

---

## PASSO 3 — MIGRAR `visit_active_card.dart`

```bash
grep -n "import.*modules/visitas" \
  lib/modules/map/presentation/widgets/visit_active_card.dart
```

### Import a remover:
```dart
// REMOVER:
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
```

### Import a adicionar:
```dart
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
```

### Atualizar uso (linha ~21):
```dart
// ANTES
final state = ref.watch(visitControllerProvider);

// DEPOIS
final session = ref.watch(visitSessionLookupProvider);
```

---

## PASSO 4 — VERIFICAR IMPORTS PROIBIDOS ELIMINADOS

```bash
echo "=== Imports diretos de visitas/ restantes ==="
grep -rn "import.*modules/visitas" \
  lib/ui/ lib/modules/map/presentation/widgets/ \
  --include="*.dart" | sort
```

Resultado esperado: **vazio**.
Se qualquer linha retornar → não prosseguir.

---

## PASSO 5 — VERIFICAR CONTAGENS DE LINHA

```bash
wc -l lib/ui/components/map/map_bottom_sheet.dart
wc -l lib/ui/screens/private_map_screen.dart
wc -l lib/modules/map/presentation/widgets/visit_active_card.dart
```

- `private_map_screen.dart` deve ficar ≤ 900

---

## PASSO 6 — FLUTTER ANALYZE

```bash
flutter analyze lib/ui/ 2>&1 | grep -E "^.*error"
flutter analyze lib/modules/map/ 2>&1 | grep -E "^.*error"
flutter analyze lib/modules/visitas/ 2>&1 | grep -E "^.*error"
```

Zero erros novos.

---

## PASSO 7 — ARCH_CHECK

```bash
bash tool/arch_check.sh 2>&1
echo "EXIT CODE: $?"
```

Verificar especificamente:
- REGRA-VISITAS-1: não dispara (lib/ui/ não importa visitas/)
- REGRA-MAP-1: não dispara (lib/ui/ nas exceções autorizadas)
- Exit 0

---

## PASSO 8 — ATUALIZAR ADR-023 E ADR-025

```
ADR-023: DT-023-5 → ✅ RESOLVIDA — DT-025-3 PROMPT 02
ADR-025: DT-025-3 → ✅ RESOLVIDA — DT-025-3 PROMPT 02
```

---

## VALIDAÇÃO FINAL

- [ ] `map_bottom_sheet.dart` sem import de `visitas/`?
- [ ] `private_map_screen.dart` sem import de `visitas/`?
- [ ] `visit_active_card.dart` sem import de `visitas/`?
- [ ] `visit_sheet.dart` usando path `map/presentation/widgets/`?
- [ ] `private_map_screen.dart` ≤ 900 linhas?
- [ ] Lógica de todos os widgets inalterada?
- [ ] `flutter analyze` sem erros novos?
- [ ] `arch_check.sh` Exit 0?
- [ ] ADR-023 DT-023-5 marcada resolvida?
- [ ] ADR-025 DT-025-3 marcada resolvida?

---

## MENSAGEM DE COMMIT

```
feat(map,visitas): resolve DT-023-5 e DT-025-3 — lib/ui/ sem imports diretos de visitas/

- map_bottom_sheet.dart: visit_controller → visitSessionLookupProvider
- map_bottom_sheet.dart: visit_sheet path corrigido (map/presentation/widgets/)
- private_map_screen.dart: geofence/visit controllers → contratos neutros
- private_map_screen.dart: visit_sheet path corrigido
- visit_active_card.dart: visit_controller → visitSessionLookupProvider
- private_map_screen.dart: <N> linhas (comentário governance removido se < 900)
- arch_check.sh: Exit 0 | REGRA-VISITAS-1 e REGRA-MAP-1 sem disparar
- flutter analyze: 0 erros novos
- ADR-023 DT-023-5: ✅ resolvida
- ADR-025 DT-025-3: ✅ resolvida
```

---

## ENCERRAMENTO

`lib/ui/` sem imports diretos de `visitas/`.
Dívidas DT-023-5 e DT-025-3 fechadas no mesmo commit.
Próximo: PROMPT 03 — auditoria final de conformidade.
