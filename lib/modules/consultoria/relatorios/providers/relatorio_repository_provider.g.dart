// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relatorio_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$relatorioRepositoryHash() =>
    r'7f8a992c84678d06029ca093d9355d57606c3c3b';

/// Provider concreto SQLite de [IRelatorioRepository] — ADR-009
///
/// Registra [RelatorioRepositoryImpl] como implementação oficial do contrato.
/// Mantido em memória durante todo o ciclo de vida do app ([keepAlive: true]).
///
/// Toda camada de domínio ou apresentação deve assistir a este provider
/// (ou ao alias [relatorioRepositoryProvider]).
///
/// Exemplo de consumo em use case:
/// ```dart
/// final repository = ref.watch(relatorioRepositoryProvider);
/// ```
///
/// Copied from [relatorioRepository].
@ProviderFor(relatorioRepository)
final relatorioRepositoryProvider = Provider<IRelatorioRepository>.internal(
  relatorioRepository,
  name: r'relatorioRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$relatorioRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RelatorioRepositoryRef = ProviderRef<IRelatorioRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
