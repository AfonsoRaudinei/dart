# ADR-024 PROMPT 06 — MIGRAÇÃO: `visit_controller.dart` + `geofence_controller.dart`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Cirurgia de Acoplamento
**Arquivos alvo:**
  - `lib/modules/visitas/presentation/controllers/visit_controller.dart`
  - `lib/modules/visitas/presentation/controllers/geofence_controller.dart`
**Arquivos novos:**
  - `test/modules/visitas/visit_controller_test.dart`
**Tipo:** ALTERAÇÃO ESTRUTURAL — remoção de 6 imports proibidos via contratos criados
**Pré-requisito:** PROMMPTs 02–05 do ADR-024 concluídos
**Risco:** ALTO — controllers críticos de campo; lógica não pode ser alterada

---

## OBJETIVO

Substituir os 6 imports proibidos de `consultoria/` e `agenda/` nos dois
controllers por contratos neutros criados nos prompts anteriores.
Criar `visit_controller_test.dart` com 3 fakes para garantir que a
migração não quebra comportamento.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não alterar lógica de negócio — apenas trocar a origem dos tipos
❌ Não alterar `VisitSession` nem repositório de visitas
❌ Não criar novos contratos — todos já foram criados nos PROMMPTs 02–05
❌ Não ultrapassar 900 linhas nos arquivos alterados
❌ Não usar `dynamic` para contornar tipagem
❌ Se encontrar import proibido sem contrato correspondente → PARAR e reportar

---

## PASSO 0 — LEITURA COMPLETA ANTES DE QUALQUER EDIÇÃO

```bash
# Ler os dois controllers integralmente
cat lib/modules/visitas/presentation/controllers/visit_controller.dart
cat lib/modules/visitas/presentation/controllers/geofence_controller.dart

# Confirmar todos os contratos disponíveis
find lib/core/contracts/ -name "*.dart" | sort

# Confirmar os 4 contratos do ADR-024
cat lib/core/contracts/i_occurrence_lookup.dart       2>/dev/null || echo "AUSENTE"
cat lib/core/contracts/i_report_writer.dart           2>/dev/null || echo "AUSENTE"
cat lib/core/contracts/i_agenda_session_bridge.dart   2>/dev/null || echo "AUSENTE"
cat lib/core/contracts/i_field_lookup_geofence_provider.dart 2>/dev/null || echo "AUSENTE"
```

Antes de editar qualquer arquivo, montar a tabela de substituição:

```
Import proibido atual               → Substituto em core/contracts/
─────────────────────────────────────────────────────────────────
occurrence_repository.dart          → i_occurrence_lookup.dart (IOccurrenceLookup)
sqlite_report_repository.dart       → i_report_writer.dart (IReportWriter)
report_model.dart                   → DTO neutro do i_report_writer.dart
agenda_provider.dart                → i_agenda_session_bridge.dart (IAgendaSessionBridge)
i_agenda_repository.dart            → i_agenda_session_bridge.dart (métodos existentes)
event_status.dart                   → i_agenda_session_bridge.dart (sem expor EventStatus)
field_providers.dart                → i_field_lookup_geofence_provider.dart
talhao_map_adapter.dart             → função pura local em geofence_controller.dart
agronomic_models.dart (Talhao)      → FieldSummary (i_field_lookup.dart)
```

Se qualquer import não tiver substituto identificado → PARAR antes de continuar.

---

## PASSO 1 — MIGRAR `visit_controller.dart`

### 1a — Identificar cada uso dos imports proibidos

```bash
grep -n "OccurrenceRepository\|SQLiteReportRepository\|Report\b\|ReportType\b\|IAgendaRepository\|agendaRepositoryProvider\|EventStatus\|agendaProvider" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```

Para cada ocorrência, anotar: linha, tipo, contexto de uso.

### 1b — Substituir imports

Remover os 6 imports proibidos e adicionar apenas:
```dart
import 'package:soloforte_app/core/contracts/i_occurrence_lookup.dart';
import 'package:soloforte_app/core/contracts/i_report_writer.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
// Providers correspondentes (i_*_provider.dart)
```

### 1c — Atualizar injeção de dependência

O construtor ou `ref.watch` de `visit_controller.dart` deve receber
os tipos de contrato, não as implementações concretas.

Se o controller usa `ref.watch(agendaRepositoryProvider)`:
```dart
// ANTES
final agendaRepo = ref.watch(agendaRepositoryProvider);

// DEPOIS
final agendaBridge = ref.watch(iAgendaSessionBridgeProvider);
```

Se o controller instancia repositórios diretamente:
```dart
// ANTES
final _occurrenceRepo = OccurrenceRepository();

// DEPOIS — injetar via construtor ou provider
final IOccurrenceLookup _occurrenceLookup;
```

### 1d — Adaptar chamadas de método

Para cada método chamado nos repositórios concretos, usar o método
equivalente no contrato neutro. Verificar assinaturas:

```bash
cat lib/core/contracts/i_occurrence_lookup.dart
cat lib/core/contracts/i_report_writer.dart
cat lib/core/contracts/i_agenda_session_bridge.dart
```

Se o método concreto usado não existe no contrato → PARAR e reportar.
Não adaptar silenciosamente.

---

## PASSO 2 — MIGRAR `geofence_controller.dart`

### 2a — Identificar cada uso dos imports proibidos

```bash
grep -n "fieldProvider\|mapFieldsProvider\|TalhaoMapAdapter\|Talhao\b\|AgronomicModel\|geometry" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

### 2b — Substituir imports

```dart
// Remover:
// import '...consultoria/clients/presentation/providers/field_providers.dart'
// import '...consultoria/services/talhao_map_adapter.dart'
// import '...consultoria/clients/domain/agronomic_models.dart'

// Adicionar:
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_geofence_provider.dart';
```

### 2c — Substituir `Talhao` por `FieldSummary`

Toda referência a `Talhao` com `geometry` deve usar `FieldSummary.geometry`.
O campo `geometry` é `String?` (GeoJSON serializado).

### 2d — Inlinar `TalhaoMapAdapter` se for transformação pura

Se `TalhaoMapAdapter.toPolygon()` e `isPointInside()` são apenas
matemática de coordenadas sem dependência de `consultoria/`:

```dart
// Criar função privada local em geofence_controller.dart:
List<LatLng> _geoJsonToPolygon(String geoJson) {
  // transformação pura — sem imports de consultoria/
}

bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
  // algoritmo ray-casting — sem imports externos
}
```

Se `TalhaoMapAdapter` tem lógica não trivial que não pode ser replicada
com segurança → PARAR e reportar antes de inlinar.

### 2e — Atualizar provider de campos

```dart
// ANTES
final fields = ref.watch(mapFieldsProvider);

// DEPOIS
final fieldLookup = ref.watch(iFieldLookupGeofenceProvider);
// usar fieldLookup.listAll() de forma assíncrona
```

---

## PASSO 3 — VERIFICAR CONTAGEM DE LINHAS

```bash
wc -l lib/modules/visitas/presentation/controllers/visit_controller.dart
wc -l lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Se qualquer arquivo ultrapassar 900 linhas → PARAR e reportar.
Não commitar arquivos acima do limite.

---

## PASSO 4 — VERIFICAR IMPORTS PROIBIDOS ELIMINADOS

```bash
echo "=== visit_controller — imports restantes de consultoria/ ==="
grep -n "import.*modules/consultoria" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart

echo "=== visit_controller — imports restantes de agenda/presentation ==="
grep -n "import.*modules/agenda.*presentation" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart

echo "=== geofence_controller — imports restantes de consultoria/ ==="
grep -n "import.*modules/consultoria" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Todos devem retornar **vazio**.
Se qualquer resultado → não prosseguir para PASSO 5.

---

## PASSO 5 — CRIAR `visit_controller_test.dart`

Criar `test/modules/visitas/visit_controller_test.dart` com 3 fakes
para os contratos injetados:

```dart
// test/modules/visitas/visit_controller_test.dart
//
// Testes de migração ADR-024 — visit_controller.dart
// Valida que o controller funciona com contratos neutros
// sem dependência de consultoria/ ou agenda/.

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_lookup.dart';
import 'package:soloforte_app/core/contracts/i_report_writer.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
// imports do controller

// ── Fake 1 ──────────────────────────────────────────────────────────
class FakeOccurrenceLookup implements IOccurrenceLookup {
  final List<OccurrenceSummary> _data;
  FakeOccurrenceLookup([this._data = const []]);

  @override
  Future<List<OccurrenceSummary>> getBySessionId(String sessionId) async {
    return _data.where((o) => o.sessionId == sessionId).toList();
  }
  // implementar demais métodos com retorno vazio/null
}

// ── Fake 2 ──────────────────────────────────────────────────────────
class FakeReportWriter implements IReportWriter {
  final List<ReportDraft> saved = [];

  @override
  Future<void> saveReport(ReportDraft draft) async {
    saved.add(draft);
  }
  // implementar demais métodos
}

// ── Fake 3 ──────────────────────────────────────────────────────────
class FakeAgendaSessionBridge implements IAgendaSessionBridge {
  bool _isActive = false;

  void setActive(bool value) => _isActive = value;

  @override
  Future<bool> hasActiveSession(String producerId) async => _isActive;

  @override
  Future<void> finalizeSession(String sessionId) async {}
  // implementar demais métodos
}

// ── Cenários de teste ───────────────────────────────────────────────
void main() {
  group('VisitController — contratos ADR-024', () {

    test('cenário feliz — iniciar visita sem sessão ativa', () async {
      // PREENCHER com o cenário real do controller
    });

    test('cenário erro — tentar iniciar com sessão ativa', () async {
      // PREENCHER com validação de guarda do controller
    });

    test('edge case — encerrar visita salva relatório via IReportWriter', () async {
      // PREENCHER com verificação de FakeReportWriter.saved
    });

  });
}
```

Os corpos de teste marcados com `// PREENCHER` devem ser completados
com base na lógica real lida no PASSO 0.
Não criar testes com `expect(true, true)` — cada teste deve verificar
comportamento real.

---

## PASSO 6 — EXECUTAR TESTES

```bash
# Testes novos
flutter test test/modules/visitas/visit_controller_test.dart \
  --reporter compact 2>&1

# Regressão consultoria/
flutter test test/modules/consultoria/ --reporter compact 2>&1 | tail -5

# Regressão drawing/
flutter test test/drawing/ --reporter compact 2>&1 | tail -5

# Regressão ndvi/
flutter test test/modules/ --reporter compact 2>&1 | tail -10
```

---

## PASSO 7 — FLUTTER ANALYZE

```bash
flutter analyze lib/modules/visitas/ 2>&1 | grep -E "error|Error"
flutter analyze lib/modules/consultoria/ 2>&1 | grep -E "error|Error"
flutter analyze lib/modules/agenda/ 2>&1 | grep -E "error|Error"
flutter analyze lib/modules/map/ 2>&1 | grep -E "error|Error"
```

Zero erros novos em todos.

---

## PASSO 8 — ARCH_CHECK FINAL

```bash
bash tool/arch_check.sh 2>&1
echo "EXIT CODE: $?"
```

Desta vez, as regras `REGRA-VISITAS-1/2/3` não devem disparar exceção
para `visit_controller.dart` nem `geofence_controller.dart` — os imports
foram removidos. Verificar que as linhas de exceção do arch_check
podem ser removidas:

```bash
grep -n "visit_controller\|geofence_controller" tool/arch_check.sh
```

Se as exceções ainda estão presentes → removê-las agora,
pois a dívida DT-023-3 e DT-023-4 foi resolvida.

Rodar arch_check novamente após remover as exceções:
```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado: **Exit 0 sem exceções**.

---

## PASSO 9 — ATUALIZAR ADR-023

Marcar as dívidas como resolvidas:
```
DT-023-3: visit_controller.dart sem imports de consultoria → ✅ RESOLVIDO — ADR-024 PROMPT 06
DT-023-4: geofence_controller.dart sem imports de consultoria → ✅ RESOLVIDO — ADR-024 PROMPT 06
```

---

## VALIDAÇÃO FINAL

- [ ] `visit_controller.dart` sem imports de `consultoria/`?
- [ ] `visit_controller.dart` sem imports diretos de `agenda/presentation/`?
- [ ] `geofence_controller.dart` sem imports de `consultoria/`?
- [ ] Lógica de negócio inalterada (apenas origem dos tipos mudou)?
- [ ] Ambos os arquivos abaixo de 900 linhas?
- [ ] `visit_controller_test.dart` criado com 3 fakes e 3 cenários reais?
- [ ] Todos os testes passando (consultoria 67/67, ndvi 12/12)?
- [ ] `flutter analyze` sem erros novos em todos os módulos?
- [ ] Exceções de `visit_controller/geofence_controller` removidas do `arch_check.sh`?
- [ ] `arch_check.sh` Exit 0 sem exceções?
- [ ] ADR-023 DT-023-3 e DT-023-4 marcadas como resolvidas?

---

## MENSAGEM DE COMMIT

```
feat(visitas): resolve DT-023-3 e DT-023-4 — ADR-024

- visit_controller.dart: remove 3 imports diretos de consultoria/
  substituídos por IOccurrenceLookup, IReportWriter, IAgendaSessionBridge
- geofence_controller.dart: remove 3 imports diretos de consultoria/
  substituídos por IFieldLookup via iFieldLookupGeofenceProvider
- TalhaoMapAdapter inlinado como funções puras em geofence_controller
- Cria visit_controller_test.dart (3 fakes + 3 cenários)
- Remove exceções DT-023-3/4 do arch_check.sh
- ADR-023: DT-023-3 e DT-023-4 marcadas como resolvidas
- arch_check.sh: Exit 0 sem exceções
- flutter analyze: 0 erros novos
- Testes: sem regressão
```

---

## ENCERRAMENTO

DT-023-3 e DT-023-4 resolvidas.
`visitas/` não importa `consultoria/` em nenhum arquivo.
`arch_check.sh` cobre toda a camada sem exceções autorizadas.
Próximo: ADR-024 PROMPT 07 — auditoria final de conformidade do ciclo completo.
