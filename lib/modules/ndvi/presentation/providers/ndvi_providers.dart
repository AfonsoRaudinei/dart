import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/drawing/infra/field_lookup_provider.dart';

final ndviLocalDatasourceProvider = Provider<NdviLocalDatasource>(
  (_) => NdviLocalDatasource(),
);

final ndviRemoteDatasourceProvider = Provider<NdviRemoteDatasource>(
  (_) => NdviRemoteDatasource(Supabase.instance.client),
);



final ndviRepositoryProvider = Provider<INdviRepository>((ref) {
  final local = ref.watch(ndviLocalDatasourceProvider);
  final remote = ref.watch(ndviRemoteDatasourceProvider);
  final fieldLookup = ref.watch(iFieldLookupProvider);
  return NdviRepositoryImpl(local, remote, fieldLookup);
});

final ndviImagesProvider = FutureProvider.family.autoDispose<List<NdviImage>, String>(
  (ref, fieldId) => ref.watch(ndviRepositoryProvider).getByFieldId(fieldId),
);

final ndviLatestProvider = FutureProvider.family.autoDispose<NdviImage?, String>(
  (ref, fieldId) => ref.watch(ndviRepositoryProvider).getLatestByFieldId(fieldId),
);