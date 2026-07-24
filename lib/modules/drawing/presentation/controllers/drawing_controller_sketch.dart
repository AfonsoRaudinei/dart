part of 'drawing_controller.dart';

/// Estado operacional por ferramenta — não usar `_currentPoints` como modelo universal.
extension DrawingControllerSketch on DrawingController {
  List<LatLng> get freehandTrail => List.unmodifiable(_freehandPoints);

  bool get isFreehandStrokeActive => _freehandStrokeActive;

  LatLng? get pivotCenter => _pivotCenter;

  LatLng? get pivotEdgePoint => _pivotPreviewEdge;

  bool get pivotRadiusFinalized => _pivotRadiusFinalized;

  double? get pivotRadiusMeters => _pivotRadiusMeters;

  int get polygonVertexCount => _currentPoints.length;

  int get freehandPointCount => _freehandPoints.length;

  String? get pendingDrawingSubtipo {
    if (_stateMachine.currentState != DrawingState.reviewing) return null;
    if (_stateMachine.currentTool == DrawingTool.pivot) return 'pivo';
    return null;
  }

  double? get pendingDrawingRaioMetros {
    if (_stateMachine.currentState != DrawingState.reviewing) return null;
    return _pivotRadiusMeters;
  }

  bool get canFinishDrawing {
    switch (_stateMachine.currentTool) {
      case DrawingTool.polygon:
        return _currentPoints.length >= 3;
      case DrawingTool.freehand:
        return !_freehandStrokeActive && _freehandPoints.length >= 3;
      case DrawingTool.pivot:
        return _pivotRadiusFinalized &&
            _pivotCenter != null &&
            (_pivotRadiusMeters ?? 0) > 0;
      default:
        return liveGeometry != null;
    }
  }

  String get finishDrawingHint {
    switch (_stateMachine.currentTool) {
      case DrawingTool.polygon:
        return 'Adicione pelo menos 3 pontos para criar um polígono';
      case DrawingTool.freehand:
        if (_freehandStrokeActive) {
          return 'Solte o dedo para concluir o traçado';
        }
        return 'Desenhe uma área contínua no mapa';
      case DrawingTool.pivot:
        if (_pivotCenter == null) {
          return 'Toque no mapa para definir o centro do pivô';
        }
        if (_pivotPreviewEdge == null) {
          return 'Toque novamente para definir o raio';
        }
        return 'Ajuste o raio ou toque em concluir para revisar';
      default:
        return 'Geometria inválida para finalizar';
    }
  }

  void _clearSketchState() {
    _currentPoints.clear();
    _freehandPoints.clear();
    _freehandStrokeActive = false;
    _pivotCenter = null;
    _pivotPreviewEdge = null;
    _pivotRadiusFinalized = false;
    _pivotRadiusMeters = null;
  }

  bool _ensureDrawingStarted() {
    if (_stateMachine.currentState == DrawingState.armed) {
      return _stateMachine.beginAddingPoints();
    }
    return _stateMachine.currentState == DrawingState.drawing;
  }

  DrawingGeometry? _buildPolygonLiveGeometry() {
    if (_currentPoints.isEmpty) return null;
    if (_currentPoints.length < 2) return null;

    final ring = _currentPoints
        .map((p) => <double>[p.longitude, p.latitude])
        .toList();

    if (_currentPoints.length >= 3) {
      final first = ring.first;
      final last = ring.last;
      final needsClosure =
          (first[0] - last[0]).abs() > 1e-9 ||
          (first[1] - last[1]).abs() > 1e-9;
      if (needsClosure) {
        ring.add(List<double>.from(first));
      }
    }

    return DrawingPolygon(coordinates: [ring]);
  }

  DrawingGeometry? _buildFreehandLiveGeometry() {
    if (_freehandPoints.length < 3 || _freehandStrokeActive) return null;
    return _buildClosedFreehandPolygon();
  }

  DrawingPolygon _buildClosedFreehandPolygon() {
    final ring = _freehandPoints
        .map((p) => <double>[p.longitude, p.latitude])
        .toList();
    final raw = DrawingPolygon(coordinates: [ring]);
    final simplified = DrawingUtils.simplifyGeometry(raw);
    if (simplified is DrawingPolygon) {
      return DrawingUtils.normalizeGeometry(simplified) as DrawingPolygon;
    }
    return DrawingUtils.normalizeGeometry(raw) as DrawingPolygon;
  }

  DrawingGeometry? _buildPivotLiveGeometry() {
    if (_pivotCenter == null || _pivotPreviewEdge == null) return null;
    final radius =
        _pivotRadiusMeters ??
        _distanceMeters(_pivotCenter!, _pivotPreviewEdge!);
    if (radius <= 0) return null;
    return DrawingUtils.createPivotPolygon(_pivotCenter!, radius);
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  void _appendPointWithMinDistance(List<LatLng> target, LatLng point) {
    if (target.isNotEmpty) {
      final last = target.last;
      if (_distanceMeters(last, point) <
          DrawingUtils.toleranciaMinDistanciaVertice) {
        return;
      }
    }
    target.add(point);
  }

  String _instructionForActiveTool() {
    switch (_stateMachine.currentTool) {
      case DrawingTool.polygon:
        final pointCount = _currentPoints.length;
        if (pointCount == 0) {
          return 'Toque no mapa para iniciar o polígono';
        }
        if (_isSnapping) return '⚡ Ponto ajustado (snap)';
        if (pointCount < 3) {
          return 'Continue tocando ou arraste um ponto para ajustar';
        }
        return 'Arraste um ponto para ajustar ou toque no inicial para fechar';
      case DrawingTool.freehand:
        if (_freehandStrokeActive) {
          return 'Mantenha o dedo pressionado e trace a área';
        }
        if (_freehandPoints.length >= 3) {
          return 'Toque em Concluir para revisar a área';
        }
        return 'Pressione e arraste no mapa para desenhar livremente';
      case DrawingTool.pivot:
        if (_pivotCenter == null) {
          return 'Toque no mapa para definir o centro do pivô';
        }
        if (_pivotPreviewEdge == null) {
          return 'Toque ou arraste para definir o raio';
        }
        return 'Ajuste o raio ou toque em concluir para revisar';
      default:
        return 'Toque no mapa para iniciar o desenho';
    }
  }

  void appendPolygonPoint(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.polygon &&
        _stateMachine.currentTool != DrawingTool.rectangle &&
        _stateMachine.currentTool != DrawingTool.circle) {
      return;
    }
    if (!_canAcceptSketchInput()) return;
    // Durante arraste de vértice, não adicionar ponto (gesto do handle).
    if (_isDraggingVertex) return;
    if (!_ensureDrawingStarted()) return;

    _currentPoints.add(point);
    _updateRealTimeIntersection();
    _notify();
  }

  /// Move um vértice do sketch em andamento (polígono / retângulo / círculo).
  ///
  /// Permite ajustar pontos no meio do desenho, no padrão GPS Fields.
  void moveSketchVertex(int index, LatLng newPos) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.polygon &&
        _stateMachine.currentTool != DrawingTool.rectangle &&
        _stateMachine.currentTool != DrawingTool.circle) {
      return;
    }
    if (_stateMachine.currentState != DrawingState.drawing &&
        _stateMachine.currentState != DrawingState.armed) {
      return;
    }
    if (index < 0 || index >= _currentPoints.length) return;

    _currentPoints[index] = newPos;
    _updateRealTimeIntersection();
    _notifyHost();
  }

  /// Restaura todos os pontos do polígono sketch (cancel de drag).
  void restoreSketchPoints(List<LatLng> points) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.polygon &&
        _stateMachine.currentTool != DrawingTool.rectangle &&
        _stateMachine.currentTool != DrawingTool.circle) {
      return;
    }
    _currentPoints
      ..clear()
      ..addAll(points);
    _updateRealTimeIntersection();
    _notify();
  }

  /// Move vértice da trilha freehand já finalizada (antes de concluir).
  void moveFreehandVertex(int index, LatLng newPos) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    if (_freehandStrokeActive) return;
    if (_stateMachine.currentState != DrawingState.drawing) return;
    if (index < 0 || index >= _freehandPoints.length) return;

    _freehandPoints[index] = newPos;
    _updateRealTimeIntersection();
    _notifyHost();
  }

  /// Restaura a trilha freehand (cancel de drag).
  void restoreFreehandPoints(List<LatLng> points) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    _freehandPoints
      ..clear()
      ..addAll(points);
    _updateRealTimeIntersection();
    _notify();
  }

  /// Reposiciona o centro do pivô durante o desenho.
  void movePivotCenter(LatLng newPos) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (_pivotCenter == null) return;
    if (_stateMachine.currentState != DrawingState.drawing &&
        _stateMachine.currentState != DrawingState.armed) {
      return;
    }

    _pivotCenter = newPos;
    if (_pivotPreviewEdge != null) {
      _pivotRadiusMeters = _distanceMeters(_pivotCenter!, _pivotPreviewEdge!);
    }
    _updateRealTimeIntersection();
    _notifyHost();
  }

  /// Restaura centro/borda/raio do pivô (cancel de drag).
  void restorePivotSketch({
    required LatLng? center,
    required LatLng? edge,
    required double? radiusMeters,
    required bool radiusFinalized,
  }) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    _pivotCenter = center;
    _pivotPreviewEdge = edge;
    _pivotRadiusMeters = radiusMeters;
    _pivotRadiusFinalized = radiusFinalized;
    _updateRealTimeIntersection();
    _notify();
  }

  void handlePivotTap(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (!_canAcceptSketchInput()) return;

    if (_pivotCenter == null) {
      if (!_ensureDrawingStarted()) return;
      _pivotCenter = point;
      _notify();
      return;
    }

    _setPivotPreview(point, finalize: true);
  }

  void updatePivotEdge(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (_pivotCenter == null) return;
    if (_stateMachine.currentState != DrawingState.drawing) return;

    _setPivotPreview(point, finalize: false);
  }

  void finalizePivotEdge(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (_pivotCenter == null) return;
    _setPivotPreview(point, finalize: true);
  }

  void _setPivotPreview(LatLng point, {required bool finalize}) {
    _pivotPreviewEdge = point;
    _pivotRadiusMeters = _distanceMeters(_pivotCenter!, point);
    _updateRealTimeIntersection();

    if (finalize && _pivotRadiusMeters! > 0) {
      _pivotRadiusFinalized = true;
    }

    _notify();
  }

  void beginFreehandStroke(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    if (!_canAcceptSketchInput()) return;
    if (!_ensureDrawingStarted()) return;

    _freehandPoints.clear();
    _freehandStrokeActive = true;
    _freehandPoints.add(point);
    _notify();
  }

  void extendFreehandStroke(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    if (!_freehandStrokeActive) return;

    _appendPointWithMinDistance(_freehandPoints, point);
    _notify();
  }

  void endFreehandStroke() {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    if (!_freehandStrokeActive) return;

    _freehandStrokeActive = false;

    if (_freehandPoints.length < 3) {
      _errorMessage = 'Traçado muito curto. Desenhe novamente.';
      _freehandPoints.clear();
      if (_stateMachine.currentState == DrawingState.drawing) {
        _stateMachine.tryTransitionTo(DrawingState.armed);
      }
      _notify();
      return;
    }

    _updateRealTimeIntersection();
    _notify();
  }

  bool _canAcceptSketchInput() {
    return _stateMachine.currentState == DrawingState.armed ||
        _stateMachine.currentState == DrawingState.drawing;
  }

  DrawingGeometry? buildSketchLiveGeometry() {
    switch (_stateMachine.currentTool) {
      case DrawingTool.polygon:
        return _buildPolygonLiveGeometry();
      case DrawingTool.freehand:
        return _buildFreehandLiveGeometry();
      case DrawingTool.pivot:
        return _buildPivotLiveGeometry();
      default:
        if (_currentPoints.isNotEmpty) {
          return _buildPolygonLiveGeometry();
        }
        return null;
    }
  }
}
