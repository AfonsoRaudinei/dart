import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/quick_photo_repository.dart';
import '../../domain/quick_photo_record.dart';

final quickPhotoRepositoryProvider = Provider<QuickPhotoRepository>(
  (ref) => QuickPhotoRepository(),
);

final quickPhotoListProvider =
    FutureProvider.autoDispose<List<QuickPhotoRecord>>((ref) async {
      final repository = ref.watch(quickPhotoRepositoryProvider);
      return repository.getRecentForCurrentUser();
    });
