// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mapRepositoryHash() => r'ec009f50eb6f932e4b33edff7f97c3e4d5e85fb9';

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
String _$activeLayerHash() => r'16207542deeb7be5ef21ca1c4882f188957d83cc';

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
String _$showMarkersHash() => r'a4286abf0f77fdc7a8e8bf0f68afd5bc338efbdc';

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
String _$mapSatelliteLabelsEnabledHash() =>
    r'ddb405b7da93c2c2e867fc853223d2d38f765b5d';

/// Labels (cidades/estradas) sobre a camada Satélite via MapTiler Hybrid.
///
/// Copied from [MapSatelliteLabelsEnabled].
@ProviderFor(MapSatelliteLabelsEnabled)
final mapSatelliteLabelsEnabledProvider =
    NotifierProvider<MapSatelliteLabelsEnabled, bool>.internal(
      MapSatelliteLabelsEnabled.new,
      name: r'mapSatelliteLabelsEnabledProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mapSatelliteLabelsEnabledHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MapSatelliteLabelsEnabled = Notifier<bool>;
String _$inpeSatelliteOverlayModeCtrlHash() =>
    r'0fad1e30c15e35e5f9899c964d2d8082edca6cc6';

/// Ciclo Off → INPE Cerrado → mosaico Brasil 3M → Off (ícone único no mapa).
///
/// Copied from [InpeSatelliteOverlayModeCtrl].
@ProviderFor(InpeSatelliteOverlayModeCtrl)
final inpeSatelliteOverlayModeCtrlProvider =
    NotifierProvider<
      InpeSatelliteOverlayModeCtrl,
      inpe_overlay.InpeSatelliteOverlayMode
    >.internal(
      InpeSatelliteOverlayModeCtrl.new,
      name: r'inpeSatelliteOverlayModeCtrlProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inpeSatelliteOverlayModeCtrlHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$InpeSatelliteOverlayModeCtrl =
    Notifier<inpe_overlay.InpeSatelliteOverlayMode>;
String _$mapStateBoundariesEnabledHash() =>
    r'fbfa0e443724e0e47ea410b1ecd4e062014c15d4';

/// Divisas estaduais (UF) — malha IBGE sobre o mapa.
///
/// Copied from [MapStateBoundariesEnabled].
@ProviderFor(MapStateBoundariesEnabled)
final mapStateBoundariesEnabledProvider =
    NotifierProvider<MapStateBoundariesEnabled, bool>.internal(
      MapStateBoundariesEnabled.new,
      name: r'mapStateBoundariesEnabledProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mapStateBoundariesEnabledHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MapStateBoundariesEnabled = Notifier<bool>;
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
