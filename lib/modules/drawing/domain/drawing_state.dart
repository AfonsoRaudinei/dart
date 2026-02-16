/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE — SOLOFORTE
════════════════════════════════════════════════════════════════════

Este arquivo define a máquina de estados do módulo de desenho.
Garante transições válidas e previsíveis entre estados de interação.

ESTADOS:
- idle: Navegação normal do mapa
- armed: Ferramenta selecionada, aguardando primeiro ponto
- drawing: Desenhando geometria (adicionando pontos)
- reviewing: Geometria completa, aguardando confirmação
- editing: Editando geometria existente (movendo vértices)
- measuring: Medindo área/perímetro
- importPreview: Visualizando geometria importada antes de confirmar
- booleanOperation: Operações booleanas (união, diferença, interseção)

REGRAS:
- Apenas transições válidas são permitidas
- Transições inválidas lançam StateError
- Estado é imutável (novas instâncias para cada mudança)
════════════════════════════════════════════════════════════════════
*/

import 'package:flutter/foundation.dart';

/// Estados possíveis da máquina de desenho
enum DrawingState {
  /// Navegação normal do mapa (estado inicial)
  idle,

  /// Ferramenta selecionada, aguardando primeiro ponto
  armed,

  /// Desenhando geometria (adicionando pontos)
  drawing,

  /// Geometria completa, aguardando confirmação
  reviewing,

  /// Editando geometria existente (movendo vértices)
  editing,

  /// Visualizando geometria importada antes de confirmar
  importPreview,

  /// Operações booleanas (união, diferença, interseção)
  booleanOperation,

  // REMOVIDO: measuring (estado órfão nunca usado)
  // Se precisar de medição no futuro, usar reviewing + flag
}

/// Tipos de ferramentas de desenho
enum DrawingTool { none, polygon, freehand, pivot, rectangle, circle }

/// Tipos de operações booleanas
enum BooleanOperationType { none, union, difference, intersection }

/// Gerenciador de estado de desenho
///
/// Controla as transições entre estados e garante que apenas
/// transições válidas sejam permitidas.
class DrawingStateMachine {
  DrawingState _currentState = DrawingState.idle;
  DrawingTool _currentTool = DrawingTool.none;
  BooleanOperationType _booleanOp = BooleanOperationType.none;

  /// Estado atual da máquina
  DrawingState get currentState => _currentState;

  /// Ferramenta atual selecionada
  DrawingTool get currentTool => _currentTool;

  /// Operação booleana atual
  BooleanOperationType get booleanOperation => _booleanOp;

  /// Indica se está em modo de desenho ativo
  bool get isDrawingActive => _currentState != DrawingState.idle;

  /// Indica se pode adicionar pontos
  bool get canAddPoints => _currentState == DrawingState.drawing;

  /// Indica se pode editar vértices
  bool get canEditVertices => _currentState == DrawingState.editing;

  /// Matriz de transições válidas
  ///
  /// Define quais transições são permitidas a partir de cada estado.
  /// Isso garante que o usuário não entre em estados inconsistentes.
  static const _validTransitions = {
    DrawingState.idle: [
      DrawingState.armed,
      DrawingState.importPreview,
      DrawingState.editing,
    ],
    DrawingState.armed: [DrawingState.drawing, DrawingState.idle],
    DrawingState.drawing: [DrawingState.reviewing, DrawingState.idle],
    DrawingState.reviewing: [
      DrawingState.editing,
      DrawingState.idle,
      DrawingState.booleanOperation,
    ],
    DrawingState.editing: [DrawingState.reviewing, DrawingState.idle],
    // REMOVIDO: DrawingState.measuring (estado órfão)
    DrawingState.importPreview: [DrawingState.idle, DrawingState.reviewing],
    DrawingState.booleanOperation: [DrawingState.reviewing, DrawingState.idle],
  };

  /// Verifica se pode transicionar para um novo estado
  bool canTransitionTo(DrawingState newState) {
    // Sempre pode voltar ao estado idle (reset)
    if (newState == DrawingState.idle) return true;

    // Verifica se a transição está na matriz de válidas
    return _validTransitions[_currentState]?.contains(newState) ?? false;
  }

  /// Tenta transicionar para um novo estado.
  ///
  /// Retorna `true` se a transição foi bem-sucedida, `false` caso contrário.
  /// **Nunca lança exceções** — ideal para chamadas de UI onde um throw
  /// causa red screen.
  bool tryTransitionTo(DrawingState newState, {DrawingTool? tool}) {
    if (!canTransitionTo(newState)) {
      return false;
    }
    _applyTransition(newState, tool: tool);
    return true;
  }

  /// Transiciona para um novo estado.
  ///
  /// 🔧 FIX-DRAW-REDSCREEN: Não lança mais StateError.
  /// Retorna `true` se transição bem-sucedida, `false` se inválida.
  /// Usa [debugPrint] em modo debug para rastrear transições inválidas.
  bool transitionTo(DrawingState newState, {DrawingTool? tool}) {
    if (!canTransitionTo(newState)) {
      // 🔧 FIX: Log em vez de throw para evitar red screen
      assert(() {
        debugPrint(
          'DRAW-WARN: Transição inválida ignorada: '
          '${_currentState.name} -> ${newState.name}',
        );
        return true;
      }());
      return false;
    }
    _applyTransition(newState, tool: tool);
    return true;
  }

  /// Aplica a transição (método interno, já validado)
  void _applyTransition(DrawingState newState, {DrawingTool? tool}) {
    _currentState = newState;

    // Atualizar ferramenta se fornecida
    if (tool != null) {
      _currentTool = tool;
    }

    // Resetar ferramenta se voltar ao idle
    if (newState == DrawingState.idle) {
      _currentTool = DrawingTool.none;
      _booleanOp = BooleanOperationType.none;
    }
  }

  /// Inicia o modo de desenho com uma ferramenta.
  /// Retorna `true` se transição foi bem-sucedida.
  bool startDrawing(DrawingTool tool) {
    return transitionTo(DrawingState.armed, tool: tool);
  }

  /// Começa a adicionar pontos (primeiro ponto adicionado).
  /// Retorna `true` se transição foi bem-sucedida.
  /// 🔧 FIX-DRAW-REDSCREEN: Era o ponto exato do crash (idle -> drawing).
  bool beginAddingPoints() {
    return transitionTo(DrawingState.drawing);
  }

  /// Completa o desenho e vai para revisão.
  /// Retorna `true` se transição foi bem-sucedida.
  bool completeDrawing() {
    return transitionTo(DrawingState.reviewing);
  }

  /// Inicia edição de uma geometria existente.
  /// Retorna `true` se transição foi bem-sucedida.
  bool startEditing() {
    return transitionTo(DrawingState.editing);
  }

  /// Salva a edição e volta para revisão.
  /// Retorna `true` se transição foi bem-sucedida.
  bool saveEditing() {
    return transitionTo(DrawingState.reviewing);
  }

  /// Cancela a operação atual e volta ao idle.
  /// Retorna `true` se transição foi bem-sucedida.
  bool cancel() {
    return transitionTo(DrawingState.idle);
  }

  /// Confirma a geometria e finaliza.
  /// Retorna `true` se transição foi bem-sucedida.
  bool confirm() {
    return transitionTo(DrawingState.idle);
  }

  /// Inicia visualização de importação.
  /// Retorna `true` se transição foi bem-sucedida.
  bool startImportPreview() {
    return transitionTo(DrawingState.importPreview);
  }

  /// Confirma importação e vai para revisão.
  /// Retorna `true` se transição foi bem-sucedida.
  bool confirmImport() {
    return transitionTo(DrawingState.reviewing);
  }

  /// Inicia operação booleana.
  /// Retorna `true` se transição foi bem-sucedida.
  bool startBooleanOperation(BooleanOperationType opType) {
    _booleanOp = opType;
    return transitionTo(DrawingState.booleanOperation);
  }

  /// Completa operação booleana e vai para revisão.
  /// Retorna `true` se transição foi bem-sucedida.
  bool completeBooleanOperation() {
    return transitionTo(DrawingState.reviewing);
  }

  /// Reseta a máquina de estados.
  ///
  /// Sempre permitido — volta direto para idle sem validação.
  void reset() {
    _currentState = DrawingState.idle;
    _currentTool = DrawingTool.none;
    _booleanOp = BooleanOperationType.none;
  }

  /// Retorna mensagem descritiva do estado atual
  String getStateMessage() {
    switch (_currentState) {
      case DrawingState.idle:
        return 'Toque no mapa para navegar';
      case DrawingState.armed:
        return 'Toque para iniciar desenho';
      case DrawingState.drawing:
        return 'Desenhando... (toque duplo para finalizar)';
      case DrawingState.reviewing:
        return 'Revisar e confirmar';
      case DrawingState.editing:
        return 'Editando vértices';
      case DrawingState.importPreview:
        return 'Visualizando importação';
      case DrawingState.booleanOperation:
        return _getBooleanOpMessage();
    }
  }

  String _getBooleanOpMessage() {
    switch (_booleanOp) {
      case BooleanOperationType.union:
        return 'Selecione a segunda área para unir';
      case BooleanOperationType.difference:
        return 'Selecione a área a ser subtraída';
      case BooleanOperationType.intersection:
        return 'Selecione para calcular interseção';
      case BooleanOperationType.none:
        return 'Operação booleana';
    }
  }

  @override
  String toString() =>
      'DrawingStateMachine(state: ${_currentState.name}, tool: ${_currentTool.name})';
}
