import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/drawing_repository.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/services/drawing_feature_crud_service.dart';
import '../../domain/services/drawing_vertex_edit_service.dart';
import '../../domain/services/drawing_boolean_ops_service.dart';
import '../../domain/services/drawing_import_service.dart';
import '../../domain/services/gps_tracking_service.dart';
import '../../infra/file_picker/file_picker_adapter.dart';
// ADR-019 — DrawingClientNotifier extraído do DrawingController
export 'drawing_client_provider.dart';

final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  return DrawingRepository();
});

// ─── Services puros (Sprint 1) ─────────────────────────────────────────────
final _crudServiceProvider = Provider<DrawingFeatureCrudService>(
  (_) => const DrawingFeatureCrudService(),
);

final _vertexServiceProvider = Provider<DrawingVertexEditService>(
  (_) => const DrawingVertexEditService(),
);

final _booleanOpsServiceProvider = Provider<DrawingBooleanOpsService>(
  (_) => const DrawingBooleanOpsService(),
);

final _importServiceProvider = Provider<DrawingImportService>(
  (_) => const DrawingImportService(FilePickerAdapter()),
);

final _gpsTrackingServiceProvider = Provider<GpsTrackingService>(
  (_) => const GpsTrackingService(),
);
// ───────────────────────────────────────────────────────────────────────────

/// DrawingController provider sem autoDispose para manter estado durante navegação.
/// Lifecycle é controlado explicitamente no PrivateMapScreen.dispose().
final drawingControllerProvider = ChangeNotifierProvider<DrawingController>((
  ref,
) {
  final repo = ref.watch(drawingRepositoryProvider);
  final crudService = ref.watch(_crudServiceProvider);
  final vertexService = ref.watch(_vertexServiceProvider);
  final booleanOpsService = ref.watch(_booleanOpsServiceProvider);
  final importService = ref.watch(_importServiceProvider);
  final gpsTrackingService = ref.watch(_gpsTrackingServiceProvider);

  return DrawingController(
    repository: repo,
    crudService: crudService,
    vertexService: vertexService,
    booleanOpsService: booleanOpsService,
    importService: importService,
    gpsTrackingService: gpsTrackingService,
  );
});

final drawingFeaturesProvider = Provider.autoDispose<List<DrawingFeature>>((
  ref,
) {
  return ref.watch(drawingControllerProvider.select((c) => c.features));
});
