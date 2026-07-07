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
        return 'Toque novamente para definir o raio';
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
        _pivotRadiusMeters ?? _distanceMeters(_pivotCenter!, _pivotPreviewEdge!);
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
          return 'Continue tocando para fechar o polígono';
        }
        return 'Toque para continuar ou no ponto inicial para fechar';
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
        return 'Confirme o círculo do pivô';
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
    if (!_ensureDrawingStarted()) return;

    _currentPoints.add(point);
    _updateRealTimeIntersection();
    notifyListeners();
  }

  void handlePivotTap(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (!_canAcceptSketchInput()) return;

    if (_pivotCenter == null) {
      if (!_ensureDrawingStarted()) return;
      _pivotCenter = point;
      notifyListeners();
      return;
    }

    _setPivotPreview(point, finalize: true);
  }

  void updatePivotEdge(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (_pivotCenter == null) return;
    if (_stateMachine.currentState != DrawingState.drawing) return;
    if (_pivotRadiusFinalized) return;

    _setPivotPreview(point, finalize: false);
  }

  void finalizePivotEdge(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.pivot) return;
    if (_pivotCenter == null || _pivotRadiusFinalized) return;
    _setPivotPreview(point, finalize: true);
  }

  void _setPivotPreview(LatLng point, {required bool finalize}) {
    _pivotPreviewEdge = point;
    _pivotRadiusMeters = _distanceMeters(_pivotCenter!, point);
    _updateRealTimeIntersection();

    if (finalize && _pivotRadiusMeters! > 0) {
      _pivotRadiusFinalized = true;
      completeDrawing();
      return;
    }

    notifyListeners();
  }

  void beginFreehandStroke(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    if (!_canAcceptSketchInput()) return;
    if (!_ensureDrawingStarted()) return;

    _freehandPoints.clear();
    _freehandStrokeActive = true;
    _freehandPoints.add(point);
    notifyListeners();
  }

  void extendFreehandStroke(LatLng point) {
    if (_isDisposed) return;
    if (_stateMachine.currentTool != DrawingTool.freehand) return;
    if (!_freehandStrokeActive) return;

    _appendPointWithMinDistance(_freehandPoints, point);
    notifyListeners();
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
      notifyListeners();
      return;
    }

    _updateRealTimeIntersection();
    notifyListeners();
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
