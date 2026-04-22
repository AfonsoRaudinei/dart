// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clima_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$climaRepositoryHash() => r'11a30e1c8ef1154554319e3464cae17c497af103';

/// See also [climaRepository].
@ProviderFor(climaRepository)
final climaRepositoryProvider = AutoDisposeProvider<IClimaRepository>.internal(
  climaRepository,
  name: r'climaRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$climaRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClimaRepositoryRef = AutoDisposeProviderRef<IClimaRepository>;
String _$climaLocationHash() => r'ff14ae584c6db5719d766d0bb86606f769cad52f';

/// Obtém coordenadas via GPS. Retorna Brasília como fallback.
///
/// Copied from [climaLocation].
@ProviderFor(climaLocation)
final climaLocationProvider = AutoDisposeFutureProvider<ClimaLatLon>.internal(
  climaLocation,
  name: r'climaLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$climaLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClimaLocationRef = AutoDisposeFutureProviderRef<ClimaLatLon>;
String _$climaAtualHash() => r'93f17942d52fb5b7a6e3791224990c23b199c46d';

/// See also [climaAtual].
@ProviderFor(climaAtual)
final climaAtualProvider = AutoDisposeFutureProvider<ClimaAtual>.internal(
  climaAtual,
  name: r'climaAtualProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$climaAtualHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClimaAtualRef = AutoDisposeFutureProviderRef<ClimaAtual>;
String _$previsaoHorariaHash() => r'e8c2946c6fc2c9dbe0b7df6f490f97dcfbdee8b1';

/// See also [previsaoHoraria].
@ProviderFor(previsaoHoraria)
final previsaoHorariaProvider =
    AutoDisposeFutureProvider<List<PrevisaoHoraria>>.internal(
      previsaoHoraria,
      name: r'previsaoHorariaProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$previsaoHorariaHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrevisaoHorariaRef =
    AutoDisposeFutureProviderRef<List<PrevisaoHoraria>>;
String _$previsaoSemanalHash() => r'eb9bfd01f8a9d9877ae5c21171579cf330a39237';

/// See also [previsaoSemanal].
@ProviderFor(previsaoSemanal)
final previsaoSemanalProvider =
    AutoDisposeFutureProvider<List<PrevisaoDiaria>>.internal(
      previsaoSemanal,
      name: r'previsaoSemanalProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$previsaoSemanalHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrevisaoSemanalRef = AutoDisposeFutureProviderRef<List<PrevisaoDiaria>>;
String _$alertasClimaHash() => r'81e7bb594bdce72a4b131551d60c337a8bba5a12';

/// See also [alertasClima].
@ProviderFor(alertasClima)
final alertasClimaProvider =
    AutoDisposeFutureProvider<List<AlertaMeteorologico>>.internal(
      alertasClima,
      name: r'alertasClimaProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alertasClimaHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlertasClimaRef =
    AutoDisposeFutureProviderRef<List<AlertaMeteorologico>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
