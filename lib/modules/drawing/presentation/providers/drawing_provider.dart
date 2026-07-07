import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/drawing_repository.dart';
import '../../data/data_sources/drawing_local_store.dart';
import '../controllers/drawing_controller.dart';
export '../controllers/drawing_controller.dart';
import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/services/drawing_feature_crud_service.dart';
import '../../domain/services/drawing_vertex_edit_service.dart';
import '../../domain/services/drawing_boolean_ops_service.dart';
import '../../domain/services/drawing_import_service.dart';
import '../../domain/services/gps_tracking_service.dart';
import '../../infra/file_picker/file_picker_adapter.dart';
// ADR-019 — DrawingClientNotifier extraído do DrawingController
export 'drawing_client_provider.dart';

final drawingLocalStoreProvider = Provider<DrawingLocalStore>((ref) {
  return DrawingLocalStore();
});

final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  final store = ref.watch(drawingLocalStoreProvider);
  return DrawingRepository(localStore: store);
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

/// Métricas agregadas para o mapa — 1 rebuild vs 8× ref.watch no orchestrator.
/// Fase 1 performance hot path.
class DrawingMapMetrics {
  const DrawingMapMetrics({
    required this.state,
    required this.tool,
    required this.canUndo,
    required this.canRedo,
    required this.measureAreaHa,
    required this.measurePerimeterKm,
    required this.measureAzimuthDeg,
    required this.gpsAccuracyM,
  });

  final DrawingState state;
  final DrawingTool tool;
  final bool canUndo;
  final bool canRedo;
  final double measureAreaHa;
  final double measurePerimeterKm;
  final double? measureAzimuthDeg;
  final double? gpsAccuracyM;
}

final drawingMapMetricsProvider = Provider<DrawingMapMetrics>((ref) {
  ref.watch(
    drawingControllerProvider.select(
      (c) => (
        c.currentState,
        c.currentTool,
        c.canUndo,
        c.canRedo,
        c.reviewAreaHa,
        c.reviewPerimeterKm,
        c.liveAzimuthDegrees,
        c.gpsLastAccuracyM,
      ),
    ),
  );
  final controller = ref.read(drawingControllerProvider);
  return DrawingMapMetrics(
    state: controller.currentState,
    tool: controller.currentTool,
    canUndo: controller.canUndo,
    canRedo: controller.canRedo,
    measureAreaHa: controller.reviewAreaHa,
    measurePerimeterKm: controller.reviewPerimeterKm,
    measureAzimuthDeg: controller.liveAzimuthDegrees,
    gpsAccuracyM: controller.gpsLastAccuracyM,
  );
});
