// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mapRepositoryHash() => r'8817467e7dde658f0b734ab52d570e8939b97631';

/// See also [mapRepository].
@ProviderFor(mapRepository)
final mapRepositoryProvider = Provider<MapRepository>.internal(
  mapRepository,
  name: r'mapRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mapRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MapRepositoryRef = ProviderRef<MapRepository>;
String _$activeLayerHash() => r'ce2b7762f599f3beaca8a85515cf66435c9486df';

/// See also [ActiveLayer].
@ProviderFor(ActiveLayer)
final activeLayerProvider = NotifierProvider<ActiveLayer, LayerType>.internal(
  ActiveLayer.new,
  name: r'activeLayerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeLayerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveLayer = Notifier<LayerType>;
String _$showMarkersHash() => r'172e4b678910ab6babcac283d33d1cbb568d52ff';

/// See also [ShowMarkers].
@ProviderFor(ShowMarkers)
final showMarkersProvider = NotifierProvider<ShowMarkers, bool>.internal(
  ShowMarkers.new,
  name: r'showMarkersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$showMarkersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ShowMarkers = Notifier<bool>;
String _$publicationsDataHash() => r'387f95c7062d03a5a0d773d922c15e902603560a';

/// See also [PublicationsData].
@ProviderFor(PublicationsData)
final publicationsDataProvider =
    AsyncNotifierProvider<PublicationsData, List<Publication>>.internal(
      PublicationsData.new,
      name: r'publicationsDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicationsDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PublicationsData = AsyncNotifier<List<Publication>>;
String _$publicacoesDataHash() => r'f9f870dc66466fccf642a299e0c72b4e75880229';

/// See also [PublicacoesData].
@ProviderFor(PublicacoesData)
final publicacoesDataProvider =
    AsyncNotifierProvider<PublicacoesData, List<Publicacao>>.internal(
      PublicacoesData.new,
      name: r'publicacoesDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicacoesDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PublicacoesData = AsyncNotifier<List<Publicacao>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
