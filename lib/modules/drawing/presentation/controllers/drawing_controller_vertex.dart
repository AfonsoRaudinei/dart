part of 'drawing_controller.dart';

extension DrawingControllerVertexEditing on DrawingController {
  // ===========================================================================
  // VERTEX EDITING (RT-DRAW-06)
  // ===========================================================================

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

  /// Call this when starting a drag operation to save state for Undo
  void onDragStart([int? index]) {
    _isDraggingVertex = true;
    _draggedVertexIndex = index;
    if (_editGeometry != null) {
      _history.push(_geomToVertices(_editGeometry!));
    }
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

    onDragStart(); // salva estado para undo

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
    _notify();
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
