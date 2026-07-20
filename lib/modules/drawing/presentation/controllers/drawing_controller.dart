import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_utils.dart';
import '../../domain/drawing_state.dart';
import '../../domain/drawing_history.dart';
import '../../data/repositories/drawing_repository.dart';
// ─── Services puros (Sprint 1 — delegação de lógica de negócio) ───────────────
import '../../domain/services/drawing_feature_crud_service.dart';
import '../../domain/services/drawing_vertex_edit_service.dart';
import '../../domain/services/drawing_boolean_ops_service.dart';
import '../../domain/services/drawing_import_service.dart';
import '../../domain/services/gps_tracking_service.dart';
import '../../infra/file_picker/file_picker_adapter.dart';
import 'drawing_boolean_ops_orchestrator.dart';
import 'drawing_gps_orchestrator.dart';
import 'drawing_import_orchestrator.dart';
// ─────────────────────────────────────────────────────────────────────────────
import '../../../../core/utils/app_logger.dart';

part 'drawing_controller_vertex.dart';
part 'drawing_controller_sketch.dart';

/// Controller de orquestração do módulo Drawing.
///
/// Responsabilidades únicas (após refatoração Sprint 1):
/// - Gerenciar estado de interação (DrawingStateMachine + DrawingInteraction)
/// - Orquestrar chamadas para os services puros
/// - Notificar UI via ChangeNotifier
/// - Persistir via DrawingRepository
///
/// Lógica de negócio DELEGADA para:
/// - DrawingFeatureCrudService   → CRUD e versionamento
/// - DrawingVertexEditService    → edição de vértices
/// - DrawingBooleanOpsService    → operações booleanas
/// - DrawingImportService        → importação KML/KMZ
class DrawingController extends ChangeNotifier {
  /// Ponte para as extensões em `part` files (sketch/vertex):
  /// `notifyListeners` é @protected/@visibleForTesting e o analyzer não
  /// reconhece extensões como "dentro" da classe.
  void _notify() => notifyListeners();

  final DrawingRepository _repository;
  final DrawingStateMachine _stateMachine = DrawingStateMachine();
  late final Future<void> Function(String clienteId, double totalAreaHa)
  _onClientAreaUpdate;

  // Services puros — injectáveis para testes
  final DrawingFeatureCrudService _crudService;
  final DrawingVertexEditService _vertexService;
  final DrawingBooleanOpsService _booleanOpsService;
  final DrawingImportService _importService;
  final GpsTrackingService _gpsTrackingService;
  late final DrawingBooleanOpsOrchestrator _booleanOpsOrchestrator;
  late final DrawingImportOrchestrator _importOrchestrator;
  late final DrawingGpsOrchestrator _gpsOrchestrator;

  DrawingController({
    DrawingRepository? repository,
    DrawingFeatureCrudService? crudService,
    DrawingVertexEditService? vertexService,
    DrawingBooleanOpsService? booleanOpsService,
    DrawingImportService? importService,
    GpsTrackingService? gpsTrackingService,
    Future<void> Function(String clienteId, double totalAreaHa)?
    onClientAreaUpdate,
  }) : _repository = repository ?? DrawingRepository(),
       _crudService = crudService ?? const DrawingFeatureCrudService(),
       _vertexService = vertexService ?? const DrawingVertexEditService(),
       _booleanOpsService =
           booleanOpsService ?? const DrawingBooleanOpsService(),
       _importService =
           importService ?? const DrawingImportService(FilePickerAdapter()),
       _gpsTrackingService = gpsTrackingService ?? const GpsTrackingService() {
    _onClientAreaUpdate =
        onClientAreaUpdate ??
        ((clienteId, totalAreaHa) =>
            _repository.updateClientAreaTotal(clienteId, totalAreaHa));

    _importOrchestrator = DrawingImportOrchestrator(
      importService: _importService,
      setSelectedFeature: (feature) => _selectedFeature = feature,
      setInteractionMode: (interaction) => _interactionMode = interaction,
      setErrorMessage: (message) => _errorMessage = message,
      getPreviewGeometry: () => _previewGeometry,
      setPreviewGeometry: (geometry) => _previewGeometry = geometry,
      validateGeometry: validateGeometry,
      getValidationResult: () => _validationResult,
      finalizeGeometry: _booleanOpsService.finalizeResult,
      startImportPreviewState: _stateMachine.startImportPreview,
      confirmImportState: _stateMachine.confirmImport,
      notifyHost: notifyListeners,
    );

    _booleanOpsOrchestrator = DrawingBooleanOpsOrchestrator(
      booleanOpsService: _booleanOpsService,
      getSelectedFeature: () => _selectedFeature,
      getInteractionMode: () => _interactionMode,
      setInteractionMode: (interaction) => _interactionMode = interaction,
      getPreviewGeometry: () => _previewGeometry,
      setPreviewGeometry: (geometry) => _previewGeometry = geometry,
      setErrorMessage: (message) => _errorMessage = message,
      validateGeometry: validateGeometry,
      getValidationResult: () => _validationResult,
      startBooleanOperationState: _stateMachine.startBooleanOperation,
      selectFeature: selectFeature,
      applyResultToSelectedFeature: (geometry) {
        if (_selectedFeature == null) return;
        updateFeature(
          _selectedFeature!.id,
          newGeometry: geometry,
          editorId: 'sistema',
          editorType: AuthorType.sistema,
        );
      },
      cancelOperation: cancelOperation,
      notifyHost: notifyListeners,
    );

    _gpsOrchestrator = DrawingGpsOrchestrator(
      gpsTrackingService: _gpsTrackingService,
      isDisposed: () => _isDisposed,
      currentState: () => _stateMachine.currentState,
      startGpsTrackingState: _stateMachine.startGpsTracking,
      finalizeGpsTrackingState: _stateMachine.finalizeGpsTracking,
      setErrorMessage: (message) => _errorMessage = message,
      setPreviewGeometry: (geometry) => _previewGeometry = geometry,
      setImportOrigin: _importOrchestrator.setPendingImportOrigin,
      notifyHost: notifyListeners,
    );
    loadFeatures();
  }

  bool _isDisposed = false;

  // ─── Debug Invariant ─────────────────────────────────────────────────────
  /// Verifica que SM state e _interactionMode não estão dessincronizados.
  ///
  /// Apenas chamado via [assert()] — executa somente em modo debug.
  /// Mapeia os pares SM↔interaction que DEVEM ser consistentes:
  ///   • editing          → DrawingInteraction.editing
  ///   • importPreview    → DrawingInteraction.importPreview
  ///   • booleanOperation → unionSelection | differenceSelection | intersectionSelection
  bool _stateVectorsAreConsistent() {
    if (_stateMachine.currentState == DrawingState.editing &&
        _interactionMode != DrawingInteraction.editing) {
      return false;
    }
    if (_stateMachine.currentState == DrawingState.importPreview &&
        _interactionMode != DrawingInteraction.importPreview) {
      return false;
    }
    // 🔧 FIX-AUDIT: booleanOperation exige um dos 3 modos de seleção booleana
    if (_stateMachine.currentState == DrawingState.booleanOperation &&
        _interactionMode != DrawingInteraction.unionSelection &&
        _interactionMode != DrawingInteraction.differenceSelection &&
        _interactionMode != DrawingInteraction.intersectionSelection) {
      return false;
    }
    return true;
  }
  // ─────────────────────────────────────────────────────────────────────────

  /// Vértices GPS aceitos durante rastreamento ativo.
  List<LatLng> get gpsVertices => _gpsOrchestrator.gpsVertices;

  /// Última precisão GPS recebida (metros).
  double get gpsLastAccuracyM => _gpsOrchestrator.gpsLastAccuracyM;

  /// Indica se o rastreamento GPS está pausado.
  bool get gpsIsPaused => _gpsOrchestrator.gpsIsPaused;

  /// Qualidade atual do sinal GPS para o overlay.
  GpsQuality get gpsAccuracyQuality => _gpsOrchestrator.gpsAccuracyQuality;

  @override
  void dispose() {
    if (_isDisposed) return; // 🔧 FIX-DRAW-FLOW-02: Permitir múltiplos dispose
    _isDisposed = true;
    _gpsOrchestrator.dispose();
    _validationDebounce?.cancel();
    _notifyThrottleTimer?.cancel();
    super.dispose();
  }

  Future<void> loadFeatures() async {
    _features = await _repository.getAllFeatures();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Sincroniza features locais com o servidor remoto.
  ///
  /// Trata erros específicos de rede e timeout.
  /// Em caso de conflito, notifica o usuário para resolução manual.
  Future<void> syncFeatures() async {
    if (_isDisposed) return;

    try {
      final result = await _repository.sync();

      if (_isDisposed) return;

      if (result.errors > 0) {
        // Soft error feedback
        _errorMessage =
            "Alguns itens não foram sincronizados. Verifique sua conexão.";
      }

      if (result.conflicts.isNotEmpty) {
        _errorMessage = "Conflito detectado — ação necessária";
      }

      await loadFeatures();
    } on TimeoutException {
      if (_isDisposed) return;
      _errorMessage = "Tempo esgotado. Verifique sua conexão.";
      if (kDebugMode) AppLogger.debug('Sync timeout', tag: 'DrawingController');
      notifyListeners();
    } on SocketException {
      if (_isDisposed) return;
      _errorMessage = "Sem conexão com a internet.";
      if (kDebugMode) {
        AppLogger.debug('No internet connection', tag: 'DrawingController');
      }
      notifyListeners();
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = "Erro na sincronização. Tente novamente.";
      if (kDebugMode) {
        AppLogger.error(
          'Sync error',
          tag: 'DrawingController',
          error: e,
          stackTrace: stackTrace,
        );
      }
      notifyListeners();
    }
  }

  // Persistence state
  List<DrawingFeature> _features = [];

  // Interaction state
  DrawingFeature? _selectedFeature;
  bool _multiSelectEnabled = false;
  final Set<String> _selectedFeatureIds = <String>{};
  DrawingInteraction _interactionMode = DrawingInteraction.normal;
  DrawingGeometry? _previewGeometry; // Result preview
  DrawingGeometry? _reviewGeometrySnapshot;
  double _reviewAreaHa = 0.0;
  double _reviewPerimeterKm = 0.0;
  bool _isDirty = false;
  bool _isSnapping = false; // RT-DRAW-09 Feedback state
  final List<LatLng> _currentPoints = []; // Vértices — ferramenta polígono
  final List<LatLng> _freehandPoints = []; // Trilha — ferramenta mão livre
  bool _freehandStrokeActive = false;
  LatLng? _pivotCenter;
  LatLng? _pivotPreviewEdge;
  bool _pivotRadiusFinalized = false;
  double? _pivotRadiusMeters;

  // Performance State
  bool _isHighComplexity = false;
  Timer? _validationDebounce;
  Timer? _notifyThrottleTimer;
  bool _isDraggingVertex = false; // RT-DRAW-DRAG
  int? _draggedVertexIndex;
  static const int _complexityThreshold = 2000;
  static const int _validationDebounceMs = 300;
  static const int _notifyThrottleMs = 16;

  List<DrawingFeature> get features =>
      List.unmodifiable(_features.where((f) => f.properties.ativo));
  DrawingFeature? get selectedFeature => _selectedFeature;
  bool get isMultiSelectEnabled => _multiSelectEnabled;
  Set<String> get selectedFeatureIds => Set.unmodifiable(_selectedFeatureIds);
  List<DrawingFeature> get selectedFeatures => features
      .where((f) => _selectedFeatureIds.contains(f.id))
      .toList(growable: false);
  bool get hasSelection =>
      _selectedFeature != null ||
      _selectedFeatureIds.isNotEmpty ||
      _multiSelectEnabled ||
      _stateMachine.currentState == DrawingState.selected;
  bool get isHighComplexity => _isHighComplexity;
  List<LatLng> get currentPoints => List.unmodifiable(_currentPoints);

  bool get isDraggingVertex => _isDraggingVertex;
  int? get draggedVertexIndex => _draggedVertexIndex;

  /// ⚡ COMPUTED PROPERTY: Evita cálculo no build()
  int get pendingSyncCount => _features
      .where((f) => f.properties.syncStatus != SyncStatus.synced)
      .length;

  // Legacy getters (deprecated - use currentState)
  DrawingInteraction get interactionMode => _interactionMode;

  /// Origem da importação pendente.
  /// Não-null APENAS quando estamos em [DrawingState.reviewing] vindo de import.
  /// Usado pelo formulário para pré-preencher nome e preservar origem correta.
  DrawingOrigin? get pendingImportOrigin =>
      _stateMachine.currentState == DrawingState.reviewing
      ? _importOrchestrator.pendingImportOrigin
      : null;

  // New state machine getters
  DrawingState get currentState => _stateMachine.currentState;
  DrawingTool get currentTool => _stateMachine.currentTool;
  BooleanOperationType get booleanOperation => _stateMachine.booleanOperation;

  DrawingFeature? get pendingFeatureA =>
      _booleanOpsOrchestrator.pendingFeatureA;
  DrawingFeature? get pendingFeatureB =>
      _booleanOpsOrchestrator.pendingFeatureB;
  DrawingGeometry? get previewGeometry => _previewGeometry;
  String? get intersectionWarningMessage => _intersectionWarningMessage;
  bool get hasPendingImportWarning =>
      _stateMachine.currentState == DrawingState.importPreview &&
      _isImportedOrigin(_importOrchestrator.pendingImportOrigin) &&
      _isImportedWarningMessage(_validationResult.message);
  String? get pendingImportWarningMessage => hasPendingImportWarning
      ? _importWarningMessageFor(_validationResult.message)
      : null;
  double get reviewAreaHa =>
      _stateMachine.currentState == DrawingState.reviewing
      ? _reviewAreaHa
      : liveAreaHa;
  double get reviewPerimeterKm =>
      _stateMachine.currentState == DrawingState.reviewing
      ? _reviewPerimeterKm
      : livePerimeterKm;

  // Retorna a geometria sendo desenhada ou o preview de importação
  DrawingGeometry? get liveGeometry {
    // GPS Tracking — exibe polígono parcial em tempo real
    if (_stateMachine.currentState == DrawingState.gpsTracking &&
        _gpsOrchestrator.gpsVertices.length >= 2) {
      final ring = _gpsOrchestrator.gpsVertices
          .map((p) => <double>[p.longitude, p.latitude])
          .toList();
      // Fecha visualmente o anel para o usuário ver o polígono se formando
      ring.add(List<double>.from(ring.first));
      return DrawingPolygon(coordinates: [ring]);
    }

    final isEditing =
        _interactionMode == DrawingInteraction.editing ||
        _stateMachine.currentState == DrawingState.editing;
    if (isEditing) {
      return _editGeometry;
    }

    final isPreviewing =
        _interactionMode == DrawingInteraction.importPreview ||
        _stateMachine.currentState == DrawingState.importPreview ||
        _stateMachine.currentState == DrawingState.booleanOperation;
    if (isPreviewing) {
      return _previewGeometry;
    }

    if (_stateMachine.currentState == DrawingState.reviewing) {
      if (_previewGeometry != null) return _previewGeometry;
      if (_reviewGeometrySnapshot != null) return _reviewGeometrySnapshot;
    }

    final sketch = buildSketchLiveGeometry();
    if (sketch != null) return sketch;

    return _manualSketch;
  }

  void appendDrawingPoint(LatLng point) {
    switch (currentTool) {
      case DrawingTool.polygon:
      case DrawingTool.rectangle:
      case DrawingTool.circle:
        appendPolygonPoint(point);
      case DrawingTool.pivot:
        handlePivotTap(point);
      case DrawingTool.freehand:
        break;
      default:
        appendPolygonPoint(point);
    }
  }

  // Manual Sketch State
  DrawingGeometry? _manualSketch;

  // Editing State
  DrawingGeometry? _editGeometry;
  String? _editGeometrySnapshotJson;
  final DrawingHistory _history = DrawingHistory();

  // ─── Getters de Undo/Redo (Sprint 2) ──────────────────────────────────
  /// `true` quando há vértices de desenho que podem ser desfeitos.
  bool get canUndo {
    if (_stateMachine.currentState == DrawingState.drawing) {
      switch (_stateMachine.currentTool) {
        case DrawingTool.freehand:
          return _freehandPoints.isNotEmpty;
        case DrawingTool.pivot:
          return _pivotCenter != null;
        case DrawingTool.polygon:
        default:
          return _currentPoints.length > 1;
      }
    }
    return _history.canUndo;
  }

  /// `true` quando há estados futuros que podem ser refeitos (só em editing).
  bool get canRedo => _history.canRedo;
  bool get hasPendingEditChanges {
    if (_editGeometry == null || _editGeometrySnapshotJson == null) {
      return false;
    }
    return _serializeGeometry(_editGeometry!) != _editGeometrySnapshotJson;
  }
  // ──────────────────────────────────────────────────────────────────────

  // Metrics Getters
  /// Retorna a área em hectares da geometria sendo desenhada.
  double get liveAreaHa {
    final g = liveGeometry;
    if (g == null) return 0.0;
    // ⚡ Usar método unificado
    return DrawingUtils.calculateGeometryArea(g);
  }

  double get livePerimeterKm => DrawingUtils.calculatePerimeterKm(liveGeometry);
  List<double> get liveSegmentsKm =>
      DrawingUtils.calculateSegmentsKm(liveGeometry);

  /// Azimute (0-360°) do último segmento útil da geometria em desenho.
  double? get liveAzimuthDegrees {
    List<LatLng> pts = [];
    if (_stateMachine.currentState == DrawingState.gpsTracking &&
        _gpsOrchestrator.gpsVertices.length >= 2) {
      pts = _gpsOrchestrator.gpsVertices;
    } else if (_currentPoints.length >= 2) {
      pts = _currentPoints;
    } else {
      final geom = liveGeometry;
      if (geom is DrawingPolygon &&
          geom.coordinates.isNotEmpty &&
          geom.coordinates.first.length >= 2) {
        pts = geom.coordinates.first
            .take(geom.coordinates.first.length - 1)
            .map((p) => LatLng(p[1], p[0]))
            .toList();
      }
    }
    if (pts.length < 2) return null;
    final a = pts[pts.length - 2];
    final b = pts[pts.length - 1];
    return DrawingUtils.bearingDegrees(a, b);
  }

  // ===========================================================================
  // INTERACTION FLOW
  // ===========================================================================

  /// Returns the text instruction for the tooltip
  String get instructionText {
    if (_errorMessage != null) return "Erro: $_errorMessage";
    if (!_validationResult.isValid) {
      return "⚠️ ${_validationResult.message}"; // Validation Error
    }

    switch (_interactionMode) {
      case DrawingInteraction.importing:
        return "Selecione o formato do arquivo (KML/KMZ)";
      case DrawingInteraction.importPreview:
        return "Confira a área e confirme ou cancele";
      case DrawingInteraction.unionSelection:
        if (pendingFeatureB == null) {
          return "Seleção de União: Toque na segunda área";
        }
        return "Confirme a união das áreas";
      case DrawingInteraction.differenceSelection:
        if (_previewGeometry == null) {
          return "Seleção de Diferença: Toque na área a subtrair";
        }
        return "Confirme a subtração";
      case DrawingInteraction.intersectionSelection:
        if (pendingFeatureB == null) {
          return "Seleção de Interseção: Toque na segunda área";
        }
        return "Confirme a interseção";

      case DrawingInteraction.editing:
        if (_isHighComplexity) {
          return "⚠️ Área complexa — validação simplificada";
        }
        if (_isSnapping) return "⚡ Ponto ajustado (snap)";
        return "Arraste: Mover • Toque na linha: Adicionar • Toque no ponto: Remover";
      case DrawingInteraction.normal:
        // 🔧 FIX-DRAW-FLOW-01: Consultar state machine para armed/drawing
        if (_stateMachine.currentState == DrawingState.armed) {
          return _instructionForActiveTool();
        }
        if (_stateMachine.currentState == DrawingState.drawing ||
            _currentPoints.isNotEmpty ||
            _freehandPoints.isNotEmpty ||
            _pivotCenter != null) {
          return _instructionForActiveTool();
        }
        // Manual Drawing Logic (legacy _manualSketch)
        if (_manualSketch == null) {
          // Idle / Ready to start
          return "Selecione uma ferramenta ou toque no mapa";
        } else {
          // Sketch in progress
          int pointCount = 0;
          if (_manualSketch is DrawingPolygon) {
            final poly = _manualSketch as DrawingPolygon;
            if (poly.coordinates.isNotEmpty) {
              pointCount = poly.coordinates.first.length;
            }
          }

          if (pointCount == 0) {
            return "Toque no mapa para iniciar o desenho";
          }
          if (_isSnapping) return "⚡ Ponto ajustado (snap)";
          if (pointCount < 3) {
            return "Continue tocando para desenhar a área";
          }
          return "Toque para continuar ou no ponto inicial para fechar";
        }
    }
  }

  bool get isDirty => _isDirty;

  // Error State
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    // ⚡ OTIMIZAÇÃO: Só notificar se algo realmente mudou
    if (_errorMessage == null && _validationResult.isValid) {
      return; // Nada mudou, evitar rebuild
    }

    _errorMessage = null;
    _validationResult = const DrawingValidationResult.valid();
    notifyListeners();
  }

  // Validation State
  DrawingValidationResult _validationResult =
      const DrawingValidationResult.valid();
  DrawingValidationResult get validationResult => _validationResult;

  bool _hasSelfIntersection = false;
  bool get hasSelfIntersection => _hasSelfIntersection;
  String? _intersectionWarningMessage;

  Set<int> _intersectingSegmentIndices = {};
  Set<int> get intersectingSegmentIndices => _intersectingSegmentIndices;

  void _updateRealTimeIntersection() {
    DrawingGeometry? geom = liveGeometry;
    if (geom is DrawingPolygon) {
      _intersectingSegmentIndices = DrawingUtils.findSelfIntersectingSegments(
        geom,
      );
      _hasSelfIntersection = _intersectingSegmentIndices.isNotEmpty;
    } else {
      _intersectingSegmentIndices = {};
      _hasSelfIntersection = false;
    }
  }

  void _captureReviewMetrics(DrawingGeometry? geometry) {
    if (geometry == null) {
      _reviewAreaHa = 0.0;
      _reviewPerimeterKm = 0.0;
      return;
    }
    _reviewAreaHa = DrawingUtils.calculateGeometryArea(geometry);
    _reviewPerimeterKm = DrawingUtils.calculatePerimeterKm(geometry);
  }

  bool _isSelfIntersectionMessage(String? message) {
    final text = (message ?? '').toLowerCase();
    return text.contains('auto-interse') ||
        (text.contains('linhas') && text.contains('cruz'));
  }

  bool _isOverlapMessage(String? message) =>
      (message ?? '').toLowerCase().contains('sobreposição');

  bool _isImportedOrigin(DrawingOrigin? origin) =>
      origin == DrawingOrigin.importacao_kml ||
      origin == DrawingOrigin.importacao_kmz;

  bool _isImportedWarningMessage(String? message) =>
      _isSelfIntersectionMessage(message) || _isOverlapMessage(message);

  String _importWarningMessageFor(String? message) {
    if (_isSelfIntersectionMessage(message)) {
      return 'Linhas da geometria importada se cruzam. O arquivo será salvo e poderá ser ajustado depois.';
    }
    if (_isOverlapMessage(message)) {
      return 'A geometria importada sobrepõe uma área existente. O arquivo será salvo e poderá ser ajustado depois.';
    }
    return message ?? 'A geometria importada possui ajustes pendentes.';
  }

  void validateGeometry(DrawingGeometry? g, {bool forceFull = false}) {
    if (g == null) {
      _validationResult = const DrawingValidationResult.valid();
      return;
    }

    // Complexity Check
    final count = DrawingUtils.getVertexCount(g);
    _isHighComplexity = count > _complexityThreshold;

    // Use simplified validation for high complexity unless forced (e.g. on save)
    final skipExpensive = _isHighComplexity && !forceFull;

    final stopwatch = Stopwatch()..start();

    _validationResult = DrawingUtils.validateTopology(
      g,
      existingFeatures: _features,
      ignoreId: _selectedFeature?.id,
      skipExpensiveChecks: skipExpensive,
    );

    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 16) {
      if (kDebugMode) {
        AppLogger.debug(
          'Validation took ${stopwatch.elapsedMilliseconds}ms (Vertices: $count)',
          tag: 'DrawingController',
        );
      }
    }
  }

  /// Adiciona uma nova feature ao mapa após validação.
  ///
  /// Delega construção para [DrawingFeatureCrudService.buildFeature].
  /// Valida topologia antes de persistir.
  Future<DrawingFeature?> addFeature({
    required DrawingGeometry geometry,
    required String nome,
    required DrawingType tipo,
    required DrawingOrigin origem,
    required String autorId,
    required AuthorType autorTipo,
    String? subtipo,
    double? raioMetros,
    String? clienteId,
    String? fazendaId,
    String? grupo,
    int? cor,
  }) async {
    geometry = DrawingUtils.normalizeGeometry(geometry);
    validateGeometry(geometry);
    if (!_validationResult.isValid) {
      if (_isImportedOrigin(origem) &&
          _isImportedWarningMessage(_validationResult.message)) {
        _intersectionWarningMessage = _importWarningMessageFor(
          _validationResult.message,
        );
        _errorMessage = null;
      } else if (_isSelfIntersectionMessage(_validationResult.message)) {
        _intersectionWarningMessage =
            'Linhas se cruzam. Salve e edite os vértices depois.';
      } else {
        _errorMessage = _validationResult.message;
        notifyListeners();
        return null;
      }
    }

    final newFeature = await _crudService.saveFeature(
      geometry: geometry,
      nome: nome,
      tipo: tipo,
      origem: origem,
      autorId: autorId,
      autorTipo: autorTipo,
      persistFeature: _repository.saveFeature,
      getTotalAreaByClienteId: _repository.getTotalAreaByClienteId,
      onClientAreaUpdate: _onClientAreaUpdate,
      subtipo: subtipo,
      raioMetros: raioMetros,
      clienteId: clienteId,
      fazendaId: fazendaId,
      grupo: grupo,
      cor: cor,
    );

    _features.add(newFeature);
    _selectedFeature = newFeature;
    _isDirty = true;
    _stateMachine.confirm();
    _importOrchestrator.clearPendingImportOrigin();
    _intersectionWarningMessage = null;
    _reviewAreaHa = 0.0;
    _reviewPerimeterKm = 0.0;
    _reviewGeometrySnapshot = null;
    _clearSketchState();
    _manualSketch = null;
    _previewGeometry = null;
    _interactionMode = DrawingInteraction.normal;
    notifyListeners();
    return newFeature;
  }

  /// Updates an existing feature (Attributes or Geometry).
  /// Delega para [DrawingFeatureCrudService.buildUpdate].
  /// TRIGGERS VERSIONING if geometry changed.
  void updateFeature(
    String id, {
    String? nome,
    DrawingStatus? status,
    DrawingGeometry? newGeometry,
    String? editorId,
    AuthorType? editorType,
  }) {
    final index = _features.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final oldFeature = _features[index];

    final (:updated, :deactivated) = _crudService.buildUpdate(
      oldFeature,
      nome: nome,
      status: status,
      newGeometry: newGeometry,
      editorId: editorId,
      editorType: editorType,
    );

    if (deactivated != null) {
      _repository.saveFeature(deactivated);
    }

    _features[index] = updated;
    _repository.saveFeature(updated);
    _selectedFeature = updated;
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // SPRINT 6: Atualiza campos agronômicos sem criar nova versão de geometria.
  // ---------------------------------------------------------------------------

  /// Atualiza campos descritivos (nome, cultura, safra, amostragem, nutrientes,
  /// clienteId, fazendaId) sem tocar na geometria — não gera nova versão no
  /// histórico de vértices.
  void updateMetadata(
    String id, {
    String? nome,
    String? cultura,
    String? safra,
    String? soilSamplingScheme,
    Map<String, double>? recByNutrient,
    String? clienteId,
    String? fazendaId,
  }) {
    final index = _features.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final old = _features[index];
    final updated = DrawingFeature(
      id: old.id,
      geometry: old.geometry,
      properties: old.properties.copyWith(
        nome: nome,
        cultura: cultura,
        safra: safra,
        soilSamplingScheme: soilSamplingScheme,
        recByNutrient: recByNutrient,
        clienteId: clienteId,
        fazendaId: fazendaId,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.local_only,
      ),
    );

    _features[index] = updated;
    _selectedFeature = updated;
    _repository.saveFeature(updated);
    _isDirty = true;
    notifyListeners();
  }

  void selectFeature(DrawingFeature? feature) {
    if (_multiSelectEnabled) {
      toggleFeatureSelection(feature);
      return;
    }
    // ⚡ OTIMIZAÇÃO: Só notificar se a seleção mudou
    if (_selectedFeature?.id == feature?.id) {
      return; // Já está selecionado
    }

    if (feature == null) {
      _selectedFeature = null;
      // Se SM estiver em selected, voltar ao idle
      if (_stateMachine.currentState == DrawingState.selected) {
        _stateMachine.exitSelected();
      }
    } else {
      _selectedFeature = _features.firstWhere(
        (f) => f.id == feature.id,
        orElse: () =>
            feature, // Use the provided feature instance if not found in list
      );
      // Transicionar para selected se estiver em idle
      if (_stateMachine.currentState == DrawingState.idle) {
        _stateMachine.startSelected();
      }
    }
    notifyListeners();
  }

  void setMultiSelectEnabled(bool enabled) {
    if (_multiSelectEnabled == enabled) return;
    _multiSelectEnabled = enabled;
    if (!enabled) {
      _selectedFeatureIds.clear();
    } else if (_selectedFeature != null) {
      _selectedFeatureIds.add(_selectedFeature!.id);
    }
    notifyListeners();
  }

  void toggleFeatureSelection(DrawingFeature? feature) {
    if (!_multiSelectEnabled || feature == null) return;
    if (_selectedFeatureIds.contains(feature.id)) {
      _selectedFeatureIds.remove(feature.id);
    } else {
      _selectedFeatureIds.add(feature.id);
    }
    _selectedFeature = _selectedFeatureIds.isEmpty
        ? null
        : features.firstWhere(
            (f) => _selectedFeatureIds.contains(f.id),
            orElse: () => feature,
          );
    notifyListeners();
  }

  void clearMultiSelection() {
    if (_selectedFeatureIds.isEmpty) return;
    _selectedFeatureIds.clear();
    _selectedFeature = null;
    notifyListeners();
  }

  void selectByGroup(String group) {
    final ids = features
        .where((f) => (f.properties.grupo ?? '').trim() == group.trim())
        .map((f) => f.id)
        .toSet();
    _selectedFeatureIds
      ..clear()
      ..addAll(ids);
    _selectedFeature = ids.isEmpty
        ? null
        : features.firstWhere((f) => ids.contains(f.id));
    notifyListeners();
  }

  Future<void> duplicateSelectedFeatures() async {
    final source = selectedFeatures;
    if (source.isEmpty) return;
    final created = <DrawingFeature>[];
    for (final feature in source) {
      final shifted = _translateGeometry(
        feature.geometry,
        deltaLat: 0.00018,
        deltaLng: 0.00018,
      );
      final clone = await _crudService.saveFeature(
        geometry: shifted,
        nome: '${feature.properties.nome} (cópia)',
        tipo: feature.properties.tipo,
        origem: DrawingOrigin.gerado_sistema,
        autorId: feature.properties.autorId,
        autorTipo: feature.properties.autorTipo,
        persistFeature: _repository.saveFeature,
        getTotalAreaByClienteId: _repository.getTotalAreaByClienteId,
        onClientAreaUpdate: _onClientAreaUpdate,
        subtipo: feature.properties.subtipo,
        raioMetros: feature.properties.raioMetros,
        clienteId: feature.properties.clienteId,
        fazendaId: feature.properties.fazendaId,
        grupo: feature.properties.grupo,
        cor: feature.properties.cor,
      );
      _features.add(clone);
      created.add(clone);
    }
    _selectedFeatureIds
      ..clear()
      ..addAll(created.map((e) => e.id));
    _selectedFeature = created.isNotEmpty ? created.first : null;
    _isDirty = true;
    notifyListeners();
  }

  Future<void> moveSelectedFeatures({
    required double deltaLat,
    required double deltaLng,
  }) async {
    if (_selectedFeatureIds.isEmpty) return;
    final canMoveAll = selectedFeatures.every(
      (feature) => _isGeometryWithinWorldBounds(
        _translateGeometry(
          feature.geometry,
          deltaLat: deltaLat,
          deltaLng: deltaLng,
        ),
      ),
    );
    if (!canMoveAll) {
      _errorMessage =
          'Movimento inválido: uma ou mais coordenadas sairiam dos limites do mapa.';
      notifyListeners();
      return;
    }
    final updatedIds = <String>{};
    final affectedClientIds = <String>{};
    for (int i = 0; i < _features.length; i++) {
      final feature = _features[i];
      if (!_selectedFeatureIds.contains(feature.id)) continue;
      final movedGeometry = _translateGeometry(
        feature.geometry,
        deltaLat: deltaLat,
        deltaLng: deltaLng,
      );
      final (:updated, :deactivated) = _crudService.buildUpdate(
        feature,
        newGeometry: movedGeometry,
        editorId: feature.properties.autorId,
        editorType: feature.properties.autorTipo,
      );
      if (deactivated != null) await _repository.saveFeature(deactivated);
      _features[i] = updated;
      updatedIds.add(updated.id);
      await _repository.saveFeature(updated);
      final clientId = feature.properties.clienteId;
      if (clientId != null && clientId.isNotEmpty) {
        affectedClientIds.add(clientId);
      }
    }
    _selectedFeatureIds
      ..clear()
      ..addAll(updatedIds);
    await _refreshClientAreas(affectedClientIds);
    _selectedFeature = updatedIds.isEmpty
        ? null
        : _features.firstWhere((f) => updatedIds.contains(f.id));
    _isDirty = true;
    notifyListeners();
  }

  Future<void> _refreshClientAreas(Iterable<String> clientIds) async {
    for (final clientId in clientIds) {
      final total = await _repository.getTotalAreaByClienteId(clientId);
      await _onClientAreaUpdate(clientId, total);
    }
  }

  bool _isGeometryWithinWorldBounds(DrawingGeometry geometry) {
    Iterable<List<double>> coordinates;
    if (geometry is DrawingPolygon) {
      coordinates = geometry.coordinates.expand((ring) => ring);
    } else if (geometry is DrawingMultiPolygon) {
      coordinates = geometry.coordinates
          .expand((polygon) => polygon)
          .expand((ring) => ring);
    } else {
      return true;
    }
    return coordinates.every(
      (point) =>
          point.length >= 2 &&
          point[0] >= -180 &&
          point[0] <= 180 &&
          point[1] >= -90 &&
          point[1] <= 90,
    );
  }

  void deleteSelectedFeatures() {
    final ids = _selectedFeatureIds.toList(growable: false);
    for (final id in ids) {
      deleteFeature(id);
    }
    _selectedFeatureIds.clear();
    _selectedFeature = null;
    notifyListeners();
  }

  DrawingGeometry _translateGeometry(
    DrawingGeometry geometry, {
    required double deltaLat,
    required double deltaLng,
  }) {
    if (geometry is DrawingPolygon) {
      final coords = geometry.coordinates
          .map(
            (ring) => ring
                .map((p) => <double>[p[0] + deltaLng, p[1] + deltaLat])
                .toList(),
          )
          .toList();
      return DrawingPolygon(coordinates: coords);
    }
    if (geometry is DrawingMultiPolygon) {
      final coords = geometry.coordinates
          .map(
            (poly) => poly
                .map(
                  (ring) => ring
                      .map((p) => <double>[p[0] + deltaLng, p[1] + deltaLat])
                      .toList(),
                )
                .toList(),
          )
          .toList();
      return DrawingMultiPolygon(coordinates: coords);
    }
    return geometry;
  }

  void deleteFeature(String id) {
    final index = _features.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final feature = _features[index];

    // 🔧 FIX-AUDIT: Se já sincronizado, manter na lista como deleted_local
    // para que o sync posterior propague a exclusão ao servidor.
    if (feature.properties.syncStatus == SyncStatus.synced ||
        feature.properties.syncStatus == SyncStatus.pending_sync) {
      _features[index] = DrawingFeature(
        id: feature.id,
        geometry: feature.geometry,
        properties: feature.properties.copyWith(
          ativo: false,
          syncStatus: SyncStatus.local_only,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      _features.removeAt(index);
    }

    _deleteFeatureAndUpdateClientArea(id, feature.properties.clienteId);

    if (_selectedFeature?.id == id) {
      _selectedFeature = null;
    }
    _isDirty = true;
    notifyListeners();
  }

  void _deleteFeatureAndUpdateClientArea(String id, String? clienteId) async {
    await _repository.deleteFeature(id);
    if (clienteId == null || clienteId.isEmpty) return;
    final totalAreaHa = await _repository.getTotalAreaByClienteId(clienteId);
    await _onClientAreaUpdate(clienteId, totalAreaHa);
  }

  /// Restaura uma feature excluída (Undo action)
  void restoreFeature(DrawingFeature feature) {
    if (!_features.any((f) => f.id == feature.id)) {
      _features.add(feature);
      _repository.saveFeature(feature);
      _selectedFeature = feature;
      _isDirty = true;
      notifyListeners();
    }
  }

  // ===========================================================================
  // TOOL SELECTION
  // ===========================================================================

  void selectTool(String toolKey) {
    if (_isDisposed) return;

    DrawingTool tool;
    switch (toolKey) {
      case 'polygon':
        tool = DrawingTool.polygon;
        break;
      case 'freehand':
        tool = DrawingTool.freehand;
        break;
      case 'pivot':
        tool = DrawingTool.pivot;
        break;
      case 'rectangle':
        tool = DrawingTool.rectangle;
        break;
      case 'circle':
        tool = DrawingTool.circle;
        break;
      case 'gps':
        // GPS Tracking é tratado separadamente — não mapeia para DrawingTool
        startGpsTracking();
        return;
      default:
        tool = DrawingTool.none;
    }

    if (kDebugMode) {
      AppLogger.debug(
        'selectTool($toolKey) → $tool | estado: ${_stateMachine.currentState.name}',
        tag: 'DrawingController',
      );
    }

    // 🔧 FIX-AUDIT: Bloquear mudança de ferramenta durante drawing
    // Evita perda de trabalho do usuário sem aviso
    if (_stateMachine.currentState == DrawingState.drawing &&
        tool != DrawingTool.none) {
      if (kDebugMode) {
        AppLogger.debug(
          'selectTool bloqueado durante drawing state.',
          tag: 'DrawingController',
        );
      }
      _errorMessage =
          "Conclua ou cancele o desenho atual antes de trocar de ferramenta";
      notifyListeners();
      return;
    }

    // Sync with state machine
    if (tool != DrawingTool.none) {
      // 🔧 FIX-DRAW-FLOW-01: Resetar estado anterior se necessário
      // Se já estava em armed, permitir trocar ferramenta
      if (_stateMachine.currentState != DrawingState.idle) {
        _stateMachine.reset();
        if (kDebugMode) {
          AppLogger.debug(
            'Estado resetado para idle',
            tag: 'DrawingController',
          );
        }
      }
      _clearSketchState();
      _manualSketch = null;
      _reviewGeometrySnapshot = null;
      _intersectionWarningMessage = null;
      _reviewAreaHa = 0.0;
      _reviewPerimeterKm = 0.0;
      _selectedFeature = null;

      // 🔧 FIX-DRAW-REDSCREEN: startDrawing agora retorna bool, não lança
      final success = _stateMachine.startDrawing(tool);
      if (!success) {
        if (kDebugMode) {
          AppLogger.debug(
            'startDrawing falhou para $tool',
            tag: 'DrawingController',
          );
        }
        _stateMachine.reset();
        _interactionMode = DrawingInteraction.normal;
        notifyListeners();
        return;
      }

      _interactionMode =
          DrawingInteraction.normal; // Ensure mode is normal for drawing

      if (kDebugMode) {
        AppLogger.debug(
          'Estado após startDrawing: ${_stateMachine.currentState.name} | Ferramenta: ${_stateMachine.currentTool.name}',
          tag: 'DrawingController',
        );
      }
    } else {
      _stateMachine.cancel();
      _clearSketchState();
      _manualSketch = null;
      _reviewGeometrySnapshot = null;
      _intersectionWarningMessage = null;
      _reviewAreaHa = 0.0;
      _reviewPerimeterKm = 0.0;

      if (kDebugMode) {
        AppLogger.debug('Modo desenho desativado', tag: 'DrawingController');
      }
    }
    notifyListeners();
  }

  // ===========================================================================
  // BOOLEAN OPERATIONS FLOW (RT-DRAW-07)
  // ===========================================================================

  void cancelOperation({bool notify = true}) {
    exitDrawingContext(notify: notify);
  }

  void clearSelection({bool disableMultiSelect = true}) {
    final hadSelection = hasSelection;
    if (!hadSelection) return;

    _selectedFeature = null;
    _selectedFeatureIds.clear();
    if (disableMultiSelect) {
      _multiSelectEnabled = false;
    }
    if (_stateMachine.currentState == DrawingState.selected) {
      _stateMachine.exitSelected();
    }
    notifyListeners();
  }

  /// Sai completamente do contexto de desenho atual e volta ao estado idle.
  ///
  /// Fonte única de verdade para:
  /// - cancelar operações transitórias
  /// - limpar seleção simples e multi-seleção
  /// - descartar edição temporária e preview
  /// - resetar a state machine para idle
  void exitDrawingContext({bool notify = true}) {
    if (_isDisposed) return;

    _gpsOrchestrator.cancelTracking();
    _gpsOrchestrator.clearReviewOrigin();
    _booleanOpsOrchestrator.clear();
    _importOrchestrator.clearPendingImportOrigin();

    _selectedFeature = null;
    _selectedFeatureIds.clear();
    _multiSelectEnabled = false;
    _editGeometry = null;
    _editGeometrySnapshotJson = null;
    _history.clear();
    _previewGeometry = null;
    _reviewGeometrySnapshot = null;
    _reviewAreaHa = 0.0;
    _reviewPerimeterKm = 0.0;
    _manualSketch = null;
    _clearSketchState();
    _interactionMode = DrawingInteraction.normal;
    _errorMessage = null;
    _intersectionWarningMessage = null;
    _validationResult = const DrawingValidationResult.valid();
    _hasSelfIntersection = false;
    _intersectingSegmentIndices = {};
    _isSnapping = false;
    _isDraggingVertex = false;
    _draggedVertexIndex = null;
    _stateMachine.cancel();
    if (notify) {
      notifyListeners();
    }
  }

  // ===========================================================================
  // GPS TRACKING (Sprint 5)
  // ===========================================================================

  Future<void> startGpsTracking() => _gpsOrchestrator.startGpsTracking();

  void pauseGpsTracking() => _gpsOrchestrator.pauseGpsTracking();

  void resumeGpsTracking() => _gpsOrchestrator.resumeGpsTracking();

  void undoLastGpsVertex() => _gpsOrchestrator.undoLastGpsVertex();

  void finalizeGpsTracking() => _gpsOrchestrator.finalizeGpsTracking();

  void addManualGpsPoint(LatLng point) =>
      _gpsOrchestrator.addManualGpsPoint(point);

  /// Called by the Map Widget to update the current manual drawing sketch
  void updateManualSketch(DrawingGeometry? geometry) {
    if (_interactionMode != DrawingInteraction.normal &&
        _interactionMode != DrawingInteraction.importing) {}

    // 🔧 FIX-DRAW-STATE: Blindagem contra transição inválida idle -> drawing
    // Se o estado estiver idle, significa que a ferramenta não foi selecionada
    // corretamente. Não processar o sketch para evitar transição inválida.
    if (_stateMachine.currentState == DrawingState.idle) {
      if (kDebugMode) {
        AppLogger.debug(
          'updateManualSketch ignorado em estado idle.',
          tag: 'DrawingController',
        );
      }
      return;
    }

    _manualSketch = geometry;

    // Detect state transition from ARMED to DRAWING
    if (_manualSketch != null &&
        _stateMachine.currentState == DrawingState.armed) {
      // 🔧 FIX-DRAW-REDSCREEN: Usar retorno booleano em vez de try-catch
      final success = _stateMachine.beginAddingPoints();
      if (!success && kDebugMode) {
        AppLogger.debug(
          'DRAW-ERROR: Falha ao transicionar armed -> drawing',
          tag: 'DrawingController',
        );
      }
    }

    // If sketch is cleared, go back to armed if we were drawing
    if (_manualSketch == null &&
        _stateMachine.currentState == DrawingState.drawing) {
      // Optionally handle cancel here or wait for user action
    }

    // Snap logic for manual sketch
    // Reset snap state
    _isSnapping = false;

    if (_manualSketch is DrawingPolygon) {
      final poly = _manualSketch as DrawingPolygon;
      final snappedCoords = poly.coordinates.map((ring) {
        return ring.map((p) => _snapIfClose(p)).toList();
      }).toList();
      _manualSketch = DrawingPolygon(coordinates: snappedCoords);
    }

    validateGeometry(_manualSketch);
    // We notify listeners so the UI updates metrics
    notifyListeners();
  }

  // ===========================================================================
  // EDITING FLOW (RT-DRAW-06)
  // ===========================================================================

  void startEditMode() {
    if (_selectedFeature == null) return;

    // Delega deep copy ao DrawingVertexEditService
    _editGeometry = _vertexService.cloneGeometry(_selectedFeature!.geometry);
    _editGeometrySnapshotJson = _serializeGeometry(_editGeometry!);
    _history.clear();
    _history.push(_geomToVertices(_editGeometry!));

    // 🔧 FASE1-FIX-01: Garantir que os dois vetores só avançam juntos.
    // Se a SM rejeitar a transição, não setar interactionMode.
    final ok = _stateMachine.startEditing();
    if (!ok) {
      if (kDebugMode) {
        AppLogger.debug(
          'startEditMode: SM rejeitou startEditing() — interactionMode não alterado',
          tag: 'DrawingController',
        );
      }
      return;
    }
    _interactionMode = DrawingInteraction.editing;
    assert(
      _stateVectorsAreConsistent(),
      'DrawingController.startEditMode: vetores de estado dessincronizados — '
      'SM=\${_stateMachine.currentState.name} interaction=\${_interactionMode.name}',
    );
    notifyListeners();
  }

  void cancelEdit() {
    _editGeometry = null;
    _editGeometrySnapshotJson = null;
    _history.clear();
    _interactionMode = DrawingInteraction.normal;
    // 🔧 FASE3: Se feature ainda selecionada, volta para selected em vez de idle
    if (_selectedFeature != null) {
      _stateMachine.tryTransitionTo(DrawingState.selected);
    } else {
      _stateMachine.cancel();
    }
    assert(
      _stateVectorsAreConsistent(),
      'DrawingController.cancelEdit: vetores de estado dessincronizados — '
      'SM=\${_stateMachine.currentState.name} interaction=\${_interactionMode.name}',
    );
    notifyListeners();
  }

  bool saveEdit() {
    // Force FULL validation on save
    if (_editGeometry != null) {
      validateGeometry(_editGeometry, forceFull: true);
      if (!_validationResult.isValid) {
        if (_isSelfIntersectionMessage(_validationResult.message)) {
          _intersectionWarningMessage =
              'Linhas se cruzam. Salve e ajuste os vértices depois.';
        } else {
          _errorMessage = _validationResult.message;
          notifyListeners();
          return false;
        }
      }
    }

    if (_selectedFeature != null && _editGeometry != null) {
      updateFeature(
        _selectedFeature!.id,
        newGeometry: _editGeometry,
        editorId: "sistema", // Placeholder, usually would be current user
        editorType: AuthorType.sistema,
      );
    }
    cancelEdit();
    return true;
  }

  void undoEdit() {
    final prev = _history.undo();
    if (prev != null) {
      _editGeometry = _verticesToGeom(prev, _editGeometry);
      notifyListeners();
    }
  }

  /// Refaz a última operação desfeita no modo de edição de vértices.
  void redoEdit() {
    final next = _history.redo();
    if (next != null) {
      _editGeometry = _verticesToGeom(next, _editGeometry);
      notifyListeners();
    }
  }

  /// Desfaz o último vértice adicionado no modo de desenho livre.
  void undoDrawingPoint() {
    if (_isDisposed) return;

    switch (_stateMachine.currentTool) {
      case DrawingTool.freehand:
        if (_freehandPoints.isEmpty) return;
        _freehandPoints.clear();
        _freehandStrokeActive = false;
      case DrawingTool.pivot:
        if (_pivotPreviewEdge != null) {
          _pivotPreviewEdge = null;
          _pivotRadiusMeters = null;
          _pivotRadiusFinalized = false;
        } else if (_pivotCenter != null) {
          _pivotCenter = null;
        } else {
          return;
        }
      case DrawingTool.polygon:
      default:
        if (_currentPoints.isEmpty) return;
        _currentPoints.removeLast();
    }

    final hasSketch = _currentPoints.isNotEmpty ||
        _freehandPoints.isNotEmpty ||
        _pivotCenter != null;
    if (!hasSketch && _stateMachine.currentState == DrawingState.drawing) {
      final didRevert = _stateMachine.tryTransitionTo(DrawingState.armed);
      if (!didRevert && kDebugMode) {
        AppLogger.debug(
          'undoDrawingPoint: falha ao regredir drawing → armed',
          tag: 'DrawingController',
        );
      }
    }
    notifyListeners();
  }

  // ─── Helpers de conversão geometria ↔ vértices ────────────────────────────────
  List<LatLng> _geomToVertices(DrawingGeometry geom) {
    if (geom is DrawingPolygon && geom.coordinates.isNotEmpty) {
      return geom.coordinates.first.map((p) => LatLng(p[1], p[0])).toList();
    }
    return [];
  }

  DrawingGeometry _verticesToGeom(
    List<LatLng> vertices,
    DrawingGeometry? reference,
  ) {
    final ring = vertices
        .map((p) => <double>[p.longitude, p.latitude])
        .toList();
    // Se o último ponto não fecha o anel, fechar
    if (ring.isNotEmpty) {
      final first = ring.first;
      final last = ring.last;
      if ((first[0] - last[0]).abs() > 1e-9 ||
          (first[1] - last[1]).abs() > 1e-9) {
        ring.add(List<double>.from(first));
      }
    }
    return DrawingPolygon(coordinates: [ring]);
  }

  /// Attempts to find a feature at the given coordinate.
  DrawingFeature? findFeatureAt(LatLng point) {
    // Iterate in reverse to pick top-most feature
    for (var i = _features.length - 1; i >= 0; i--) {
      final f = _features[i];
      if (!f.properties.ativo) continue;

      if (f.geometry is DrawingPolygon) {
        final poly = f.geometry as DrawingPolygon;
        if (poly.coordinates.isEmpty) continue;

        // Check outer ring
        if (DrawingUtils.isPointInPolygon(point, poly.coordinates.first)) {
          // Check holes
          bool inHole = false;
          if (poly.coordinates.length > 1) {
            for (var j = 1; j < poly.coordinates.length; j++) {
              if (DrawingUtils.isPointInPolygon(point, poly.coordinates[j])) {
                inHole = true;
                break;
              }
            }
          }
          if (!inHole) return f;
        }
      }
    }
    return null;
  }

  // ===========================================================================
  // GRUPOS
  // No futuro, isso viria de um repository dedicado
  final List<String> _groups = [
    'Soja 2025/26',
    'Milho 2024',
    'Algodão Safra 1',
  ];
  List<String> get groups => List.unmodifiable(_groups);

  void createGroup(String name) {
    if (!_groups.contains(name)) {
      _groups.add(name);
      notifyListeners();
    }
  }

  // ===========================================================================
  // DRAWING FLOW
  // ===========================================================================

  /// Completa o desenho manual e entra em modo de revisão
  void completeDrawing() {
    final geometrySnapshot = liveGeometry;
    if (_stateMachine.currentState == DrawingState.drawing) {
      final success = _stateMachine.completeDrawing();
      if (success) {
        _reviewGeometrySnapshot = geometrySnapshot;
        _captureReviewMetrics(geometrySnapshot);
        // 🔧 FIX-AUDIT: Usar liveGeometry (fonte real dos pontos) em vez de _manualSketch
        validateGeometry(liveGeometry);
        if (_hasSelfIntersection ||
            _isSelfIntersectionMessage(_validationResult.message)) {
          _intersectionWarningMessage =
              'Linhas se cruzam. Salve e edite os vértices depois.';
          _errorMessage = null;
        } else {
          _intersectionWarningMessage = null;
        }
        notifyListeners();
      }
    }
  }

  /// Atualiza propriedades específicas de uma feature
  void updateFeatureProperties(String id, {String? grupo, int? cor}) {
    final index = _features.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final feature = _features[index];
    final updatedProperties = feature.properties.copyWith(
      grupo: grupo,
      cor: cor,
      updatedAt: DateTime.now(),
    );

    final updatedFeature = DrawingFeature(
      id: feature.id,
      geometry: feature.geometry,
      properties: updatedProperties,
    );

    _features[index] = updatedFeature;

    if (_selectedFeature?.id == id) {
      _selectedFeature = updatedFeature;
    }

    notifyListeners();
  }

  // ===========================================================================
  // IMPORT FLOW
  // ===========================================================================

  void startImportMode() {
    _importOrchestrator.startImportMode();
  }

  Future<void> pickImportFile() => _importOrchestrator.pickImportFile();

  // ===========================================================================
  // BOOLEAN OPERATIONS FLOW (RT-DRAW-07)
  // ===========================================================================

  void startUnionMode() => _booleanOpsOrchestrator.startUnionMode();

  void startDifferenceMode() => _booleanOpsOrchestrator.startDifferenceMode();

  void startIntersectionMode() =>
      _booleanOpsOrchestrator.startIntersectionMode();

  void onFeatureTapped(DrawingFeature feature) =>
      _booleanOpsOrchestrator.onFeatureTapped(feature);

  void confirmBooleanOp() => _booleanOpsOrchestrator.confirmBooleanOp();

  void confirmImport() {
    _importOrchestrator.confirmImport();
    if (_stateMachine.currentState == DrawingState.reviewing) {
      _captureReviewMetrics(liveGeometry);
      if (_isImportedOrigin(pendingImportOrigin) &&
          _isImportedWarningMessage(_validationResult.message)) {
        _intersectionWarningMessage = _importWarningMessageFor(
          _validationResult.message,
        );
      } else if (_isSelfIntersectionMessage(_validationResult.message)) {
        _intersectionWarningMessage =
            'Linhas se cruzam. Salve e edite os vértices depois.';
      } else {
        _intersectionWarningMessage = null;
      }
    }
  }

  void confirmImportForced() {
    confirmImport();
  }

  // Helper for snapping
  List<double> _snapIfClose(List<double> p) {
    final latlng = LatLng(p[1], p[0]);
    // Snap to OTHER features (exclude selected if editing)
    final others = _features
        .where((f) => f.id != _selectedFeature?.id)
        .toList();
    final snapped = DrawingUtils.snapPoint(latlng, others);

    if (snapped != latlng) {
      _isSnapping = true;
    }

    return [snapped.longitude, snapped.latitude];
  }

  String _serializeGeometry(DrawingGeometry geometry) {
    final normalized = DrawingUtils.normalizeGeometry(
      _vertexService.cloneGeometry(geometry),
    );
    return jsonEncode(normalized.toJson());
  }
}
