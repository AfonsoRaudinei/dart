import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/i_visit_session_lookup_provider.dart';
import '../../data/quick_photo_repository.dart';
import '../../data/services/quick_photo_client_id_backfill_service.dart';
import '../../domain/quick_photo_record.dart';

final quickPhotoRepositoryProvider = Provider<QuickPhotoRepository>(
  (ref) => QuickPhotoRepository(),
);

final quickPhotoClientIdBackfillServiceProvider =
    Provider<QuickPhotoClientIdBackfillService>((ref) {
      return QuickPhotoClientIdBackfillService(
        repository: ref.watch(quickPhotoRepositoryProvider),
        visitLookup: ref.watch(visitSessionLookupProvider),
      );
    });

final quickPhotoListProvider =
    FutureProvider.autoDispose<List<QuickPhotoRecord>>((ref) async {
      final repository = ref.watch(quickPhotoRepositoryProvider);
      final backfill = ref.watch(quickPhotoClientIdBackfillServiceProvider);
      final photos = await repository.getRecentForCurrentUser();
      return backfill.backfillIfNeeded(photos);
    });
