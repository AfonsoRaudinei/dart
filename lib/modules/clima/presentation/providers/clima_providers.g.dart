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
String _$climaLocationHash() => r'aed933ca243e629ca414b096dd447c8d2fe71227';

/// Obtém coordenadas para o clima.
/// Prioridade 1: cidade escolhida manualmente.
/// Prioridade 2: posição obtida pelo botão "minha localização".
/// Prioridade 3: localização já conhecida pelo mapa.
/// Prioridade 4: GPS direto (usuário ainda não navegou no mapa).
/// Fallback: Brasília-DF com estado de erro exposto na UI.
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
String _$climaAtualHash() => r'8ff98ebfd9b6455cf6be84c9fd2ae0c0f770ac8d';

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
String _$previsaoHorariaHash() => r'5c23fde4dc2fca2d37d5abc2c47b842b1ea25a94';

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
String _$previsaoSemanalHash() => r'6842a09aa2f29ce3bcc932b552b99695660b139d';

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
String _$alertasClimaHash() => r'90e3c015656c938be52353420f83ba26723e4038';

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
