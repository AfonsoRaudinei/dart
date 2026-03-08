// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plano_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$planoRepositoryHash() => r'35b99fb75f3581dda4794d1bf54ce8f28cb4751f';

/// See also [planoRepository].
@ProviderFor(planoRepository)
final planoRepositoryProvider = Provider<PlanoRepositoryImpl>.internal(
  planoRepository,
  name: r'planoRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planoRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlanoRepositoryRef = ProviderRef<PlanoRepositoryImpl>;
String _$referralServiceHash() => r'80cae8a382b8072405b988220967085f420cdd8c';

/// See also [referralService].
@ProviderFor(referralService)
final referralServiceProvider = Provider<ReferralService>.internal(
  referralService,
  name: r'referralServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$referralServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReferralServiceRef = ProviderRef<ReferralService>;
String _$planoAtivoHash() => r'6e6eb2a6d9244cdffee94aab90e34ea384d269aa';

/// Plano ativo do usuário autenticado.
///
/// keepAlive: true — sobrevive ao dispose de telas para que
/// marketing/ e map/ possam consultá-lo sem re-fetch.
///
/// Retorna null se o usuário não possui plano ativo.
///
/// Observa [sessionControllerProvider] para reagir automaticamente ao
/// logout: quando a sessão vira [SessionPublic], retorna null sem erro.
///
/// Copied from [planoAtivo].
@ProviderFor(planoAtivo)
final planoAtivoProvider = FutureProvider<UserPlan?>.internal(
  planoAtivo,
  name: r'planoAtivoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planoAtivoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlanoAtivoRef = FutureProviderRef<UserPlan?>;
String _$referralsHash() => r'34fe3c3dd0706c3eba9e8a440c8cce2912cecf49';

/// See also [referrals].
@ProviderFor(referrals)
final referralsProvider = AutoDisposeFutureProvider<List<Referral>>.internal(
  referrals,
  name: r'referralsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$referralsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReferralsRef = AutoDisposeFutureProviderRef<List<Referral>>;
String _$meuCodigoIndicacaoHash() =>
    r'52771184c0c75dabdbff60c90ec214f6c96a1015';

/// See also [meuCodigoIndicacao].
@ProviderFor(meuCodigoIndicacao)
final meuCodigoIndicacaoProvider =
    AutoDisposeFutureProvider<ReferralCode?>.internal(
      meuCodigoIndicacao,
      name: r'meuCodigoIndicacaoProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$meuCodigoIndicacaoHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MeuCodigoIndicacaoRef = AutoDisposeFutureProviderRef<ReferralCode?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
