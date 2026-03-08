# AUDITORIA — DrawingState Machine (SoloForte)

**Data:** 03/03/2026  
**Branch:** `release/v1.1`  
**Status:** DIAGNÓSTICO COMPLETO — SEM ALTERAÇÃO DE CÓDIGO  
**Autor:** Engenheiro Flutter Sênior — Auditoria Automática  
**Arquivo-alvo:** `lib/modules/drawing/domain/drawing_state.dart`

---

## 1. Diagnóstico do Problema

### 1.1 Localização do Erro

O problema não é um crash ativo único — é um **conjunto de inconsistências estruturais** que juntas criam janelas de tempo onde o estado da `DrawingStateMachine` e o estado da `DrawingInteraction` ficam **dessincronizados**, produzindo comportamentos incorretos na UI sem lançar exceção.

**Arquivo primário:**  
`lib/modules/drawing/domain/drawing_state.dart`

**Arquivo secundário (com maior densidade de risco):**  
`lib/modules/drawing/presentation/controllers/drawing_controller.dart` (1534 linhas — exceção legada)

**Sintoma identificado via comentários no próprio código:**
- Tags `🔧 FIX-DRAW-REDSCREEN` em 3 pontos distintos do controller.
- Transition `armed → drawing` foi o ponto exato de um crash anterior (`BeginAddingPoints`).
- Workarounds aplicados inline sem máquina de estados refatorada.

---

### 1.2 Arquivo que Causa o Problema

O `DrawingController` gerencia **dois vetores de estado em paralelo**:

| Vetor | Tipo | Localização |
|---|---|---|
| `DrawingStateMachine` | Máquina de estados formal (8 estados) | `drawing_state.dart` |
| `DrawingInteraction _interactionMode` | Enum de interação (7 valores) | `drawing_models.dart` |

Esses dois vetores são **redundantes e potencialmente contraditórios**:

```dart
// Exemplo de overlap detectado no controller (linhas 303–319):
final isEditing =
    _interactionMode == DrawingInteraction.editing ||          // vetor 1
    _stateMachine.currentState == DrawingState.editing;        // vetor 2

final isPreviewing =
    _interactionMode == DrawingInteraction.importPreview ||    // vetor 1
    _stateMachine.currentState == DrawingState.importPreview || // vetor 2
    _stateMachine.currentState == DrawingState.booleanOperation;
```

**Conclusão:** a propriedade `liveGeometry`, de alta criticidade (usada diretamente no mapa), é computada usando `OR` entre os dois vetores. Se apenas um deles for atualizado (race condition ou erro de sequência), a UI pode exibir geometria incorreta ou nenhuma.

---

### 1.3 Fluxo de Estado Quebrado

O fluxo `editing` tem o problema mais claro:

1. `startEditMode()` chama `_stateMachine.startEditing()` **E** seta `_interactionMode = DrawingInteraction.editing` (correto, em sincronia).
2. `cancelEdit()` chama `_stateMachine.cancel()` — que leva o SM para `idle` — **E** seta `_interactionMode = DrawingInteraction.normal` (correto).
3. **MAS:** `saveEdit()` chama internamente `cancelEdit()`, que reseta o SM para `idle`.  
   Isso significa que após salvar uma edição, o estado vai para `idle` em vez de permanecer em algum estado que preserve a seleção da feature — **perda de contexto silenciosa**.

---

## 2. Fluxo Atual da Máquina de Estados

### 2.1 Estados Definidos

```
idle → armed → drawing → reviewing → editing → reviewing → idle
  ↑                                                         |
  └─────────────────────────────────────────────────────────┘
       (cancel retorna a idle de qualquer estado)
```

**Estados completos:**

| Estado | Descrição |
|---|---|
| `idle` | Navegação normal do mapa (estado inicial) |
| `armed` | Ferramenta selecionada, aguardando primeiro ponto |
| `drawing` | Desenhando geometria (adicionando pontos) |
| `reviewing` | Geometria completa, aguardando confirmação do usuário |
| `editing` | Editando vértices de geometria existente |
| `importPreview` | Visualizando geometria importada antes de confirmar |
| `booleanOperation` | Operações booleanas (union, difference, intersection) |
| `gpsTracking` | Rastreamento GPS em tempo real |

> **Nota:** `measuring` foi removido como estado órfão — decisão correta, documentada inline.

---

### 2.2 Matriz de Transições Declarada

```
idle             → armed, importPreview, editing, gpsTracking
armed            → drawing, idle
drawing          → reviewing, idle
reviewing        → editing, idle, booleanOperation
editing          → reviewing, idle
importPreview    → idle, reviewing
booleanOperation → reviewing, idle
gpsTracking      → reviewing, idle
```

**Regra global:** qualquer estado → `idle` é sempre válido (reset incondicional).

---

### 2.3 Transições Válidas

| De | Para | Status |
|---|---|---|
| `idle` | `armed` | ✅ Válida |
| `armed` | `drawing` | ✅ Válida |
| `drawing` | `reviewing` | ✅ Válida |
| `reviewing` | `editing` | ✅ Válida |
| `editing` | `reviewing` | ✅ Válida |
| `reviewing` | `booleanOperation` | ✅ Válida |
| `booleanOperation` | `reviewing` | ✅ Válida |
| `idle` | `gpsTracking` | ✅ Válida |
| `gpsTracking` | `reviewing` | ✅ Válida |
| `*` | `idle` | ✅ Sempre válida |

---

### 2.4 Transições Inválidas / Ausentes (Problemas Detectados)

| Transição | Status | Impacto |
|---|---|---|
| `idle` → `editing` | ⚠️ Declarada mas semanticamente estranha | Bypass de armed/drawing ao editar feature existente — intencional, mas sem documentação |
| `editing` → `idle` (via `cancelEdit`) | ⚠️ SM vai para idle, mas contexto de seleção se perde | Silencioso — usuário pode precisar re-selecionar feature |
| `drawing` → `armed` (via `undoDrawingPoint` quando lista vazia) | ⚠️ Único ponto com `tryTransitionTo` em vez do método semântico | Inconsistência de API — deveria usar `backToArmed()` |
| `armed` → `idle` sem limpeza de `_currentPoints` | ✅ OK | `cancelOperation` limpa, mas transição direta via `cancel()` não garante |
| `reviewing` → `reviewing` (re-entrada após boolean op) | ⚠️ Ausente na matriz | `booleanOperation → reviewing` existe, mas `reviewing → reviewing` não é explícito |

---

## 3. Causa Raiz

### 3.1 Diagnóstico Central

**Causa raiz: Duplo vetor de estado sem single source of truth.**

O `DrawingController` mantém dois estados em paralelo:

```
DrawingStateMachine._currentState   (DrawingState enum — 8 valores)
DrawingController._interactionMode  (DrawingInteraction enum — 7 valores)
```

Esses dois vetores modelam **domínios parcialmente sobrepostos** sem contrato claro de separação:

- `DrawingState.editing` e `DrawingInteraction.editing` representam o mesmo conceito
- `DrawingState.importPreview` e `DrawingInteraction.importPreview` idem
- `DrawingState.booleanOperation` e `DrawingInteraction.{union,difference,intersection}Selection` representam o mesmo ciclo

**Consequência:** propriedades derivadas usam `OR` entre os dois vetores (linhas 303–319 do controller), o que significa que **um estado pode estar "ativo" mesmo se apenas metade da dupla for atualizada**.

---

### 3.2 Causa Secundária: ChangeNotifier com Estado Misto

O `DrawingController` é um `ChangeNotifier` de 1534 linhas com responsabilidades misturadas:

- Orquestração de estado (`DrawingStateMachine`)
- Estado de interação (`_interactionMode`)
- Estado de dados (`_currentPoints`, `_manualSketch`, `_editGeometry`, `_previewGeometry`)
- Estado de clientes (`_clients`, `_farms`)
- Estado de GPS (`_gpsVertices`, stream subscriptions)
- Validação de geometria

Isso não viola ADR-008 (que explicitamente autoriza `ChangeNotifier` para `DrawingController`), mas **aumenta a superfície de risco de inconsistência** entre os sub-estados.

---

### 3.3 Causa Terciária: Transições Silenciosas

O `transitionTo()` da `DrawingStateMachine` foi alterado para **não lançar `StateError`** (fix do DRAW-REDSCREEN). A transição inválida apenas loga em debug e retorna `false`.

Isso é correto para evitar red screens, mas **cria o risco de transições ignoradas silenciosamente**. O controller verifica o retorno booleano em alguns pontos, mas não em todos:

```dart
// ✅ Verificado:
final success = _stateMachine.beginAddingPoints();
if (!success) { return; }

// ⚠️ NÃO verificado (linha 1131):
_stateMachine.tryTransitionTo(DrawingState.armed);  // retorno ignorado
```

---

### 3.4 Causa Quaternária: `private_map_screen.dart` em `lib/ui/`

`PrivateMapScreen` importa diretamente `drawing_state.dart` e `drawing_provider.dart`:

```dart
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
```

Isso está em `lib/ui/screens/` — que é a camada de composição da UI, não um módulo. **Não viola as regras do `arch_check.sh`**, pois as regras só bloqueiam `modules/` cruzando com outros `modules/`, e `core/` importando `modules/`. Porém, é um acoplamento implícito que faz `private_map_screen.dart` comparar `DrawingState` enum values diretamente (linhas 473, 599–600, 605, 813).

---

## 4. Impacto no Sistema

### 4.1 Mapa (alto impacto)

| Comportamento | Risco |
|---|---|
| `liveGeometry` usa OR entre dois vetores | ⚠️ MÉDIO — geometria pode persistir na tela após estado limpo se um dos vetores não for zerado |
| `PrivateMapScreen` lê `currentState` para decidir se adiciona ponto | ⚠️ MÉDIO — se SM fica em `armed` mas `_interactionMode` avançou, o tap no mapa não adiciona ponto |
| `dispose()` da screen usa referência cacheada `_drawingController` | ✅ CORRETO — evita `BadState` ao usar `ref` após dispose |

### 4.2 Desenho de Talhões (alto impacto)

| Comportamento | Risco |
|---|---|
| Transição `armed → drawing` foi ponto de crash histórico | ✅ MITIGADO com `FIX-DRAW-REDSCREEN` |
| `undoDrawingPoint` usa `tryTransitionTo(armed)` sem verificar retorno | ⚠️ BAIXO — falha silenciosa, usuário pode perceber inconsistência visual |
| `selectTool('none')` chama `_stateMachine.cancel()` mas pode deixar `_currentPoints` não limpos em edge case | ⚠️ BAIXO — `cancelOperation()` limpa tudo, `cancel()` via `selectTool` pode perder limpeza |

### 4.3 Edição (médio impacto)

| Comportamento | Risco |
|---|---|
| `saveEdit()` → `cancelEdit()` → SM vai para `idle` | ⚠️ MÉDIO — perda de contexto de seleção após salvar |
| `_interactionMode` setado para `editing` mas SM pode estar em `idle` se `startEditing()` falhar | ⚠️ BAIXO — `startEditing()` retorna bool mas resultado não é verificado em `startEditMode()` |

### 4.4 Salvamento (baixo impacto)

O fluxo de save (`DrawingFeatureCrudService`) está desacoplado da máquina de estados — opera no repositório diretamente. Risco baixo aqui.

### 4.5 Sincronização (sem impacto direto)

O `SyncOrchestrator` não consome `DrawingState`. Sem impacto.

### 4.6 Operações Booleanas (médio impacto)

O estado `booleanOperation` no SM é um único estado, mas `DrawingInteraction` tem 3 sub-estados distintos (`unionSelection`, `differenceSelection`, `intersectionSelection`). A granularidade de UI vem de `_interactionMode`, e o SM apenas confirma "está em operação booleana". A falta de alinhamento pode causar instrução de tooltip errada se `_interactionMode` não for setado atomicamente com a transição do SM.

---

## 5. Plano de Correção (PRD)

> ⚠️ Este PRD é **proposta técnica** — nenhuma alteração deve ser feita sem passar pelo processo arquitetural obrigatório (`docs/00_INDEX_OFICIAL.md`).

---

### FASE 1 — Correção Mínima (Segura, Sem Refatoração Estrutural)

**Objetivo:** eliminar os 3 pontos de risco imediato sem alterar contratos.

**Duração estimada:** 1–2 dias  
**Risco arquitetural:** BAIXO — todas as mudanças são dentro de `drawing_controller.dart`

#### 1.1 Verificar retorno de `startEditing()` em `startEditMode()`

```dart
// Arquivo: drawing_controller.dart, método startEditMode()
// ANTES:
_interactionMode = DrawingInteraction.editing;
_stateMachine.startEditing();

// DEPOIS:
final ok = _stateMachine.startEditing();
if (!ok) return;   // SM rejeitou — não seta interactionMode
_interactionMode = DrawingInteraction.editing;
```

> Garante que os dois vetores só avançam juntos.

#### 1.2 Verificar retorno de `tryTransitionTo(armed)` em `undoDrawingPoint()`

```dart
// Arquivo: drawing_controller.dart, método undoDrawingPoint(), linha ~1131
// ANTES:
_stateMachine.tryTransitionTo(DrawingState.armed);

// DEPOIS:
final didRevert = _stateMachine.tryTransitionTo(DrawingState.armed);
if (!didRevert && kDebugMode) {
  AppLogger.debug('undoDrawingPoint: falha ao regredir para armed', tag: 'DrawingController');
}
```

#### 1.3 Documentar intenção da transição `idle → editing` (edição de feature existente)

Adicionar comentário inline na matriz `_validTransitions` explicando que `idle → editing` é intencional (select feature → edit sem passar por armed/drawing):

```dart
DrawingState.idle: [
  DrawingState.armed,
  DrawingState.importPreview,
  DrawingState.editing,    // ← intencional: editar feature existente sem desenhar
  DrawingState.gpsTracking,
],
```

---

### FASE 2 — Refatoração Segura (Eliminar Duplo Vetor de Estado)

**Objetivo:** unificar `DrawingState` e `DrawingInteraction` em um único contrato de estado.

**Duração estimada:** 3–5 dias  
**Risco arquitetural:** MÉDIO — requer ADR, pois altera contratos públicos do controller  
**Pré-requisito:** aprovação de ADR-016 (proposto)

#### 2.1 Criar ADR-016 — Unificação do modelo de estado do Drawing

Proposta: remover `DrawingInteraction` como enum separado e mover a semântica para:
- Novos estados do `DrawingState` (ex: `DrawingState.editingVertex`, `DrawingState.importPreview` já existe)
- Ou flags dentro de um sealed `DrawingStateModel` (Freezed)

#### 2.2 Extrair `DrawingStateNotifier` (Riverpod `@riverpod`)

Conforme ADR-008: código existente permanece, mas na próxima alteração estrutural migrar para:

```dart
@riverpod
class DrawingStateNotifier extends _$DrawingStateNotifier {
  @override
  DrawingStateModel build() => const DrawingStateModel.idle();
  // ...
}
```

Isso eliminaria o `ChangeNotifier` com 1534 linhas e seguiria o padrão canônico para código novo.

#### 2.3 Separar responsabilidades do DrawingController

Conforme planejamento existente (comentários no `LEGACY_EXCEPTIONS` do `arch_check.sh`):

| Novo arquivo | Responsabilidade |
|---|---|
| `drawing_state_notifier.dart` | Estado puro (SM + interactionMode unificados) |
| `drawing_geometry_service.dart` | Cálculos de `liveGeometry` (extrair de controller) |
| `drawing_client_notifier.dart` | Estado de clientes/fazendas (`_clients`, `_farms`) |

---

### FASE 3 — Hardening da Máquina de Estados

**Objetivo:** tornar a SM à prova de uso incorreto.

**Duração estimada:** 2–3 dias  
**Risco arquitetural:** BAIXO — changes dentro do módulo drawing, sem alterar contratos externos

#### 3.1 Testes unitários para cada transição da SM

Cobertura obrigatória:
- Todas as transições válidas passam
- Todas as transições inválidas retornam `false` (não jogam)
- Reset sempre funciona independente do estado atual
- `beginAddingPoints()` de `idle` retorna `false` (não pode bypassar `armed`)

#### 3.2 Adicionar estado `selected` ao SM

O problema de "perda de contexto após `saveEdit()`" (Seção 3.1) pode ser corrigido com:

```dart
enum DrawingState {
  idle,
  armed,
  drawing,
  reviewing,
  editing,
  selected,        // ← novo: feature selecionada mas não editando
  importPreview,
  booleanOperation,
  gpsTracking,
}
```

Com transições:
- `idle → selected` (ao selecionar feature no mapa)
- `selected → editing`
- `editing → selected` (ao salvar/cancelar edit — preserva seleção)
- `selected → idle` (ao fechar seleção)

#### 3.3 Adicionar invariante de consistência (debug-only)

```dart
// No método notifyListeners() do DrawingController (ou em assert):
assert(_stateVectorsAreConsistent(), 
  'DrawingController: SM=$currentState, interaction=$_interactionMode são inconsistentes');
```

Com helper privado:
```dart
bool _stateVectorsAreConsistent() {
  if (_stateMachine.currentState == DrawingState.editing && 
      _interactionMode != DrawingInteraction.editing) return false;
  if (_stateMachine.currentState == DrawingState.importPreview && 
      _interactionMode != DrawingInteraction.importPreview) return false;
  return true;
}
```

---

## 6. Checklist de Validação

### Para qualquer correção aplicada:

- [ ] `./tool/arch_check.sh` retorna `Exit 0`
- [ ] `drawing/` não importa `consultoria/` (REGRA 2 mantida)
- [ ] `consultoria/` não importa `drawing/` (REGRA 2 mantida)
- [ ] `core/` não importa `drawing/` (REGRA 1 mantida)
- [ ] Nenhum arquivo novo ultrapassa 900 linhas (REGRA 3)
- [ ] `DrawingController` permanece como `ChangeNotifier` (conforme ADR-008)
- [ ] Nenhum novo `StateNotifier` ou `ChangeNotifier` é criado fora do padrão canônico
- [ ] Todos os novos providers seguem `@riverpod` codegen (ADR-008)

### Estados e transições:

- [ ] `armed → drawing` funciona sem crash (FIX-DRAW-REDSCREEN preservado)
- [ ] `drawing → reviewing` funciona ao fechar polígono
- [ ] `reviewing → editing` funciona ao selecionar edição
- [ ] `editing → idle` funciona ao cancelar edição
- [ ] `editing → reviewing` funciona ao salvar edição (após FASE 3.2)
- [ ] `idle → gpsTracking` funciona
- [ ] `gpsTracking → reviewing` funciona
- [ ] Reset (`cancelOperation()`) de qualquer estado retorna para `idle` limpo

### Providers Riverpod:

- [ ] `drawingControllerProvider` é `ChangeNotifierProvider` sem `autoDispose` (intencional — lifecycle manual)
- [ ] `drawingFeaturesProvider` é `Provider.autoDispose` com `.select` (sem rebuild total)
- [ ] Nenhum provider de drawing é recriado desnecessariamente na navegação
- [ ] `PrivateMapScreen.dispose()` chama `cancelOperation()` via referência cacheada

### UI:

- [ ] `DrawingStateIndicator` cobre todos os 8 valores do enum (switch exhaustivo)
- [ ] `DrawingSheet` exibe modo correto para cada estado
- [ ] `DrawingEditLayer` reage apenas ao estado `editing`
- [ ] `GpsTrackingOverlay` aparece apenas em estado `gpsTracking`
- [ ] Nenhum widget recebe rebuild total do `DrawingController` — apenas via `.select`

---

## Apêndice — Referências

| Documento | Relevância |
|---|---|
| `lib/modules/drawing/domain/drawing_state.dart` | Definição da SM e enum |
| `lib/modules/drawing/presentation/controllers/drawing_controller.dart` | Orquestração — fonte dos riscos identificados |
| `lib/modules/drawing/domain/models/drawing_models.dart` | `DrawingInteraction` enum |
| `lib/modules/drawing/presentation/providers/drawing_provider.dart` | Configuração Riverpod |
| `docs/02_ARQUITETURA_ATIVA/ADR-008-RIVERPOD-NORMALIZATION.md` | Padrão canônico de estado |
| `docs/03_ENFORCEMENT/enforcement-rules.md` | Regras de isolamento entre módulos |
| `tool/arch_check.sh` | Script de enforcement (passa sem violações — ✅ APROVADO) |
| `lib/ui/screens/private_map_screen.dart` | Consumidor do estado de drawing na UI |
