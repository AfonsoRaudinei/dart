// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicLocationNotifierHash() =>
    r'1e78e442615cecc627d1d72df7522f9c67faa12e';

/// Provider de localização pública (isolado do mapa privado)
///
/// Copied from [PublicLocationNotifier].
@ProviderFor(PublicLocationNotifier)
final publicLocationNotifierProvider =
    AutoDisposeNotifierProvider<
      PublicLocationNotifier,
      PublicLocationState
    >.internal(
      PublicLocationNotifier.new,
      name: r'publicLocationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicLocationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PublicLocationNotifier = AutoDisposeNotifier<PublicLocationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
