import 'package:latlong2/latlong.dart';

/// Histórico de estados do desenho com suporte a Undo e Redo.
///
/// Mantém um buffer circular de snapshots de geometria, representado como
/// lista de vértices ([List<LatLng>]). O cursor aponta para o estado "atual".
///
/// ### Invariantes
/// - `_cursor` sempre aponta para um índice válido quando `isNotEmpty`
/// - Push de novo estado descarta qualquer estado "futuro" (à frente do cursor)
/// - Capacidade máxima definida por [maxStates] (evita uso de memória crescente)
///
/// ### Uso
/// ```dart
/// final history = DrawingHistory();
/// history.push(initialVertices);
///
/// history.push(newVertices);  // adiciona estado
/// history.undo();              // volta ao estado anterior
/// history.redo();              // avança para próximo estado
/// final current = history.current; // lê estado atual
/// ```
class DrawingHistory {
  DrawingHistory({this.maxStates = 50});

  /// Número máximo de estados mantidos no histórico.
  final int maxStates;

  final List<List<LatLng>> _states = [];
  int _cursor = -1;

  // ─── Consultas ────────────────────────────────────────────────────────────

  /// `true` se houver pelo menos um estado registrado.
  bool get isNotEmpty => _states.isNotEmpty;

  /// `true` se não houver nenhum estado registrado.
  bool get isEmpty => _states.isEmpty;

  /// `true` se for possível desfazer (cursor > 0).
  bool get canUndo => _cursor > 0;

  /// `true` se for possível refazer (cursor está antes do último estado).
  bool get canRedo => _cursor < _states.length - 1;

  /// Estado atual (vértices do snapshot apontado pelo cursor).
  /// Retorna `null` se o histórico estiver vazio.
  List<LatLng>? get current =>
      isNotEmpty ? List.unmodifiable(_states[_cursor]) : null;

  /// Número de estados registrados.
  int get length => _states.length;

  // ─── Mutações ─────────────────────────────────────────────────────────────

  /// Registra um novo estado descartando todos os estados "futuros" (redo branch).
  ///
  /// Se o novo estado for idêntico ao estado atual, é ignorado (idempotente).
  void push(List<LatLng> vertices) {
    // Idempotência — não registrar duplicatas consecutivas
    if (isNotEmpty && _verticesEqual(_states[_cursor], vertices)) return;

    // Descartar estados futuros (redo branch)
    if (_cursor < _states.length - 1) {
      _states.removeRange(_cursor + 1, _states.length);
    }

    // Respeitar capacidade máxima (descarta o mais antigo)
    if (_states.length >= maxStates) {
      _states.removeAt(0);
      // cursor já aponta para o mesmo estado relativo (deslocado -1)
      if (_cursor > 0) _cursor--;
    }

    _states.add(List<LatLng>.from(vertices));
    _cursor = _states.length - 1;
  }

  /// Volta para o estado anterior. Retorna o novo estado atual, ou `null`
  /// se não for possível desfazer.
  List<LatLng>? undo() {
    if (!canUndo) return null;
    _cursor--;
    return current;
  }

  /// Avança para o próximo estado. Retorna o novo estado atual, ou `null`
  /// se não for possível refazer.
  List<LatLng>? redo() {
    if (!canRedo) return null;
    _cursor++;
    return current;
  }

  /// Limpa todo o histórico e reinicia o cursor.
  void clear() {
    _states.clear();
    _cursor = -1;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _verticesEqual(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i].latitude - b[i].latitude).abs() > 1e-10 ||
          (a[i].longitude - b[i].longitude).abs() > 1e-10) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'DrawingHistory(states: ${_states.length}, cursor: $_cursor, '
      'canUndo: $canUndo, canRedo: $canRedo)';
}
