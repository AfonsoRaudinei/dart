part of 'drawing_controller.dart';

extension DrawingControllerVertexEditing on DrawingController {
  // ===========================================================================
  // VERTEX EDITING (RT-DRAW-06)
  // ===========================================================================

  /// Seleciona vértice em edição (mostra gota).
  bool selectEditVertex(int ringIndex, int pointIndex) {
    if (_isDisposed) return false;
    if (_stateMachine.currentState != DrawingState.editing) return false;
    if (_editGeometry is! DrawingPolygon) return false;

    final poly = _editGeometry as DrawingPolygon;
    if (ringIndex < 0 || ringIndex >= poly.coordinates.length) return false;
    final ring = poly.coordinates[ringIndex];
    if (pointIndex < 0 || pointIndex >= ring.length) return false;

    final isClosed =
        ring.length > 1 &&
        ring.first[0] == ring.last[0] &&
        ring.first[1] == ring.last[1];
    final logicalLength = isClosed ? ring.length - 1 : ring.length;
    if (pointIndex >= logicalLength) return false;

    _selectedEditRingIndex = ringIndex;
    _selectedEditPointIndex = pointIndex;
    _notify();
    return true;
  }

  void clearEditVertexSelection() {
    if (_selectedEditRingIndex == null && _selectedEditPointIndex == null) {
      return;
    }
    _selectedEditRingIndex = null;
    _selectedEditPointIndex = null;
    _notify();
  }

  /// Hit-test por proximidade para vértices em edição (fallback via onTap do mapa).
  ({int ring, int point})? findEditVertexNear(
    LatLng tap,
    double toleranceMeters,
  ) {
    if (_stateMachine.currentState != DrawingState.editing) return null;
    if (_editGeometry is! DrawingPolygon) return null;

    final poly = _editGeometry as DrawingPolygon;
    int? bestRing;
    int? bestPoint;
    var closestDist = toleranceMeters;

    for (var ringIdx = 0; ringIdx < poly.coordinates.length; ringIdx++) {
      final ringRaw = poly.coordinates[ringIdx];
      final ring = ringRaw.map((p) => LatLng(p[1], p[0])).toList();
      final isClosed =
          ring.isNotEmpty &&
          ring.first.latitude == ring.last.latitude &&
          ring.first.longitude == ring.last.longitude;
      final logicalLength = isClosed ? ring.length - 1 : ring.length;

      for (var i = 0; i < logicalLength; i++) {
        final dist = const Distance().as(LengthUnit.Meter, ring[i], tap);
        if (dist <= closestDist) {
          closestDist = dist;
          bestRing = ringIdx;
          bestPoint = i;
        }
      }
    }

    if (bestRing == null || bestPoint == null) return null;
    return (ring: bestRing, point: bestPoint);
  }

  /// Hit-test da aresta mais próxima do toque, para inserir um vértice nela.
  ({int ring, int segment, LatLng point})? findEditEdgeNear(
    LatLng tap,
    double toleranceMeters,
  ) {
    if (_stateMachine.currentState != DrawingState.editing) return null;
    if (_editGeometry is! DrawingPolygon) return null;

    final poly = _editGeometry as DrawingPolygon;
    int? bestRing;
    int? bestSegment;
    LatLng? bestPoint;
    var closestDist = toleranceMeters;

    for (var ringIdx = 0; ringIdx < poly.coordinates.length; ringIdx++) {
      final ring = poly.coordinates[ringIdx]
          .map((p) => LatLng(p[1], p[0]))
          .toList();
      if (ring.length < 2) continue;
      final isClosed =
          ring.first.latitude == ring.last.latitude &&
          ring.first.longitude == ring.last.longitude;
      final segmentCount = ring.length - 1;

      for (var i = 0; i < segmentCount; i++) {
        final next = isClosed && i == segmentCount - 1
            ? ring.first
            : ring[i + 1];
        final hit = DrawingUtils.closestPointOnSegment(tap, ring[i], next);
        if (hit.distanceMeters <= closestDist) {
          closestDist = hit.distanceMeters;
          bestRing = ringIdx;
          bestSegment = i;
          bestPoint = hit.point;
        }
      }
    }

    if (bestRing == null || bestSegment == null || bestPoint == null) {
      return null;
    }
    return (ring: bestRing, segment: bestSegment, point: bestPoint);
  }

  /// Toque no mapa em edição.
  ///
  /// Projeção no meio do trecho insere o vértice ali. Projeção na ponta
  /// seleciona a bolinha, sem duplicar. Fora da linha, limpa a gota.
  ///
  /// Retorna false quando o toque não altera seleção nem geometria.
  bool applyEditMapTap(
    LatLng tap, {
    required double vertexToleranceMeters,
    required double edgeToleranceMeters,
  }) {
    if (_isDisposed) return false;
    if (_stateMachine.currentState != DrawingState.editing) return false;
    if (_editGeometry is! DrawingPolygon) return false;

    final edge = findEditEdgeNear(tap, edgeToleranceMeters);
    if (edge != null && _editEdgePointIsInterior(edge, vertexToleranceMeters)) {
      insertVertex(edge.ring, edge.segment, edge.point);
      return true;
    }

    final hit = findEditVertexNear(tap, vertexToleranceMeters);
    if (hit != null) {
      _toggleEditVertex(hit.ring, hit.point);
      return true;
    }

    if (edge != null) {
      final end = _closerEdgeEndpoint(edge);
      _toggleEditVertex(end.ring, end.point);
      return true;
    }

    if (_selectedEditRingIndex != null || _selectedEditPointIndex != null) {
      clearEditVertexSelection();
      return true;
    }
    return false;
  }

  void _toggleEditVertex(int ring, int point) {
    if (_selectedEditRingIndex == ring && _selectedEditPointIndex == point) {
      clearEditVertexSelection();
      return;
    }
    selectEditVertex(ring, point);
  }

  /// A projeção está longe das duas pontas do trecho (não é a bolinha).
  bool _editEdgePointIsInterior(
    ({int ring, int segment, LatLng point}) edge,
    double minMetersFromEnds,
  ) {
    final ends = _edgeEndpoints(edge);
    if (ends == null) return false;
    const distance = Distance();
    final fromStart = distance.as(LengthUnit.Meter, edge.point, ends.$1);
    final fromEnd = distance.as(LengthUnit.Meter, edge.point, ends.$2);
    return fromStart > minMetersFromEnds && fromEnd > minMetersFromEnds;
  }

  ({int ring, int point}) _closerEdgeEndpoint(
    ({int ring, int segment, LatLng point}) edge,
  ) {
    final ends = _edgeEndpoints(edge);
    if (ends == null) return (ring: edge.ring, point: edge.segment);
    const distance = Distance();
    final fromStart = distance.as(LengthUnit.Meter, edge.point, ends.$1);
    final fromEnd = distance.as(LengthUnit.Meter, edge.point, ends.$2);
    if (fromStart <= fromEnd) {
      return (ring: edge.ring, point: edge.segment);
    }
    final poly = _editGeometry! as DrawingPolygon;
    final ring = poly.coordinates[edge.ring];
    final isClosed =
        ring.length > 1 &&
        ring.first[0] == ring.last[0] &&
        ring.first[1] == ring.last[1];
    final logicalLength = isClosed ? ring.length - 1 : ring.length;
    final next = edge.segment + 1;
    return (ring: edge.ring, point: next >= logicalLength ? 0 : next);
  }

  (LatLng, LatLng)? _edgeEndpoints(
    ({int ring, int segment, LatLng point}) edge,
  ) {
    final geometry = _editGeometry;
    if (geometry is! DrawingPolygon) return null;
    if (edge.ring < 0 || edge.ring >= geometry.coordinates.length) return null;
    final ring = geometry.coordinates[edge.ring];
    if (edge.segment < 0 || edge.segment + 1 >= ring.length) return null;
    final start = ring[edge.segment];
    final end = ring[edge.segment + 1];
    return (LatLng(start[1], start[0]), LatLng(end[1], end[0]));
  }

  void _throttledValidate() {
    // Logic from old updateEditGeometry
    final count = DrawingUtils.getVertexCount(_editGeometry);
    final isComplex = count > DrawingController._complexityThreshold;

    if (isComplex) {
      _validationDebounce?.cancel();
      _validationDebounce = Timer(
        const Duration(milliseconds: DrawingController._validationDebounceMs),
        () {
          if (_isDisposed) return;
          validateGeometry(_editGeometry, forceFull: false);
          _notify();
        },
      );
      // Immediate basic check?
      // validateGeometry(_editGeometry, forceFull: false); // maybe too heavy?
    } else {
      validateGeometry(_editGeometry);
    }
  }

  void _notifyHost() {
    if (_isDisposed) return;
    if (!_isDraggingVertex) {
      _notify();
      return;
    }
    if (_notifyThrottleTimer?.isActive ?? false) return;
    _notify();
    _notifyThrottleTimer = Timer(
      const Duration(milliseconds: DrawingController._notifyThrottleMs),
      () {},
    );
  }

  /// Moves a single vertex to a new position.
  /// Delega para [DrawingVertexEditService.moveVertex].
  void moveVertex(int ringIndex, int pointIndex, LatLng newPos) {
    if (_editGeometry is! DrawingPolygon) return;

    final updated = _vertexService.moveVertex(
      _editGeometry as DrawingPolygon,
      ringIndex,
      pointIndex,
      newPos,
    );
    if (updated == null) return;

    _editGeometry = updated;
    _updateRealTimeIntersection();
    _throttledValidate();
    _notifyHost();
  }

  /// Persiste a nova posição do vértice ao finalizar o arraste.
  ///
  /// Fluxo esperado:
  /// - Durante o drag, a UI mantém estado local (sem persistir)
  /// - Ao soltar, este método aplica o ponto final no _editGeometry
  /// - Atualiza validações/interseções e persiste na feature selecionada
  void updateVertexPosition(int ringIndex, int pointIndex, LatLng newPos) {
    if (_editGeometry is! DrawingPolygon) return;

    final updated = _vertexService.moveVertex(
      _editGeometry as DrawingPolygon,
      ringIndex,
      pointIndex,
      newPos,
    );
    if (updated == null) return;

    _editGeometry = updated;
    _updateRealTimeIntersection();
    validateGeometry(_editGeometry);

    if (_selectedFeature != null) {
      updateFeature(
        _selectedFeature!.id,
        newGeometry: _editGeometry,
        editorId: "sistema",
        editorType: AuthorType.sistema,
      );
    }

    _notify();
  }

  /// Início de arraste na UI — sem notify (o overlay não pode reconstruir o mapa).
  void beginEditVertexDrag([int? index, int ringIndex = 0]) {
    if (_isDisposed) return;
    _isDraggingVertex = true;
    _draggedVertexIndex = index;
    if (index != null) {
      _selectedEditRingIndex = ringIndex;
      _selectedEditPointIndex = index;
    }
    if (_editGeometry != null) {
      _history.push(_geomToVertices(_editGeometry!));
    }
  }

  /// Call this when starting a drag operation to save state for Undo
  void onDragStart([int? index]) {
    beginEditVertexDrag(index);
    _notify();
  }

  /// Call this when ending a drag operation.
  /// [persist] mantém compatibilidade com fluxo legado:
  /// - true: persiste _editGeometry ao fim do arraste
  /// - false: apenas encerra estado de drag (quando já persistido externamente)
  void onDragEnd({bool persist = true}) {
    _isDraggingVertex = false;
    _draggedVertexIndex = null;

    if (persist && _editGeometry != null && _selectedFeature != null) {
      updateFeature(
        _selectedFeature!.id,
        newGeometry: _editGeometry,
        editorId: "sistema",
        editorType: AuthorType.sistema,
      );
    }

    _notify();
  }

  /// Inserts a new vertex after the specified segment index.
  /// Delega para [DrawingVertexEditService.insertVertex].
  void insertVertex(int ringIndex, int segmentIndex, LatLng point) {
    if (_editGeometry is! DrawingPolygon) return;

    if (_editGeometry != null) {
      _history.push(_geomToVertices(_editGeometry!));
    }

    final updated = _vertexService.insertVertex(
      _editGeometry as DrawingPolygon,
      ringIndex,
      segmentIndex,
      point,
    );
    if (updated == null) return;

    _editGeometry = updated;
    _updateRealTimeIntersection();
    validateGeometry(_editGeometry);
    selectEditVertex(ringIndex, segmentIndex + 1);
  }

  /// Removes a vertex at the specified index.
  /// Delega para [DrawingVertexEditService.removeVertex].
  void removeVertex(int ringIndex, int pointIndex) {
    if (_editGeometry is! DrawingPolygon) return;

    final result = _vertexService.removeVertex(
      _editGeometry as DrawingPolygon,
      ringIndex,
      pointIndex,
    );

    if (result.error != null) {
      _errorMessage = result.error;
      _notify();
      return;
    }

    if (result.geometry == null) return;

    onDragStart(); // salva estado para undo
    _editGeometry = result.geometry;
    _updateRealTimeIntersection();
    validateGeometry(_editGeometry);
    _notify();
  }
}
