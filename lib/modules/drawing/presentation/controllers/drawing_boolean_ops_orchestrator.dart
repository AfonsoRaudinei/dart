import '../../domain/drawing_state.dart';
import '../../domain/drawing_utils.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/services/drawing_boolean_ops_service.dart';

/// Orquestra operações booleanas (union/difference/intersection) no drawing.
class DrawingBooleanOpsOrchestrator {
  DrawingBooleanOpsOrchestrator({
    required DrawingBooleanOpsService booleanOpsService,
    required DrawingFeature? Function() getSelectedFeature,
    required DrawingInteraction Function() getInteractionMode,
    required void Function(DrawingInteraction interaction) setInteractionMode,
    required DrawingGeometry? Function() getPreviewGeometry,
    required void Function(DrawingGeometry? geometry) setPreviewGeometry,
    required void Function(String? message) setErrorMessage,
    required void Function(DrawingGeometry? geometry) validateGeometry,
    required DrawingValidationResult Function() getValidationResult,
    required void Function(BooleanOperationType type)
    startBooleanOperationState,
    required void Function(DrawingFeature feature) selectFeature,
    required void Function(DrawingGeometry geometry)
    applyResultToSelectedFeature,
    required void Function() cancelOperation,
    required void Function() notifyHost,
  }) : _booleanOpsService = booleanOpsService,
       _getSelectedFeature = getSelectedFeature,
       _getInteractionMode = getInteractionMode,
       _setInteractionMode = setInteractionMode,
       _getPreviewGeometry = getPreviewGeometry,
       _setPreviewGeometry = setPreviewGeometry,
       _setErrorMessage = setErrorMessage,
       _validateGeometry = validateGeometry,
       _getValidationResult = getValidationResult,
       _startBooleanOperationState = startBooleanOperationState,
       _selectFeature = selectFeature,
       _applyResultToSelectedFeature = applyResultToSelectedFeature,
       _cancelOperation = cancelOperation,
       _notifyHost = notifyHost;

  final DrawingBooleanOpsService _booleanOpsService;
  final DrawingFeature? Function() _getSelectedFeature;
  final DrawingInteraction Function() _getInteractionMode;
  final void Function(DrawingInteraction interaction) _setInteractionMode;
  final DrawingGeometry? Function() _getPreviewGeometry;
  final void Function(DrawingGeometry? geometry) _setPreviewGeometry;
  final void Function(String? message) _setErrorMessage;
  final void Function(DrawingGeometry? geometry) _validateGeometry;
  final DrawingValidationResult Function() _getValidationResult;
  final void Function(BooleanOperationType type) _startBooleanOperationState;
  final void Function(DrawingFeature feature) _selectFeature;
  final void Function(DrawingGeometry geometry) _applyResultToSelectedFeature;
  final void Function() _cancelOperation;
  final void Function() _notifyHost;

  DrawingFeature? _pendingFeatureA;
  DrawingFeature? _pendingFeatureB;

  DrawingFeature? get pendingFeatureA => _pendingFeatureA;
  DrawingFeature? get pendingFeatureB => _pendingFeatureB;

  void clear() {
    _pendingFeatureA = null;
    _pendingFeatureB = null;
  }

  void startUnionMode() {
    final selected = _getSelectedFeature();
    if (selected == null) return;
    _pendingFeatureA = selected;
    _pendingFeatureB = null;
    _setPreviewGeometry(null);
    _setInteractionMode(DrawingInteraction.unionSelection);
    _startBooleanOperationState(BooleanOperationType.union);
    _notifyHost();
  }

  void startDifferenceMode() {
    final selected = _getSelectedFeature();
    if (selected == null) return;
    _pendingFeatureA = selected;
    _pendingFeatureB = null;
    _setPreviewGeometry(null);
    _setInteractionMode(DrawingInteraction.differenceSelection);
    _startBooleanOperationState(BooleanOperationType.difference);
    _notifyHost();
  }

  void startIntersectionMode() {
    final selected = _getSelectedFeature();
    if (selected == null) return;
    _pendingFeatureA = selected;
    _pendingFeatureB = null;
    _setPreviewGeometry(null);
    _setInteractionMode(DrawingInteraction.intersectionSelection);
    _startBooleanOperationState(BooleanOperationType.intersection);
    _notifyHost();
  }

  void onFeatureTapped(DrawingFeature feature) {
    final interaction = _getInteractionMode();
    if (interaction == DrawingInteraction.normal ||
        interaction == DrawingInteraction.editing) {
      _selectFeature(feature);
      return;
    }

    if (_pendingFeatureA == null) return;
    if (feature.id == _pendingFeatureA!.id) return;

    _pendingFeatureB = feature;
    _calculateBooleanOp();
    _notifyHost();
  }

  void _calculateBooleanOp() {
    if (_pendingFeatureA == null || _pendingFeatureB == null) return;

    final result = _booleanOpsService.calculate(
      _pendingFeatureA!,
      _pendingFeatureB!,
      _getInteractionMode(),
    );

    if (result != null) {
      _setPreviewGeometry(result);
      _validateGeometry(result);
      _setErrorMessage(null);
    } else {
      _setPreviewGeometry(null);
      _setErrorMessage(
        'Operação inválida ou complexa demais para esta versão.',
      );
    }
  }

  void confirmBooleanOp() {
    final preview = _getPreviewGeometry();
    if (preview == null) return;

    _validateGeometry(preview);
    final validation = _getValidationResult();
    if (!validation.isValid) {
      _setErrorMessage(validation.message);
      _notifyHost();
      return;
    }

    final finalGeometry = _booleanOpsService.finalizeResult(preview);
    if (_getSelectedFeature() != null) {
      _applyResultToSelectedFeature(finalGeometry);
    }
    _cancelOperation();
  }
}
