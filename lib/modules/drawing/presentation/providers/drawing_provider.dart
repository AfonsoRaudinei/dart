import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/drawing_repository.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
// 🆕 Cruzamento consultoria→drawing via contrato local (ADR-015)
// NÃO importar consultoria diretamente aqui.
import '../../infra/clients/i_clients_repository_provider.dart';

final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  return DrawingRepository();
});

/// DrawingController provider sem autoDispose para manter estado durante navegação
/// Lifecycle é controlado explicitamente no PrivateMapScreen.dispose()
final drawingControllerProvider = ChangeNotifierProvider<DrawingController>((
  ref,
) {
  final repo = ref.watch(drawingRepositoryProvider);
  final clientsRepo = ref.watch(drawingClientsRepositoryProvider);
  return DrawingController(
    repository: repo,
    clientsRepository: clientsRepo,
  );
});

final drawingFeaturesProvider = Provider.autoDispose<List<DrawingFeature>>((
  ref,
) {
  return ref.watch(drawingControllerProvider.select((c) => c.features));
});
