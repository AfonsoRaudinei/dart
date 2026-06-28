import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/ndvi_cache_policy.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_date_nav_provider.dart';

final ndviLocalDatasourceProvider = Provider<NdviLocalDatasource>(
  (_) => NdviLocalDatasource(),
);

final ndviRemoteDatasourceProvider = Provider<NdviRemoteDatasource>(
  (_) => NdviRemoteDatasource(Supabase.instance.client),
);

final ndviCachePolicyProvider = Provider<NdviCachePolicy>(
  (ref) => PreferencesNdviCachePolicy(ref.watch(preferencesServiceProvider)),
);

final ndviRepositoryProvider = Provider<INdviRepository>((ref) {
  final local = ref.watch(ndviLocalDatasourceProvider);
  final remote = ref.watch(ndviRemoteDatasourceProvider);
  final fieldLookup = ref.watch(iFieldLookupProvider);
  final cachePolicy = ref.watch(ndviCachePolicyProvider);
  return NdviRepositoryImpl(local, remote, fieldLookup, cachePolicy: cachePolicy);
});

final ndviImagesProvider = FutureProvider.family
    .autoDispose<List<NdviImage>, String>(
      (ref, fieldId) => ref.watch(ndviRepositoryProvider).getByFieldId(fieldId),
    );

final ndviLatestProvider = FutureProvider.family
    .autoDispose<NdviImage?, String>(
      (ref, fieldId) =>
          ref.watch(ndviRepositoryProvider).getLatestByFieldId(fieldId),
    );

/// Busca lazy da imagem da data selecionada quando só existe stub no cache.
final ndviEnsureCurrentDateProvider = FutureProvider.family
    .autoDispose<void, String>((ref, fieldId) async {
      final images = await ref.watch(ndviImagesProvider(fieldId).future);
      if (images.isEmpty) return;

      final index = ref.watch(ndviDateIndexProvider(fieldId));
      final safeIndex = index.clamp(0, images.length - 1);
      final current = images[safeIndex];
      if (ndviImageHasRenderableData(current)) return;

      await ref
          .read(ndviRepositoryProvider)
          .ensureImageForDate(fieldId, ndviImageDateKey(current.imageDate));
      ref.invalidate(ndviImagesProvider(fieldId));
    });
