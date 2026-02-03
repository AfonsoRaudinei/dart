// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mapRepositoryHash() => r'014c4d69cc2d70926341a58bc57a459c0cb19ad5';

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
String _$activeLayerHash() => r'd511436a26c92ed6a80c11dd9cb5636fab39ab8e';

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
String _$publicationsDataHash() => r'f7c2a274ce43c70d2fa8920467f4991a57442891';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
