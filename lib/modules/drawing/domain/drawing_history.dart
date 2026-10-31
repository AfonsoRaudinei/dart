import 'package:latlong2/latlong.dart';

import 'models/drawing_models.dart';

/// Histórico de estados do desenho com suporte a Undo e Redo.
///
/// Mantém um buffer circular de snapshots de geometria, representado como
/// lista de vértices ([List<LatLng>]). O cursor aponta para o estado "atual".
///
/// Quando [push] recebe [fullPolygonSnapshot], o undo restaura todos os anéis
/// (furos inclusos), não só o contorno externo.
///
/// ### Invariantes
/// - `_cursor` sempre aponta para um índice válido quando `isNotEmpty`
/// - Push de novo estado descarta qualquer estado "futuro" (à frente do cursor)
/// - Capacidade máxima definida por [maxStates] (evita uso de memória crescente)
class DrawingHistory {
  DrawingHistory({this.maxStates = 50});

  /// Número máximo de estados mantidos no histórico.
  final int maxStates;

  final List<List<LatLng>> _states = [];
  final List<DrawingPolygon?> _fullPolygonSnapshots = [];
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

  /// Polígono completo no cursor, quando registrado via [fullPolygonSnapshot].
  DrawingPolygon? get currentFullPolygon {
    if (!isNotEmpty || _cursor < 0 || _cursor >= _fullPolygonSnapshots.length) {
      return null;
    }
    final snap = _fullPolygonSnapshots[_cursor];
    if (snap == null) return null;
    return _clonePolygon(snap);
  }

  /// Número de estados registrados.
  int get length => _states.length;

  // ─── Mutações ─────────────────────────────────────────────────────────────

  /// Registra um novo estado descartando todos os estados "futuros" (redo branch).
  ///
  /// Se o novo estado for idêntico ao estado atual (só vértices externos), é
  /// ignorado — exceto quando [fullPolygonSnapshot] distingue furos/anéis.
  void push(
    List<LatLng> vertices, {
    DrawingPolygon? fullPolygonSnapshot,
  }) {
    final skipDuplicate =
        fullPolygonSnapshot == null &&
        isNotEmpty &&
        _verticesEqual(_states[_cursor], vertices);
    if (skipDuplicate) return;

    if (_cursor < _states.length - 1) {
      _states.removeRange(_cursor + 1, _states.length);
      _fullPolygonSnapshots.removeRange(_cursor + 1, _fullPolygonSnapshots.length);
    }

    if (_states.length >= maxStates) {
      _states.removeAt(0);
      if (_fullPolygonSnapshots.isNotEmpty) {
        _fullPolygonSnapshots.removeAt(0);
      }
      if (_cursor > 0) _cursor--;
    }

    _states.add(List<LatLng>.from(vertices));
    _fullPolygonSnapshots.add(
      fullPolygonSnapshot != null
          ? _clonePolygon(fullPolygonSnapshot)
          : null,
    );
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
    _fullPolygonSnapshots.clear();
    _cursor = -1;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static DrawingPolygon _clonePolygon(DrawingPolygon poly) {
    return DrawingPolygon(
      coordinates: poly.coordinates
          .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
          .toList(),
    );
  }

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
