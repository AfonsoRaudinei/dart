// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_style_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicMapStyleHash() => r'30df09a0a58241ec176d0427b6f00ecde0312a16';

/// Provider legado do estilo de mapa no mapa público.
///
/// Tiles da vitrine vêm de [MapConfig.tileConfigForPublicMap], não deste
/// provider. Default OSM para não ressuscitar Carto Voyager se alguém ainda
/// watchar.
///
/// Copied from [PublicMapStyle].
@ProviderFor(PublicMapStyle)
final publicMapStyleProvider =
    AutoDisposeNotifierProvider<PublicMapStyle, MapStyle>.internal(
      PublicMapStyle.new,
      name: r'publicMapStyleProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicMapStyleHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PublicMapStyle = AutoDisposeNotifier<MapStyle>;
String _$tileLoadingStateHash() => r'1ed3a61f7395d4d32e020960bba270751b28b33e';

/// Estado de carregamento de tiles (para debug/monitoramento)
///
/// Copied from [TileLoadingState].
@ProviderFor(TileLoadingState)
final tileLoadingStateProvider =
    AutoDisposeNotifierProvider<TileLoadingState, TileStatus>.internal(
      TileLoadingState.new,
      name: r'tileLoadingStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tileLoadingStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TileLoadingState = AutoDisposeNotifier<TileStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
