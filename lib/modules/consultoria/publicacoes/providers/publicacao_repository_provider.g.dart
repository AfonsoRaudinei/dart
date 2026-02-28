// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publicacao_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicacaoRepositoryHash() =>
    r'd172c12c24f4bfcebdf3d785c46b248144e8db8a';

/// Provider concreto SQLite de [IPublicacaoRepository] — ADR-009
///
/// Registra [PublicacaoRepositoryImpl] como implementação oficial do contrato.
/// Mantido em memória durante todo o ciclo de vida do app ([keepAlive: true]).
///
/// Toda camada de domínio ou apresentação deve assistir a este provider
/// (ou ao alias [publicacaoRepositoryProvider]).
///
/// Exemplo de consumo em use case:
/// ```dart
/// final repository = ref.watch(publicacaoRepositoryProvider);
/// ```
///
/// Copied from [publicacaoRepository].
@ProviderFor(publicacaoRepository)
final publicacaoRepositoryProvider = Provider<IPublicacaoRepository>.internal(
  publicacaoRepository,
  name: r'publicacaoRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$publicacaoRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicacaoRepositoryRef = ProviderRef<IPublicacaoRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
