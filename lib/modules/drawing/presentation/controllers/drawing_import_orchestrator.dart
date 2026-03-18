import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_utils.dart';
import '../../domain/services/drawing_import_service.dart';

/// Orquestra o fluxo de importação KML/KMZ para o módulo drawing.
class DrawingImportOrchestrator {
  DrawingImportOrchestrator({
    required DrawingImportService importService,
    required void Function(DrawingFeature? feature) setSelectedFeature,
    required void Function(DrawingInteraction interaction) setInteractionMode,
    required void Function(String? message) setErrorMessage,
    required DrawingGeometry? Function() getPreviewGeometry,
    required void Function(DrawingGeometry? geometry) setPreviewGeometry,
    required void Function(DrawingGeometry? geometry) validateGeometry,
    required DrawingValidationResult Function() getValidationResult,
    required DrawingGeometry Function(DrawingGeometry geometry)
    finalizeGeometry,
    required void Function() startImportPreviewState,
    required void Function() confirmImportState,
    required void Function() notifyHost,
  }) : _importService = importService,
       _setSelectedFeature = setSelectedFeature,
       _setInteractionMode = setInteractionMode,
       _setErrorMessage = setErrorMessage,
       _getPreviewGeometry = getPreviewGeometry,
       _setPreviewGeometry = setPreviewGeometry,
       _validateGeometry = validateGeometry,
       _getValidationResult = getValidationResult,
       _finalizeGeometry = finalizeGeometry,
       _startImportPreviewState = startImportPreviewState,
       _confirmImportState = confirmImportState,
       _notifyHost = notifyHost;

  final DrawingImportService _importService;
  final void Function(DrawingFeature? feature) _setSelectedFeature;
  final void Function(DrawingInteraction interaction) _setInteractionMode;
  final void Function(String? message) _setErrorMessage;
  final DrawingGeometry? Function() _getPreviewGeometry;
  final void Function(DrawingGeometry? geometry) _setPreviewGeometry;
  final void Function(DrawingGeometry? geometry) _validateGeometry;
  final DrawingValidationResult Function() _getValidationResult;
  final DrawingGeometry Function(DrawingGeometry geometry) _finalizeGeometry;
  final void Function() _startImportPreviewState;
  final void Function() _confirmImportState;
  final void Function() _notifyHost;

  bool _isSelfIntersectionMessage(String? message) {
    final text = (message ?? '').toLowerCase();
    return text.contains('auto-interse') ||
        (text.contains('linhas') && text.contains('cruz'));
  }

  DrawingOrigin? _currentImportOrigin;
  DrawingOrigin? get pendingImportOrigin => _currentImportOrigin;

  void setPendingImportOrigin(DrawingOrigin? origin) {
    _currentImportOrigin = origin;
  }

  void clearPendingImportOrigin() {
    _currentImportOrigin = null;
  }

  void startImportMode() {
    _setSelectedFeature(null);
    _setInteractionMode(DrawingInteraction.importing);
    _setErrorMessage(null);
    _notifyHost();
  }

  Future<void> pickImportFile() async {
    _setSelectedFeature(null);
    _setErrorMessage(null);

    final result = await _importService.pickAndParse();
    if (result.cancelled) {
      _setInteractionMode(DrawingInteraction.normal);
    } else if (result.error != null) {
      _setInteractionMode(DrawingInteraction.normal);
      _setErrorMessage(result.error);
    } else {
      _setPreviewGeometry(result.geometry);
      _validateGeometry(result.geometry);
      _setInteractionMode(DrawingInteraction.importPreview);
      _currentImportOrigin = result.origin;
      _startImportPreviewState();
    }

    _notifyHost();
  }

  void confirmImport() {
    final preview = _getPreviewGeometry();
    if (preview == null || _currentImportOrigin == null) return;

    _validateGeometry(preview);
    final validation = _getValidationResult();
    if (!validation.isValid) {
      if (!_isSelfIntersectionMessage(validation.message)) {
        _setErrorMessage(validation.message);
        _notifyHost();
        return;
      }
    }

    _setErrorMessage(null);
    _setPreviewGeometry(_finalizeGeometry(preview));
    _setInteractionMode(DrawingInteraction.normal);
    _confirmImportState();
    _notifyHost();
  }

  /// Confirma a importação ignorando alertas de sobreposição.
  ///
  /// Chamado quando o usuário reconhece a sobreposição e opta por prosseguir.
  void confirmImportForced() {
    final preview = _getPreviewGeometry();
    if (preview == null || _currentImportOrigin == null) return;

    _setErrorMessage(null);
    _setPreviewGeometry(_finalizeGeometry(preview));
    _setInteractionMode(DrawingInteraction.normal);
    _confirmImportState();
    _notifyHost();
  }
}
