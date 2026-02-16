import 'package:latlong2/latlong.dart';
import '../domain/models/drawing_models.dart';
import '../domain/drawing_state.dart' as machine;

/// Estado imutável do módulo de desenho.
/// 
/// Princípios:
/// - Imutável (todas as propriedades são final)
/// - Copyable (método copyWith para atualizações)
/// - Sem lógica de negócio (apenas dados)
/// 
/// Este estado é gerenciado por [DrawingNotifier].
class DrawingAppState {
  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTÊNCIA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Lista de features salvas (polígonos, áreas, etc).
  final List<DrawingFeature> features;
  
  /// Número de features pendentes de sincronização.
  final int pendingSyncCount;

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADO DA MÁQUINA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Estado atual da máquina de estados.
  final machine.DrawingState machineState;
  
  /// Ferramenta de desenho ativa.
  final machine.DrawingTool currentTool;
  
  /// Operação booleana ativa (união, diferença, interseção).
  final machine.BooleanOperationType? booleanOperation;

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Feature selecionada para edição ou operações.
  final DrawingFeature? selectedFeature;
  
  /// Modo de interação legado (será depreciado).
  final DrawingInteraction interactionMode;
  
  /// Feature A para operações booleanas.
  final DrawingFeature? pendingFeatureA;
  
  /// Feature B para operações booleanas.
  final DrawingFeature? pendingFeatureB;
  
  /// Preview de geometria resultante de operações.
  final DrawingGeometry? previewGeometry;

  // ═══════════════════════════════════════════════════════════════════════════
  // DESENHO ATIVO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Pontos do desenho atual (em progresso).
  final List<LatLng> currentPoints;
  
  /// Geometria manual em construção.
  final DrawingGeometry? manualSketch;
  
  /// Geometria sendo editada.
  final DrawingGeometry? editGeometry;
  
  /// Pilha de undo para edição.
  final List<DrawingGeometry> undoStack;

  // ═══════════════════════════════════════════════════════════════════════════
  // FEEDBACK & VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Indica se snap foi aplicado no último ponto.
  final bool isSnapping;
  
  /// Indica se geometria é complexa (>2000 vértices).
  final bool isHighComplexity;
  
  /// Resultado da última validação.
  final ValidationResult validationResult;
  
  /// Mensagem de erro atual.
  final String? errorMessage;
  
  /// Indica se há mudanças não salvas.
  final bool isDirty;

  // ═══════════════════════════════════════════════════════════════════════════
  // IMPORTAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Origem da importação atual (KML/KMZ/GeoJSON).
  final DrawingOrigin? currentImportOrigin;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUTOR
  // ═══════════════════════════════════════════════════════════════════════════

  const DrawingAppState({
    required this.features,
    required this.pendingSyncCount,
    required this.machineState,
    required this.currentTool,
    this.booleanOperation,
    this.selectedFeature,
    required this.interactionMode,
    this.pendingFeatureA,
    this.pendingFeatureB,
    this.previewGeometry,
    required this.currentPoints,
    this.manualSketch,
    this.editGeometry,
    required this.undoStack,
    required this.isSnapping,
    required this.isHighComplexity,
    required this.validationResult,
    this.errorMessage,
    required this.isDirty,
    this.currentImportOrigin,
  });

  /// Estado inicial (idle, sem desenhos).
  factory DrawingAppState.initial() => const DrawingAppState(
        features: [],
        pendingSyncCount: 0,
        machineState: machine.DrawingState.idle,
        currentTool: machine.DrawingTool.none,
        interactionMode: DrawingInteraction.normal,
        currentPoints: [],
        undoStack: [],
        isSnapping: false,
        isHighComplexity: false,
        validationResult: ValidationResult.valid(),
        isDirty: false,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // COPYWITH
  // ═══════════════════════════════════════════════════════════════════════════

  DrawingAppState copyWith({
    List<DrawingFeature>? features,
    int? pendingSyncCount,
    machine.DrawingState? machineState,
    machine.DrawingTool? currentTool,
    machine.BooleanOperationType? Function()? booleanOperation,
    DrawingFeature? Function()? selectedFeature,
    DrawingInteraction? interactionMode,
    DrawingFeature? Function()? pendingFeatureA,
    DrawingFeature? Function()? pendingFeatureB,
    DrawingGeometry? Function()? previewGeometry,
    List<LatLng>? currentPoints,
    DrawingGeometry? Function()? manualSketch,
    DrawingGeometry? Function()? editGeometry,
    List<DrawingGeometry>? undoStack,
    bool? isSnapping,
    bool? isHighComplexity,
    ValidationResult? validationResult,
    String? Function()? errorMessage,
    bool? isDirty,
    DrawingOrigin? Function()? currentImportOrigin,
  }) {
    return DrawingAppState(
      features: features ?? this.features,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      machineState: machineState ?? this.machineState,
      currentTool: currentTool ?? this.currentTool,
      booleanOperation:
          booleanOperation != null ? booleanOperation() : this.booleanOperation,
      selectedFeature:
          selectedFeature != null ? selectedFeature() : this.selectedFeature,
      interactionMode: interactionMode ?? this.interactionMode,
      pendingFeatureA:
          pendingFeatureA != null ? pendingFeatureA() : this.pendingFeatureA,
      pendingFeatureB:
          pendingFeatureB != null ? pendingFeatureB() : this.pendingFeatureB,
      previewGeometry:
          previewGeometry != null ? previewGeometry() : this.previewGeometry,
      currentPoints: currentPoints ?? this.currentPoints,
      manualSketch: manualSketch != null ? manualSketch() : this.manualSketch,
      editGeometry: editGeometry != null ? editGeometry() : this.editGeometry,
      undoStack: undoStack ?? this.undoStack,
      isSnapping: isSnapping ?? this.isSnapping,
      isHighComplexity: isHighComplexity ?? this.isHighComplexity,
      validationResult: validationResult ?? this.validationResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isDirty: isDirty ?? this.isDirty,
      currentImportOrigin: currentImportOrigin != null
          ? currentImportOrigin()
          : this.currentImportOrigin,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Geometria sendo visualizada (desenho ativo, edição, ou preview).
  DrawingGeometry? get liveGeometry {
    if (machineState == machine.DrawingState.editing) {
      return editGeometry;
    }

    if (previewGeometry != null) {
      return previewGeometry;
    }

    if (currentPoints.isNotEmpty) {
      final ring = currentPoints
          .map((p) => [p.longitude, p.latitude])
          .toList();

      final isPolygonTool = currentTool == machine.DrawingTool.polygon ||
          currentTool == machine.DrawingTool.freehand ||
          currentTool == machine.DrawingTool.pivot;

      if (isPolygonTool && ring.length > 2) {
        final first = ring.first;
        final last = ring.last;
        final needsClosure = (first[0] - last[0]).abs() > 1e-9 ||
            (first[1] - last[1]).abs() > 1e-9;
        if (needsClosure) {
          ring.add(first);
        }
        return DrawingPolygon(coordinates: [ring]);
      }
      return DrawingPolygon(coordinates: [ring]);
    }

    return manualSketch;
  }

  /// Texto de instrução para o usuário (tooltip).
  String get instructionText {
    if (errorMessage != null) return "Erro: $errorMessage";
    if (!validationResult.isValid) {
      return "⚠️ ${validationResult.message}";
    }

    switch (interactionMode) {
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
        if (previewGeometry == null) {
          return "Seleção de Diferença: Toque na área a subtrair";
        }
        return "Confirme a subtração";
      case DrawingInteraction.intersectionSelection:
        if (pendingFeatureB == null) {
          return "Seleção de Interseção: Toque na segunda área";
        }
        return "Confirme a interseção";
      case DrawingInteraction.editing:
        if (isHighComplexity) {
          return "⚠️ Área complexa — validação simplificada";
        }
        if (isSnapping) return "⚡ Ponto ajustado (snap)";
        return "Arraste: Mover • Toque na linha: Adicionar • Toque no ponto: Remover";
      case DrawingInteraction.normal:
        if (machineState == machine.DrawingState.armed) {
          return "Toque no mapa para iniciar o desenho";
        }
        if (machineState == machine.DrawingState.drawing ||
            currentPoints.isNotEmpty) {
          final pointCount = currentPoints.length;
          if (pointCount == 0) {
            return "Toque no mapa para iniciar o desenho";
          }
          if (isSnapping) return "⚡ Ponto ajustado (snap)";
          if (pointCount < 3) {
            return "Continue tocando para desenhar a área";
          }
          return "Toque para continuar ou no ponto inicial para fechar";
        }
        if (manualSketch == null) {
          return "Selecione uma ferramenta ou toque no mapa";
        } else {
          int pointCount = 0;
          if (manualSketch is DrawingPolygon) {
            final poly = manualSketch as DrawingPolygon;
            if (poly.coordinates.isNotEmpty) {
              pointCount = poly.coordinates.first.length;
            }
          }

          if (pointCount == 0) {
            return "Toque no mapa para iniciar o desenho";
          }
          if (isSnapping) return "⚡ Ponto ajustado (snap)";
          if (pointCount < 3) {
            return "Continue tocando para desenhar a área";
          }
          return "Toque para continuar ou no ponto inicial para fechar";
        }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingAppState &&
          runtimeType == other.runtimeType &&
          features == other.features &&
          pendingSyncCount == other.pendingSyncCount &&
          machineState == other.machineState &&
          currentTool == other.currentTool &&
          booleanOperation == other.booleanOperation &&
          selectedFeature == other.selectedFeature &&
          interactionMode == other.interactionMode &&
          pendingFeatureA == other.pendingFeatureA &&
          pendingFeatureB == other.pendingFeatureB &&
          previewGeometry == other.previewGeometry &&
          currentPoints == other.currentPoints &&
          manualSketch == other.manualSketch &&
          editGeometry == other.editGeometry &&
          undoStack == other.undoStack &&
          isSnapping == other.isSnapping &&
          isHighComplexity == other.isHighComplexity &&
          validationResult == other.validationResult &&
          errorMessage == other.errorMessage &&
          isDirty == other.isDirty &&
          currentImportOrigin == other.currentImportOrigin;

  @override
  int get hashCode =>
      features.hashCode ^
      pendingSyncCount.hashCode ^
      machineState.hashCode ^
      currentTool.hashCode ^
      booleanOperation.hashCode ^
      selectedFeature.hashCode ^
      interactionMode.hashCode ^
      pendingFeatureA.hashCode ^
      pendingFeatureB.hashCode ^
      previewGeometry.hashCode ^
      currentPoints.hashCode ^
      manualSketch.hashCode ^
      editGeometry.hashCode ^
      undoStack.hashCode ^
      isSnapping.hashCode ^
      isHighComplexity.hashCode ^
      validationResult.hashCode ^
      errorMessage.hashCode ^
      isDirty.hashCode ^
      currentImportOrigin.hashCode;
}

/// Resultado de validação de geometria.
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult.valid() : isValid = true, message = null;
  const ValidationResult.invalid(this.message) : isValid = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          message == other.message;

  @override
  int get hashCode => isValid.hashCode ^ message.hashCode;
}
