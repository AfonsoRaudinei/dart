// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileRepositoryHash() =>
    r'befbad65ed07271aa4c99f56fed6fc2dbea54ea1';

/// See also [userProfileRepository].
@ProviderFor(userProfileRepository)
final userProfileRepositoryProvider =
    AutoDisposeProvider<IUserProfileRepository>.internal(
      userProfileRepository,
      name: r'userProfileRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileRepositoryRef =
    AutoDisposeProviderRef<IUserProfileRepository>;
String _$currentUserProfileHash() =>
    r'de358e2c15d73677ced2074413e2a600d710ad9f';

/// Perfil completo do usuário autenticado (Supabase Auth + perfis + cache).
///
/// autoDispose: true — descartado ao sair da tela de configurações.
/// Retorna null se não houver usuário autenticado.
///
/// Copied from [currentUserProfile].
@ProviderFor(currentUserProfile)
final currentUserProfileProvider =
    AutoDisposeFutureProvider<UserProfile?>.internal(
      currentUserProfile,
      name: r'currentUserProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentUserProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserProfileRef = AutoDisposeFutureProviderRef<UserProfile?>;
String _$profileAuditTrailHash() => r'4cc220c908ce0af77f6457f4f1693c1c09f558eb';

/// Últimas 20 alterações de perfil em ordem cronológica reversa.
///
/// autoDispose: true — carregado apenas quando a seção de auditoria está visível.
///
/// Copied from [profileAuditTrail].
@ProviderFor(profileAuditTrail)
final profileAuditTrailProvider =
    AutoDisposeFutureProvider<List<UserProfileAuditEntry>>.internal(
      profileAuditTrail,
      name: r'profileAuditTrailProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileAuditTrailHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileAuditTrailRef =
    AutoDisposeFutureProviderRef<List<UserProfileAuditEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
