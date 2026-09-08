// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plano_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$planoRepositoryHash() => r'7ab1f3ac6fc2348dc08b8f5bfea9016642ebd8ef';

/// See also [planoRepository].
@ProviderFor(planoRepository)
final planoRepositoryProvider = Provider<IPlanoRepository>.internal(
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
typedef PlanoRepositoryRef = ProviderRef<IPlanoRepository>;
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
String _$planoLocalCacheHash() => r'775591c8f21a1a6334602ce7868786ce9a61e9ee';

/// Cache local do último plano verificado online (TTL 24h — ADR-012 Adendo 1).
///
/// Copied from [planoLocalCache].
@ProviderFor(planoLocalCache)
final planoLocalCacheProvider = Provider<PlanoLocalCache>.internal(
  planoLocalCache,
  name: r'planoLocalCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planoLocalCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlanoLocalCacheRef = ProviderRef<PlanoLocalCache>;
String _$planoAtivoHash() => r'3ff61a56fa8651c01e14fb96e6fcc9334cc9f041';

/// Plano ativo do usuário autenticado.
///
/// keepAlive: true — sobrevive ao dispose de telas para que
/// marketing/ e map/ possam consultá-lo sem re-fetch.
///
/// Nunca retorna null: quando o usuário não possui plano ou não está
/// autenticado, retorna [UserPlan.free()].
///
/// Observa [sessionControllerProvider] para reagir automaticamente ao
/// logout: quando a sessão vira [SessionPublic], retorna UserPlan.free().
///
/// Offline / timeout: serve [PlanoLocalCache] se a verificação online
/// ocorreu nas últimas 24h. [AuthException] nunca usa cache (Adendo 1).
///
/// Copied from [planoAtivo].
@ProviderFor(planoAtivo)
final planoAtivoProvider = FutureProvider<UserPlan>.internal(
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
typedef PlanoAtivoRef = FutureProviderRef<UserPlan>;
String _$referralsHash() => r'8ee9bcef79b3a1c5bad665d693772ca429c3bcc0';

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
    r'80ecceb8605b57619064fd340ae87ee3d84e3f31';

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
