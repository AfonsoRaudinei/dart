import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_utils.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/services/drawing_import_service.dart';
import 'package:soloforte_app/modules/drawing/infra/file_picker/i_file_picker.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_import_orchestrator.dart';

void main() {
  test('confirmImport com auto-interseção preserva geometria sem simplify', () {
    DrawingGeometry? preview;
    DrawingValidationResult validation = const DrawingValidationResult.valid();
    DrawingInteraction interaction = DrawingInteraction.normal;

    final orchestrator = DrawingImportOrchestrator(
      importService: const DrawingImportService(_CancelledPicker()),
      setSelectedFeature: (_) {},
      setInteractionMode: (mode) => interaction = mode,
      setErrorMessage: (_) {},
      getPreviewGeometry: () => preview,
      setPreviewGeometry: (geometry) => preview = geometry,
      validateGeometry: (_) {
        validation = const DrawingValidationResult.error(
          'Linhas da área estão se cruzando (auto-interseção).',
        );
      },
      getValidationResult: () => validation,
      finalizeGeometry: (geometry) {
        fail('finalizeGeometry não deve ser chamado em auto-interseção');
        return geometry;
      },
      startImportPreviewState: () {},
      confirmImportState: () {},
      notifyHost: () {},
    );

    final original = DrawingPolygon(
      coordinates: [
        [
          [-48.0, -10.0],
          [-47.0, -10.0],
          [-47.5, -9.5],
          [-48.5, -9.5],
          [-48.0, -10.0],
        ],
      ],
    );

    preview = original;
    orchestrator.setPendingImportOrigin(DrawingOrigin.importacao_kml);
    orchestrator.confirmImport();

    expect(preview, isA<DrawingPolygon>());
    expect(interaction, DrawingInteraction.normal);
  });
}

class _CancelledPicker implements IFilePicker {
  const _CancelledPicker();

  @override
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  }) async =>
      null;
}
