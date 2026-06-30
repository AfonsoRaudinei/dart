# PROMPT 03 — CONTRATO: Expandir `IVisitSessionLookup` e `VisitSessionSummary`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Alteração Estrutural
**Arquivos alvo:**
  - `lib/core/contracts/i_visit_session_lookup.dart` (EXPANDIR — não criar)
  - `lib/core/contracts/i_visit_session_lookup_provider.dart` (VERIFICAR — possível ajuste)
  - `lib/modules/visitas/infra/visit_session_lookup_adapter.dart` (EXPANDIR — não criar)
**Tipo:** ALTERAÇÃO ESTRUTURAL — expansão de contrato existente
**Pré-requisito:** PROMPT 02 executado — ADR-023 criado com DT-023-1 e DT-023-2 declaradas
**Risco:** Médio — altera DTO existente; verificar impacto nos consumidores atuais

---

## OBJETIVO

Expandir `VisitSessionSummary` de 2 para 7 campos e adicionar `findById()`
em `IVisitSessionLookup`. Atualizar o adapter correspondente.
Verificar que os consumidores existentes não quebram.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não alterar `visit_session.dart`
❌ Não criar novos providers — apenas expandir o contrato
❌ Não alterar `visit_controller.dart` nem `geofence_controller.dart` agora (PROMPT 04)
❌ Não adicionar campos que não existem em `VisitSession` real
❌ Não ultrapassar 150 linhas nos arquivos de contrato

---

## PASSO 0 — VERIFICAÇÃO DE PRÉ-REQUISITOS

```bash
find docs/02_ARQUITETURA_ATIVA/ -name "ADR-023*"
cat lib/core/contracts/i_visit_session_lookup.dart
cat lib/modules/visitas/infra/visit_session_lookup_adapter.dart
cat lib/modules/visitas/domain/models/visit_session.dart
```

Confirmar:
1. ADR-023 existe ✅
2. Ler o estado atual da interface — quais campos tem agora?
3. Ler o adapter atual — o que `_toSummary` já mapeia?
4. Ler `VisitSession` — confirmar campos disponíveis para mapeamento

Se qualquer arquivo não existir → PARAR e reportar.

---

## PASSO 1 — MAPEAR CONSUMIDORES ATUAIS DO DTO

```bash
grep -rn "VisitSessionSummary" lib/ --include="*.dart" | sort
grep -rn "getActiveSession\|IVisitSessionLookup\|visitSessionLookupProvider" \
  lib/ --include="*.dart" | sort
```

Para cada consumidor encontrado:
- Quais campos do DTO ele acessa?
- Vai quebrar se os campos novos forem adicionados (sem remover os existentes)?

⚠️ Adicionar campos é retrocompatível. **Nunca remover nem renomear campos existentes.**

---

## PASSO 2 — EXPANDIR `i_visit_session_lookup.dart`

Substituir o conteúdo atual mantendo `id` e `status` já existentes
e adicionando os campos que os consumidores precisam:

```dart
// lib/core/contracts/i_visit_session_lookup.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-020 (origem) + ADR-023 (expansão — DT-023-1, DT-023-2)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// RETROCOMPATÍVEL: campos id e status mantidos, novos campos adicionados.

/// DTO mínimo de sessão de visita para consumo por módulos externos.
/// NÃO é espelho completo de VisitSession — apenas campos necessários
/// para contexto de mapa, agenda e consultoria.
class VisitSessionSummary {
  const VisitSessionSummary({
    required this.id,
    required this.producerId,
    required this.status,
    required this.startTime,
    this.areaId,
    this.activityType,
    this.endTime,
  });

  final String id;
  final String producerId;
  final String status;           // 'active' | 'finished'
  final DateTime startTime;
  final String? areaId;
  final String? activityType;
  final DateTime? endTime;

  bool get isActive => status == 'active';
}

/// Contrato de consulta de sessões de visita.
/// Implementado em visitas/infra/visit_session_lookup_adapter.dart
/// Consumidores autorizados: map/, consultoria/, agenda/
/// ADR-023
abstract interface class IVisitSessionLookup {
  /// Retorna a sessão ativa do usuário atual, ou null se não houver.
  Future<VisitSessionSummary?> getActiveSession();

  /// Retorna sessão por ID. Retorna null se não encontrada.
  /// Adicionado em ADR-023 — DT-023-2
  Future<VisitSessionSummary?> findById(String sessionId);
}
```

**Regra obrigatória:** confirmar que `producerId` e `startTime` existem
em `VisitSession` real (PASSO 0) antes de incluir no DTO.

---

## PASSO 3 — EXPANDIR `visit_session_lookup_adapter.dart`

```bash
cat lib/modules/visitas/infra/visit_session_lookup_adapter.dart
```

Atualizar o método `_toSummary` para incluir os novos campos
e implementar `findById` se ainda não existir:

```dart
// APENAS atualizar _toSummary e adicionar findById.
// Não alterar construtor, não alterar injeção de repositório.

VisitSessionSummary _toSummary(VisitSession session) {
  return VisitSessionSummary(
    id: session.id,
    producerId: session.producerId,    // campo novo
    status: session.status,
    startTime: session.startTime,      // campo novo
    areaId: session.areaId,            // campo novo
    activityType: session.activityType, // campo novo
    endTime: session.endTime,          // campo novo
  );
}

@override
Future<VisitSessionSummary?> findById(String sessionId) async {
  // PREENCHER com o método real do repositório de visitas
  // usar o mesmo padrão de getActiveSession já implementado
  final session = await _repository.<METODO_BUSCAR_POR_ID>(sessionId);
  if (session == null) return null;
  return _toSummary(session);
}
```

O `<METODO_BUSCAR_POR_ID>` deve ser determinado lendo o repositório real:

```bash
cat lib/modules/visitas/data/repositories/visit_repository.dart
```

Usar o método que retorna `VisitSession?` por ID. Não inventar.

---

## PASSO 4 — VERIFICAR CONSUMIDORES ATUAIS NÃO QUEBRARAM

```bash
flutter analyze lib/modules/consultoria/ 2>&1 | grep -E "error|Error"
flutter analyze lib/modules/map/ 2>&1 | grep -E "error|Error"
```

Resultado esperado: **0 erros novos**.

Os consumidores existentes (`occurrence_controller.dart`, `occurrence_list_sheet.dart`)
usam `getActiveSession()` — que não foi alterado, apenas expandido.
Adicionar `findById` é compatível porque é novo método na interface.

⚠️ Se qualquer erro aparecer → PARAR. Não prosseguir.

---

## PASSO 5 — VERIFICAR IMPORTS PROIBIDOS

```bash
grep "import.*modules" lib/core/contracts/i_visit_session_lookup.dart
```

Resultado esperado: **nenhuma linha**.

---

## PASSO 6 — VERIFICAR ARCH_CHECK

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado: **Exit 0**.

---

## PASSO 7 — ATUALIZAR ADR-023

Marcar as dívidas resolvidas:

```markdown
| DT-023-1 | VisitSessionSummary expandido para 7 campos | ✅ RESOLVIDO — PROMPT 03 |
| DT-023-2 | findById() adicionado a IVisitSessionLookup | ✅ RESOLVIDO — PROMPT 03 |
```

---

## VALIDAÇÃO FINAL

- [ ] `VisitSessionSummary` tem 7 campos (id, producerId, status, startTime, areaId, activityType, endTime)?
- [ ] `IVisitSessionLookup` tem `getActiveSession()` E `findById()`?
- [ ] Adapter atualizado com `_toSummary` completo e `findById` implementado?
- [ ] Nenhum campo inventado (todos confirmados em `VisitSession` real)?
- [ ] Campos anteriores (`id`, `status`) mantidos sem renomear?
- [ ] `flutter analyze consultoria/` e `map/` sem novos erros?
- [ ] `arch_check.sh` Exit 0?
- [ ] ADR-023 atualizado com DT-023-1 e DT-023-2 como resolvidas?

---

## ENCERRAMENTO

O contrato `IVisitSessionLookup` está completo e retrocompatível.
O adapter reflete o DTO expandido.
Consumidores existentes não quebraram.
As violações internas de `visit_controller` e `geofence_controller` são escopo do PROMPT 04.
