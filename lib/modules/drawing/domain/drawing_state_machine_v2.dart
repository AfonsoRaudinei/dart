/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE V2 — DECLARATIVE & EVENT-DRIVEN
════════════════════════════════════════════════════════════════════

ARQUITETURA:
- 📦 Declarativa: Matriz de transições imutável
- 🔒 Hermética: Nenhuma transição implícita
- 🔁 Undo/Redo formal: Eventos de primeira classe
- 🧪 100% testável: Toda combinação estado×evento
- 🛠 Múltiplas ferramentas: Context composto (state + mode)

PRINCÍPIOS:
1. Estado é imutável (snapshot + undo/redo stacks)
2. Mudanças via eventos (dispatch)
3. Transições via matriz declarativa
4. Controller não altera estado diretamente
5. Tudo rastreável e reversível

════════════════════════════════════════════════════════════════════
*/

import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════
// ENUMS — Estados, Modos e Eventos
// ═══════════════════════════════════════════════════════════════════

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
}

/// Modos de desenho (ferramentas)
enum DrawingMode { none, polygon, freehand, pivot, rectangle, circle }

/// Tipos de operações booleanas
enum BooleanOperationType { none, union, difference, intersection }

/// Eventos que podem ocorrer na máquina
enum DrawingEvent {
  /// Selecionar ferramenta
  selectTool,

  /// Adicionar ponto
  addPoint,

  /// Desfazer último ponto/ação
  undo,

  /// Refazer ponto/ação
  redo,

  /// Completar desenho
  complete,

  /// Cancelar operação atual
  cancel,

  /// Confirmar geometria
  confirm,

  /// Iniciar edição
  startEdit,

  /// Salvar edição
  saveEdit,

  /// Iniciar importação
  startImport,

  /// Confirmar importação
  confirmImport,

  /// Iniciar operação booleana
  startBooleanOp,

  /// Completar operação booleana
  completeBooleanOp,
}

// ═══════════════════════════════════════════════════════════════════
// CONTEXT — Estado Composto (State + Mode + Metadata)
// ═══════════════════════════════════════════════════════════════════

/// Contexto completo do desenho (imutável)
@immutable
class DrawingContext {
  final DrawingState state;
  final DrawingMode mode;
  final BooleanOperationType booleanOp;
  final int pointsCount;

  const DrawingContext({
    required this.state,
    this.mode = DrawingMode.none,
    this.booleanOp = BooleanOperationType.none,
    this.pointsCount = 0,
  });

  /// Estado inicial
  factory DrawingContext.initial() =>
      const DrawingContext(state: DrawingState.idle, mode: DrawingMode.none);

  /// Copiar com mudanças
  DrawingContext copyWith({
    DrawingState? state,
    DrawingMode? mode,
    BooleanOperationType? booleanOp,
    int? pointsCount,
  }) {
    return DrawingContext(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      booleanOp: booleanOp ?? this.booleanOp,
      pointsCount: pointsCount ?? this.pointsCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingContext &&
          state == other.state &&
          mode == other.mode &&
          booleanOp == other.booleanOp &&
          pointsCount == other.pointsCount;

  @override
  int get hashCode => Object.hash(state, mode, booleanOp, pointsCount);

  @override
  String toString() =>
      'DrawingContext(state: $state, mode: $mode, points: $pointsCount)';
}

// ═══════════════════════════════════════════════════════════════════
// SNAPSHOT — Estado completo para undo/redo
// ═══════════════════════════════════════════════════════════════════

/// Snapshot imutável do estado completo
@immutable
class DrawingSnapshot {
  final DrawingContext context;
  final DateTime timestamp;

  const DrawingSnapshot({required this.context, required this.timestamp});

  factory DrawingSnapshot.now(DrawingContext context) {
    return DrawingSnapshot(context: context, timestamp: DateTime.now());
  }
}

// ═══════════════════════════════════════════════════════════════════
// TRANSITION RESULT — Resultado de uma transição
// ═══════════════════════════════════════════════════════════════════

/// Resultado de uma tentativa de transição
@immutable
class TransitionResult {
  final bool success;
  final DrawingContext? newContext;
  final String? errorMessage;

  const TransitionResult.success(this.newContext)
    : success = true,
      errorMessage = null;

  const TransitionResult.failure(this.errorMessage)
    : success = false,
      newContext = null;

  bool get isSuccess => success;
  bool get isFailure => !success;
}

// ═══════════════════════════════════════════════════════════════════
// STATE MACHINE V2 — Declarativa e Event-Driven
// ═══════════════════════════════════════════════════════════════════

/// Máquina de estados declarativa para módulo de desenho
class DrawingStateMachineV2 {
  // ─────────────────────────────────────────────────────────────────
  // Estado atual e histórico
  // ─────────────────────────────────────────────────────────────────

  DrawingContext _currentContext;
  final List<DrawingSnapshot> _undoStack = [];
  final List<DrawingSnapshot> _redoStack = [];

  // Limites de histórico
  static const int _maxUndoStackSize = 50;

  DrawingStateMachineV2() : _currentContext = DrawingContext.initial() {
    _pushToUndoStack(); // Estado inicial no histórico
  }

  // ─────────────────────────────────────────────────────────────────
  // Getters públicos
  // ─────────────────────────────────────────────────────────────────

  DrawingContext get currentContext => _currentContext;
  DrawingState get currentState => _currentContext.state;
  DrawingMode get currentMode => _currentContext.mode;
  BooleanOperationType get booleanOperation => _currentContext.booleanOp;

  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isDrawingActive => _currentContext.state != DrawingState.idle;

  // ─────────────────────────────────────────────────────────────────
  // MATRIZ DE TRANSIÇÕES DECLARATIVA (IMUTÁVEL)
  // ─────────────────────────────────────────────────────────────────

  /// Matriz de transições válidas: Estado × Evento → Novo Estado
  static const Map<DrawingState, Map<DrawingEvent, DrawingState>>
  _transitionMatrix = {
    // De: idle
    DrawingState.idle: {
      DrawingEvent.selectTool: DrawingState.armed,
      DrawingEvent.startEdit: DrawingState.editing,
      DrawingEvent.startImport: DrawingState.importPreview,
      DrawingEvent.undo: DrawingState.idle, // Permanece
      DrawingEvent.redo: DrawingState.idle, // Permanece
    },

    // De: armed
    DrawingState.armed: {
      DrawingEvent.addPoint: DrawingState.drawing,
      DrawingEvent.selectTool: DrawingState.armed, // Trocar ferramenta
      DrawingEvent.cancel: DrawingState.idle,
      DrawingEvent.undo: DrawingState.idle, // Se desfazer seleção
    },

    // De: drawing
    DrawingState.drawing: {
      DrawingEvent.addPoint: DrawingState.drawing, // Adicionar mais pontos
      DrawingEvent.undo:
          DrawingState.drawing, // Remove ponto (pode voltar a armed)
      DrawingEvent.redo: DrawingState.drawing,
      DrawingEvent.complete: DrawingState.reviewing,
      DrawingEvent.cancel: DrawingState.idle,
    },

    // De: reviewing
    DrawingState.reviewing: {
      DrawingEvent.startEdit: DrawingState.editing,
      DrawingEvent.confirm: DrawingState.idle,
      DrawingEvent.cancel: DrawingState.idle,
      DrawingEvent.startBooleanOp: DrawingState.booleanOperation,
    },

    // De: editing
    DrawingState.editing: {
      DrawingEvent.saveEdit: DrawingState.reviewing,
      DrawingEvent.cancel:
          DrawingState.reviewing, // 🔧 FIX: Volta para reviewing
      DrawingEvent.undo: DrawingState.editing,
      DrawingEvent.redo: DrawingState.editing,
    },

    // De: importPreview
    DrawingState.importPreview: {
      DrawingEvent.confirmImport: DrawingState.reviewing,
      DrawingEvent.cancel: DrawingState.idle,
    },

    // De: booleanOperation
    DrawingState.booleanOperation: {
      DrawingEvent.completeBooleanOp: DrawingState.reviewing,
      DrawingEvent.cancel: DrawingState.idle,
    },
  };

  // ─────────────────────────────────────────────────────────────────
  // DISPATCH — Processar evento
  // ─────────────────────────────────────────────────────────────────

  /// Despacha um evento para a máquina
  ///
  /// Esta é a ÚNICA forma de mudar estado.
  /// Retorna resultado da transição.
  TransitionResult dispatch(
    DrawingEvent event, {
    DrawingMode? newMode,
    BooleanOperationType? newBooleanOp,
    int? deltaPoints,
  }) {
    // Casos especiais de undo/redo
    if (event == DrawingEvent.undo) {
      return _handleUndo();
    }
    if (event == DrawingEvent.redo) {
      return _handleRedo();
    }

    // Verificar se transição é válida
    final transitions = _transitionMatrix[_currentContext.state];
    if (transitions == null || !transitions.containsKey(event)) {
      return TransitionResult.failure(
        'Transição inválida: ${_currentContext.state.name} + ${event.name}',
      );
    }

    final newState = transitions[event]!;

    // Criar novo contexto
    final newContext = _buildNewContext(
      newState: newState,
      event: event,
      newMode: newMode,
      newBooleanOp: newBooleanOp,
      deltaPoints: deltaPoints,
    );

    // Aplicar transição
    _applyTransition(newContext);

    return TransitionResult.success(newContext);
  }

  // ─────────────────────────────────────────────────────────────────
  // UNDO/REDO — Eventos formais (MODELO PURO)
  // ─────────────────────────────────────────────────────────────────

  /// Undo: volta ao snapshot anterior
  ///
  /// MODELO PURO: cada dispatch cria snapshot, undo sempre volta anterior
  /// Sem lógica especial para pontos - tudo é snapshot
  TransitionResult _handleUndo() {
    if (!canUndo) {
      return const TransitionResult.failure('Nada para desfazer');
    }

    // Salvar estado atual no redo antes de desfazer
    _redoStack.add(DrawingSnapshot.now(_currentContext));

    // Remover estado atual do undo stack
    _undoStack.removeLast();

    // Voltar ao estado anterior (último do stack)
    final previousSnapshot = _undoStack.last;
    _currentContext = previousSnapshot.context;

    if (kDebugMode) {
      debugPrint('UNDO: ${_currentContext.state.name}');
    }

    return TransitionResult.success(_currentContext);
  }

  /// Redo: refaz última ação desfeita
  TransitionResult _handleRedo() {
    if (!canRedo) {
      return const TransitionResult.failure('Nada para refazer');
    }

    // Pegar snapshot do redo
    final snapshot = _redoStack.removeLast();

    // Adicionar estado atual ao undo (para poder desfazer o redo)
    _undoStack.add(DrawingSnapshot.now(_currentContext));

    // Restaurar estado
    _currentContext = snapshot.context;

    if (kDebugMode) {
      debugPrint('REDO: ${_currentContext.state.name}');
    }

    return TransitionResult.success(_currentContext);
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS — Construção de contexto e aplicação de transições
  // ─────────────────────────────────────────────────────────────────

  DrawingContext _buildNewContext({
    required DrawingState newState,
    required DrawingEvent event,
    DrawingMode? newMode,
    BooleanOperationType? newBooleanOp,
    int? deltaPoints,
  }) {
    // Resetar modo e operação booleana se voltar para idle
    if (newState == DrawingState.idle) {
      return DrawingContext(
        state: newState,
        mode: DrawingMode.none,
        booleanOp: BooleanOperationType.none,
        pointsCount: 0,
      );
    }

    // Atualizar pontos se fornecido
    int newPointsCount = _currentContext.pointsCount;
    if (deltaPoints != null) {
      newPointsCount += deltaPoints;
    } else if (event == DrawingEvent.addPoint) {
      newPointsCount++;
    } else if (event == DrawingEvent.complete || event == DrawingEvent.cancel) {
      newPointsCount = 0;
    }

    return _currentContext.copyWith(
      state: newState,
      mode: newMode,
      booleanOp: newBooleanOp,
      pointsCount: newPointsCount,
    );
  }

  void _applyTransition(DrawingContext newContext) {
    _currentContext = newContext;
    _pushToUndoStack();

    // Limpa redo stack ao fazer nova ação
    _redoStack.clear();

    if (kDebugMode) {
      debugPrint('TRANSITION: ${_currentContext.state.name}');
    }
  }

  void _pushToUndoStack() {
    _undoStack.add(DrawingSnapshot.now(_currentContext));

    // Limitar tamanho do stack
    if (_undoStack.length > _maxUndoStackSize) {
      _undoStack.removeAt(0);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // VALIDAÇÃO — Verificar se transição é possível
  // ─────────────────────────────────────────────────────────────────

  /// Verifica se pode transicionar com o evento dado
  bool canDispatch(DrawingEvent event) {
    if (event == DrawingEvent.undo) return canUndo;
    if (event == DrawingEvent.redo) return canRedo;

    final transitions = _transitionMatrix[_currentContext.state];
    return transitions != null && transitions.containsKey(event);
  }

  /// Retorna próximo estado se evento for despachado (sem executar)
  DrawingState? getNextState(DrawingEvent event) {
    if (event == DrawingEvent.undo && canUndo) {
      return _undoStack[_undoStack.length - 2].context.state;
    }
    if (event == DrawingEvent.redo && canRedo) {
      return _redoStack.last.context.state;
    }

    final transitions = _transitionMatrix[_currentContext.state];
    return transitions?[event];
  }

  // ─────────────────────────────────────────────────────────────────
  // RESET — Voltar ao estado inicial
  // ─────────────────────────────────────────────────────────────────

  void reset() {
    _currentContext = DrawingContext.initial();
    _undoStack.clear();
    _redoStack.clear();
    _pushToUndoStack();

    if (kDebugMode) {
      debugPrint('RESET: máquina reiniciada');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // DEBUG — Mensagens de estado
  // ─────────────────────────────────────────────────────────────────

  String getStateMessage() {
    switch (_currentContext.state) {
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
    switch (_currentContext.booleanOp) {
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
  String toString() => 'DrawingStateMachineV2($_currentContext)';
}
