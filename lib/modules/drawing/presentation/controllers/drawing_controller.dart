import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_utils.dart';
import '../../domain/drawing_state.dart';
import '../../data/repositories/drawing_repository.dart';

/// Controller for the Drawing Mode state.
/// This manages the current list of features (active drawings) and the current interaction state.
class DrawingController extends ChangeNotifier {
  final DrawingRepository _repository;
  final DrawingStateMachine _stateMachine = DrawingStateMachine();

  DrawingController({DrawingRepository? repository})
    : _repository = repository ?? DrawingRepository() {
    loadFeatures();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) return; // 🔧 FIX-DRAW-FLOW-02: Permitir múltiplos dispose
    _isDisposed = true;
    _validationDebounce?.cancel();
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
      if (kDebugMode) debugPrint('Sync timeout');
      notifyListeners();
    } on SocketException {
      if (_isDisposed) return;
      _errorMessage = "Sem conexão com a internet.";
      if (kDebugMode) debugPrint('No internet connection');
      notifyListeners();
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = "Erro na sincronização. Tente novamente.";
      if (kDebugMode) {
        debugPrint('Sync error: $e');
        debugPrint('Stack: $stackTrace');
      }
      notifyListeners();
    }
  }

  // Persistence state
  List<DrawingFeature> _features = [];

  // Interaction state
  DrawingFeature? _selectedFeature;
  DrawingInteraction _interactionMode = DrawingInteraction.normal;
  DrawingFeature? _pendingFeatureA; // Primary feature for ops
  DrawingFeature? _pendingFeatureB; // Secondary feature for union
  DrawingGeometry? _previewGeometry; // Result preview
  bool _isDirty = false;
  bool _isSnapping = false; // RT-DRAW-09 Feedback state
  final List<LatLng> _currentPoints = []; // Pontos do desenho atual

  // Performance State
  bool _isHighComplexity = false;
  Timer? _validationDebounce;
  static const int _complexityThreshold = 2000;
  static const int _validationDebounceMs = 300;

  List<DrawingFeature> get features => List.unmodifiable(_features);
  DrawingFeature? get selectedFeature => _selectedFeature;
  bool get isHighComplexity => _isHighComplexity;

  /// ⚡ COMPUTED PROPERTY: Evita cálculo no build()
  int get pendingSyncCount => _features
      .where((f) => f.properties.syncStatus != SyncStatus.synced)
      .length;

  // Legacy getters (deprecated - use currentState)
  DrawingInteraction get interactionMode => _interactionMode;

  // New state machine getters
  DrawingState get currentState => _stateMachine.currentState;
  DrawingTool get currentTool => _stateMachine.currentTool;
  BooleanOperationType get booleanOperation => _stateMachine.booleanOperation;

  DrawingFeature? get pendingFeatureA => _pendingFeatureA;
  DrawingFeature? get pendingFeatureB => _pendingFeatureB;
  DrawingGeometry? get previewGeometry => _previewGeometry;

  // Retorna a geometria sendo desenhada ou o preview de importação
  DrawingGeometry? get liveGeometry {
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

    if (_currentPoints.isNotEmpty) {
      if (_currentPoints.length < 2) return null;
      final ring = _currentPoints
          .map((p) => [p.longitude, p.latitude])
          .toList();

      final isPolygonTool =
          currentTool == DrawingTool.polygon ||
          currentTool == DrawingTool.freehand;
      if (isPolygonTool && ring.length > 2) {
        final first = ring.first;
        final last = ring.last;
        final needsClosure =
            (first[0] - last[0]).abs() > 1e-9 ||
            (first[1] - last[1]).abs() > 1e-9;
        if (needsClosure) {
          ring.add(first);
        }
        return DrawingPolygon(coordinates: [ring]);
      }
      return DrawingPolygon(coordinates: [ring]);
    }

    return _manualSketch;
  }

  void appendDrawingPoint(LatLng point) {
    if (_isDisposed) return;
    
    if (currentState != DrawingState.armed &&
        currentState != DrawingState.drawing) {
      return;
    }

    if (currentState == DrawingState.armed) {
      _stateMachine.beginAddingPoints();
    }

    _currentPoints.add(point);
    notifyListeners();
  }

  // Helper to map legacy DrawingInteraction to new DrawingState
  DrawingState _mapInteractionToState(DrawingInteraction interaction) {
    switch (interaction) {
      case DrawingInteraction.normal:
        return DrawingState.idle;
      case DrawingInteraction.importing:
        return DrawingState.armed; // Importing is like selecting import tool
      case DrawingInteraction.importPreview:
        return DrawingState.importPreview;
      case DrawingInteraction.editing:
        return DrawingState.editing;
      case DrawingInteraction.unionSelection:
      case DrawingInteraction.differenceSelection:
      case DrawingInteraction.intersectionSelection:
        return DrawingState.booleanOperation;
    }
  }

  // Helper to sync state machine with legacy _interactionMode
  void _syncStateMachine() {
    final targetState = _mapInteractionToState(_interactionMode);
    if (_stateMachine.currentState != targetState) {
      try {
        _stateMachine.transitionTo(targetState);
      } catch (e) {
        // Transition not allowed - reset to idle
        if (kDebugMode) {
          debugPrint(
            'State transition failed: ${_stateMachine.currentState} -> $targetState',
          );
        }
        _stateMachine.reset();
        _interactionMode = DrawingInteraction.normal;
      }
    }
  }

  // Manual Sketch State
  DrawingGeometry? _manualSketch;

  // Editing State
  DrawingGeometry? _editGeometry;
  final List<DrawingGeometry> _undoStack = [];

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
        if (_pendingFeatureB == null) {
          return "Seleção de União: Toque na segunda área";
        }
        return "Confirme a união das áreas";
      case DrawingInteraction.differenceSelection:
        if (_previewGeometry == null) {
          return "Seleção de Diferença: Toque na área a subtrair";
        }
        return "Confirme a subtração";
      case DrawingInteraction.intersectionSelection:
        if (_pendingFeatureB == null) {
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
          return "Toque no mapa para iniciar o desenho";
        }
        if (_stateMachine.currentState == DrawingState.drawing ||
            _currentPoints.isNotEmpty) {
          final pointCount = _currentPoints.length;
          if (pointCount == 0) {
            return "Toque no mapa para iniciar o desenho";
          }
          if (_isSnapping) return "⚡ Ponto ajustado (snap)";
          if (pointCount < 3) {
            return "Continue tocando para desenhar a área";
          }
          return "Toque para continuar ou no ponto inicial para fechar";
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

  // Import State
  DrawingOrigin? _currentImportOrigin;
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
        debugPrint(
          "Validation took ${stopwatch.elapsedMilliseconds}ms (Vertices: $count)",
        );
      }
    }
  }

  /// Adiciona uma nova feature ao mapa após validação.
  ///
  /// Valida a geometria antes de adicionar. Se inválida, define [_errorMessage]
  /// e retorna sem adicionar.
  ///
  /// Calcula automaticamente a área em hectares e cria um novo [DrawingFeature]
  /// com status 'rascunho' e sync_status 'local_only'.
  ///
  /// Parâmetros:
  /// - [geometry]: Geometria a ser adicionada (Polygon ou MultiPolygon)
  /// - [nome]: Nome descritivo da área
  /// - [tipo]: Tipo de desenho (talhao, zona_manejo, etc)
  /// - [origem]: Origem do desenho (manual, importação, sistema)
  /// - [autorId]: ID do usuário que criou
  /// - [autorTipo]: Tipo do autor (consultor, cliente, sistema)
  /// - [subtipo]: Subtipo opcional (ex: 'pivo' para pivôs)
  /// - [raioMetros]: Raio em metros (para pivôs circulares)
  /// - [clienteId]: ID do cliente associado
  /// - [fazendaId]: ID da fazenda associada
  void addFeature({
    required DrawingGeometry geometry,
    required String nome,
    required DrawingType tipo,
    required DrawingOrigin origem,
    required String autorId,
    required AuthorType autorTipo,
    String? subtipo,
    double? raioMetros,
    String? clienteId, // 🆕 NOVO PARÂMETRO
    String? fazendaId,
  }) {
    // Validate before adding
    geometry = DrawingUtils.normalizeGeometry(geometry);
    validateGeometry(geometry);
    if (!_validationResult.isValid) {
      _errorMessage = _validationResult.message;
      notifyListeners();
      return;
    }

    // ⚡ Usar método unificado para calcular área
    final areaHa = DrawingUtils.calculateGeometryArea(geometry);

    final newFeature = DrawingFeature(
      id: DrawingUtils.generateId(),
      geometry: geometry,
      properties: DrawingProperties(
        nome: nome,
        tipo: tipo,
        origem: origem,
        status: DrawingStatus.rascunho,
        autorId: autorId,
        autorTipo: autorTipo,
        clienteId: clienteId, // 🆕 NOVO CAMPO
        fazendaId: fazendaId, // 🆕 NOVO CAMPO
        areaHa: areaHa,
        versao: 1,
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subtipo: subtipo,
        raioMetros: raioMetros,
        syncStatus: SyncStatus.local_only,
      ),
    );

    _features.add(newFeature);
    _repository.saveFeature(newFeature); // Persist
    _selectedFeature = newFeature;
    _isDirty = true;
    _stateMachine.confirm(); // State machine reset
    _interactionMode = DrawingInteraction.normal;
    notifyListeners();
  }

  /// Updates an existing feature (Attributes or Geometry).
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
    DrawingFeature updatedFeature;

    // If geometry changes, we MUST version.
    if (newGeometry != null && editorId != null && editorType != null) {
      // 1. Calculate new area
      // ⚡ Usar método unificado
      final newArea = DrawingUtils.calculateGeometryArea(newGeometry);

      // 2. Create V+1
      updatedFeature = oldFeature.createNewVersion(
        newId: DrawingUtils.generateId(),
        newName: nome ?? oldFeature.properties.nome,
        newGeometry: newGeometry,
        newAreaHa: newArea,
        authorId: editorId,
        authorType: editorType,
      );

      // Deactivate old
      final deactivatedOld = DrawingFeature(
        id: oldFeature.id,
        geometry: oldFeature.geometry,
        properties: oldFeature.properties.copyWith(ativo: false),
      );
      _repository.saveFeature(deactivatedOld);
    } else {
      // Attribute only update (in place update, same ID)
      updatedFeature = DrawingFeature(
        id: oldFeature.id,
        geometry: oldFeature.geometry,
        properties: oldFeature.properties.copyWith(
          nome: nome,
          status: status,
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending_sync, // Mark for sync
        ),
      );
    }

    // Update local list (Replace old with new)
    _features[index] = updatedFeature;
    _repository.saveFeature(updatedFeature); // Persist new/updated

    _selectedFeature = updatedFeature;
    _isDirty = true;
    notifyListeners();
  }

  void selectFeature(DrawingFeature? feature) {
    // ⚡ OTIMIZAÇÃO: Só notificar se a seleção mudou
    if (_selectedFeature?.id == feature?.id) {
      return; // Já está selecionado
    }

    if (feature == null) {
      _selectedFeature = null;
    } else {
      _selectedFeature = _features.firstWhere(
        (f) => f.id == feature.id,
        orElse: () => _features.first,
      );
    }
    notifyListeners();
  }

  void deleteFeature(String id) {
    _features.removeWhere((f) => f.id == id);
    _repository.deleteFeature(id); // Persist deletion

    if (_selectedFeature?.id == id) {
      _selectedFeature = null;
    }
    _isDirty = true;
    notifyListeners();
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
      default:
        tool = DrawingTool.none;
    }

    // Sync with state machine
    try {
      if (tool != DrawingTool.none) {
        // 🔧 FIX-DRAW-FLOW-01: Resetar estado anterior se necessário
        // Se já estava em armed/drawing, voltar para idle antes de re-armar
        if (_stateMachine.currentState != DrawingState.idle) {
          _stateMachine.reset();
        }
        // Limpar pontos de desenho anterior
        _currentPoints.clear();
        _manualSketch = null;
        _selectedFeature = null;

        _stateMachine.startDrawing(tool);
        _interactionMode =
            DrawingInteraction.normal; // Ensure mode is normal for drawing
      } else {
        _stateMachine.cancel();
        _currentPoints.clear();
        _manualSketch = null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Tool selection failed: $e');
    }
    notifyListeners();
  }

  // ===========================================================================
  // BOOLEAN OPERATIONS FLOW (RT-DRAW-07)
  // ===========================================================================

  void cancelOperation() {
    if (_isDisposed) return;
    
    _interactionMode = DrawingInteraction.normal;
    _pendingFeatureA = null;
    _pendingFeatureB = null;
    _previewGeometry = null;
    _manualSketch = null;
    _currentImportOrigin = null;
    _errorMessage = null;
    _currentPoints.clear(); // 🔧 FIX-DRAW-FLOW-02: Limpar pontos ao cancelar
    _stateMachine.cancel(); // Use state machine cancel
    _syncStateMachine();
    notifyListeners();
  }

  /// Called by the Map Widget to update the current manual drawing sketch
  void updateManualSketch(DrawingGeometry? geometry) {
    if (_interactionMode != DrawingInteraction.normal &&
        _interactionMode != DrawingInteraction.importing) {}

    _manualSketch = geometry;

    // Detect state transition from ARMED to DRAWING
    if (_manualSketch != null &&
        _stateMachine.currentState == DrawingState.armed) {
      try {
        _stateMachine.beginAddingPoints();
      } catch (e) {
        // Already drawing or invalid
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

    // Create working copy
    _editGeometry = _cloneGeometry(_selectedFeature!.geometry);
    _undoStack.clear();
    // Push initial state
    _undoStack.add(_cloneGeometry(_editGeometry!));

    _interactionMode = DrawingInteraction.editing;
    _syncStateMachine();
    notifyListeners();
  }

  void cancelEdit() {
    _editGeometry = null;
    _undoStack.clear();
    // Revert to selected state (normal or selected)
    // Actually keep selection but exit edit mode
    _interactionMode = DrawingInteraction.normal;
    _syncStateMachine();
    notifyListeners();
  }

  void saveEdit() {
    // Force FULL validation on save
    if (_editGeometry != null) {
      validateGeometry(_editGeometry, forceFull: true);
      if (!_validationResult.isValid) {
        _errorMessage = _validationResult.message;
        notifyListeners();
        return;
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
  }

  void undoEdit() {
    if (_undoStack.length > 1) {
      _undoStack.removeLast(); // Remove current tip
      _editGeometry = _cloneGeometry(_undoStack.last);
      notifyListeners();
    }
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

  /// Called by Map when a user drags a vertex.
  /// [geometry] is the generic updated geometry from the map helper.
  void updateEditGeometry(DrawingGeometry geometry) {
    if (_interactionMode != DrawingInteraction.editing) return;

    // Reset snap for this frame
    _isSnapping = false;

    // Check complexity before snapping
    final count = DrawingUtils.getVertexCount(geometry);
    final isComplex = count > _complexityThreshold;

    DrawingGeometry processingGeo = geometry;

    // Only snap if not complex
    if (!isComplex) {
      if (geometry is DrawingPolygon) {
        final snappedCoords = geometry.coordinates.map((ring) {
          return ring.map((p) => _snapIfClose(p)).toList();
        }).toList();
        processingGeo = DrawingPolygon(coordinates: snappedCoords);
      }
    }

    _editGeometry = processingGeo;

    // Throttle validation
    if (isComplex) {
      // Debounce full validation
      _validationDebounce?.cancel();
      _validationDebounce = Timer(
        const Duration(milliseconds: _validationDebounceMs),
        () {
          if (_isDisposed) return; // 🔧 FIX: Evitar chamada após dispose
          validateGeometry(
            _editGeometry,
            forceFull: false,
          ); // Still allow skip if really huge, but run basic checks
          notifyListeners();
        },
      );
      // Immediate: Just checks valid structure (min points), skips topology
      validateGeometry(_editGeometry, forceFull: false);
    } else {
      validateGeometry(_editGeometry);
    }

    notifyListeners();
  }

  /// Call BEFORE a distinct modification action (like drag end, add point, remove point)
  void snapshotEdit() {
    if (_editGeometry != null) {
      _undoStack.add(_cloneGeometry(_editGeometry!));
      if (_undoStack.length > 20) {
        _undoStack.removeAt(0);
      }
    }
  }

  void addVertex(int ringIndex, int segmentIndex, LatLng point) {
    if (_editGeometry == null) return;
    snapshotEdit(); // Save state before change

    // Logic to insert point
    if (_editGeometry is DrawingPolygon) {
      final poly = _editGeometry as DrawingPolygon;
      if (ringIndex < poly.coordinates.length) {
        final ring = poly.coordinates[ringIndex];
        // Insert at segmentIndex + 1 (after the start of segment)
        // Segment i is p[i] -> p[i+1]. We want to insert between.
        if (segmentIndex >= 0 && segmentIndex < ring.length - 1) {
          ring.insert(segmentIndex + 1, [point.longitude, point.latitude]);
        }
      }
    }
    notifyListeners();
  }

  void removeVertex(int ringIndex, int pointIndex) {
    if (_editGeometry == null) return;

    // Check min points
    int count = 0;
    if (_editGeometry is DrawingPolygon) {
      final poly = _editGeometry as DrawingPolygon;
      if (ringIndex < poly.coordinates.length) {
        count = poly.coordinates[ringIndex].length;
      }
    }

    // Polygon must be closed (first=last). Min valid points is 4 (triangle closed).
    if (count <= 4) {
      _errorMessage = "A área precisa ter pelo menos 3 pontos (triângulo).";
      notifyListeners();
      return;
    }

    snapshotEdit();

    if (_editGeometry is DrawingPolygon) {
      final poly = _editGeometry as DrawingPolygon;
      final ring = poly.coordinates[ringIndex];

      ring.removeAt(pointIndex);

      // Re-close if needed
      if (pointIndex == 0) {
        if (ring.isNotEmpty) {
          ring.last = [ring.first[0], ring.first[1]];
        }
      }

      // Ensure closed
      if (ring.isNotEmpty &&
          (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
        ring.add([ring.first[0], ring.first[1]]);
      }
    }
    notifyListeners();
  }

  DrawingGeometry _cloneGeometry(DrawingGeometry g) {
    if (g is DrawingPolygon) {
      return DrawingPolygon(
        coordinates: g.coordinates
            .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
            .toList(),
      );
    } else if (g is DrawingMultiPolygon) {
      return DrawingMultiPolygon(
        coordinates: g.coordinates
            .map(
              (polygon) => polygon
                  .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
                  .toList(),
            )
            .toList(),
      );
    }
    return g;
  }

  // ===========================================================================
  // IMPORT FLOW
  // ===========================================================================

  void startImportMode() {
    // Reset selection if any
    _selectedFeature = null;
    _interactionMode = DrawingInteraction.importing;
    _errorMessage = null;
    _syncStateMachine();
    notifyListeners();
  }

  Future<void> pickImportFile(bool isKmz) async {
    _errorMessage = null;
    try {
      final type = isKmz ? 'kmz' : 'kml';
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [type],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final geometry = await DrawingUtils.parseFile(file);

        if (geometry != null) {
          // Simplify on import
          var processed = DrawingUtils.simplifyGeometry(geometry);
          processed = DrawingUtils.normalizeGeometry(processed);

          _previewGeometry = processed;
          validateGeometry(_previewGeometry);
          _interactionMode = DrawingInteraction.importPreview;
          _currentImportOrigin = isKmz
              ? DrawingOrigin.importacao_kmz
              : DrawingOrigin.importacao_kml;
          _syncStateMachine();
        } else {
          _interactionMode = DrawingInteraction.normal;
          _errorMessage = "O arquivo não contém geometria válida (Polygon).";
        }
      } else {
        // User cancelled
        _interactionMode = DrawingInteraction.normal;
      }
    } catch (e) {
      _interactionMode = DrawingInteraction.normal;
      _errorMessage = "Erro ao ler arquivo: $e";
    }
    notifyListeners();
  }

  // ===========================================================================
  // BOOLEAN OPERATIONS FLOW (RT-DRAW-07)
  // ===========================================================================

  void startUnionMode() {
    if (_selectedFeature == null) return;
    _pendingFeatureA = _selectedFeature;
    _pendingFeatureB = null;
    _previewGeometry = null;
    _interactionMode = DrawingInteraction.unionSelection;
    _stateMachine.startBooleanOperation(BooleanOperationType.union);
    notifyListeners();
  }

  void startDifferenceMode() {
    if (_selectedFeature == null) return;
    _pendingFeatureA = _selectedFeature;
    _pendingFeatureB = null;
    _previewGeometry = null;
    _interactionMode = DrawingInteraction.differenceSelection;
    _stateMachine.startBooleanOperation(BooleanOperationType.difference);
    notifyListeners();
  }

  void startIntersectionMode() {
    if (_selectedFeature == null) return;
    _pendingFeatureA = _selectedFeature;
    _pendingFeatureB = null;
    _previewGeometry = null;
    _interactionMode = DrawingInteraction.intersectionSelection;
    _stateMachine.startBooleanOperation(BooleanOperationType.intersection);
    notifyListeners();
  }

  void onFeatureTapped(DrawingFeature feature) {
    if (_interactionMode == DrawingInteraction.normal ||
        _interactionMode == DrawingInteraction.editing) {
      selectFeature(feature);
      return;
    }

    if (_pendingFeatureA == null) return;
    if (feature.id == _pendingFeatureA!.id) return;

    _pendingFeatureB = feature;
    _calculateBooleanOp();
    notifyListeners();
  }

  void _calculateBooleanOp() {
    if (_pendingFeatureA == null || _pendingFeatureB == null) return;

    DrawingGeometry? result;

    switch (_interactionMode) {
      case DrawingInteraction.unionSelection:
        result = DrawingUtils.union(
          _pendingFeatureA!.geometry,
          _pendingFeatureB!.geometry,
        );
        break;
      case DrawingInteraction.differenceSelection:
        result = DrawingUtils.difference(
          _pendingFeatureA!.geometry,
          _pendingFeatureB!.geometry,
        );
        break;
      case DrawingInteraction.intersectionSelection:
        result = DrawingUtils.intersection(
          _pendingFeatureA!.geometry,
          _pendingFeatureB!.geometry,
        );
        break;
      default:
        break;
    }

    if (result != null) {
      // Simplify logic for preview
      result = DrawingUtils.simplifyGeometry(result);
      _previewGeometry = result;
      validateGeometry(_previewGeometry);
      _errorMessage = null;
    } else {
      _previewGeometry = null;
      _errorMessage = "Operação inválida ou complexa demais para esta versão.";
    }
  }

  void confirmBooleanOp() {
    if (_previewGeometry == null) return;

    validateGeometry(_previewGeometry);
    if (!_validationResult.isValid) {
      _errorMessage = _validationResult.message;
      notifyListeners();
      return;
    }

    // Final Normalization
    DrawingGeometry finalGeo = DrawingUtils.simplifyGeometry(_previewGeometry!);
    finalGeo = DrawingUtils.normalizeGeometry(finalGeo);

    if (_selectedFeature != null) {
      updateFeature(
        _selectedFeature!.id,
        newGeometry: finalGeo,
        editorId: "sistema",
        editorType: AuthorType.sistema,
      );
    }
    cancelOperation();
  }

  void confirmImport() {
    if (_previewGeometry == null || _currentImportOrigin == null) return;

    validateGeometry(_previewGeometry);
    if (!_validationResult.isValid) {
      _errorMessage = _validationResult.message;
      notifyListeners();
      return;
    }

    // Final Normalization
    DrawingGeometry finalGeo = DrawingUtils.simplifyGeometry(_previewGeometry!);
    finalGeo = DrawingUtils.normalizeGeometry(finalGeo);

    addFeature(
      geometry: finalGeo,
      nome:
          "Importação ${_currentImportOrigin == DrawingOrigin.importacao_kmz ? 'KMZ' : 'KML'}",
      tipo: DrawingType.outro,
      origem: _currentImportOrigin!,
      autorId: "sistema", // Placeholder
      autorTipo: AuthorType.sistema,
    );

    cancelOperation();
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
}
