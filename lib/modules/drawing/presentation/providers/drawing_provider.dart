import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/drawing_repository.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';

final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  return DrawingRepository();
});

final drawingControllerProvider =
    ChangeNotifierProvider.autoDispose<DrawingController>((ref) {
      final repo = ref.watch(drawingRepositoryProvider);
      return DrawingController(repository: repo);
    });

final drawingFeaturesProvider = Provider.autoDispose<List<DrawingFeature>>((
  ref,
) {
  return ref.watch(drawingControllerProvider.select((c) => c.features));
});
