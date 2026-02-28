// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_relatorio_use_case.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publishRelatorioHash() => r'51e9a849b1bcb1070ea7390ef1b98ee7f227c196';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Use case: Publicar Relatório Técnico — ADR-009
///
/// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
/// para [RelatorioStatus.publicado] e o enfileira para sincronização.
///
/// Responsabilidades:
///   - Validar que o relatório existe e está em [pendente_revisao]
///   - Atualizar status para [RelatorioStatus.publicado]
///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
///   - Persistir a atualização via [IRelatorioRepository.update]
///   - Retornar o relatório atualizado
///
/// Regras ADR-009:
///   ❌ NÃO chama API diretamente — enfileira via pending_sync
///   ❌ Não é possível publicar um relatório já [arquivado]
///   ✅ Produtor passa a ter acesso após esta transição
///
/// Copied from [publishRelatorio].
@ProviderFor(publishRelatorio)
const publishRelatorioProvider = PublishRelatorioFamily();

/// Use case: Publicar Relatório Técnico — ADR-009
///
/// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
/// para [RelatorioStatus.publicado] e o enfileira para sincronização.
///
/// Responsabilidades:
///   - Validar que o relatório existe e está em [pendente_revisao]
///   - Atualizar status para [RelatorioStatus.publicado]
///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
///   - Persistir a atualização via [IRelatorioRepository.update]
///   - Retornar o relatório atualizado
///
/// Regras ADR-009:
///   ❌ NÃO chama API diretamente — enfileira via pending_sync
///   ❌ Não é possível publicar um relatório já [arquivado]
///   ✅ Produtor passa a ter acesso após esta transição
///
/// Copied from [publishRelatorio].
class PublishRelatorioFamily extends Family<AsyncValue<RelatorioTecnico>> {
  /// Use case: Publicar Relatório Técnico — ADR-009
  ///
  /// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
  /// para [RelatorioStatus.publicado] e o enfileira para sincronização.
  ///
  /// Responsabilidades:
  ///   - Validar que o relatório existe e está em [pendente_revisao]
  ///   - Atualizar status para [RelatorioStatus.publicado]
  ///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
  ///   - Persistir a atualização via [IRelatorioRepository.update]
  ///   - Retornar o relatório atualizado
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API diretamente — enfileira via pending_sync
  ///   ❌ Não é possível publicar um relatório já [arquivado]
  ///   ✅ Produtor passa a ter acesso após esta transição
  ///
  /// Copied from [publishRelatorio].
  const PublishRelatorioFamily();

  /// Use case: Publicar Relatório Técnico — ADR-009
  ///
  /// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
  /// para [RelatorioStatus.publicado] e o enfileira para sincronização.
  ///
  /// Responsabilidades:
  ///   - Validar que o relatório existe e está em [pendente_revisao]
  ///   - Atualizar status para [RelatorioStatus.publicado]
  ///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
  ///   - Persistir a atualização via [IRelatorioRepository.update]
  ///   - Retornar o relatório atualizado
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API diretamente — enfileira via pending_sync
  ///   ❌ Não é possível publicar um relatório já [arquivado]
  ///   ✅ Produtor passa a ter acesso após esta transição
  ///
  /// Copied from [publishRelatorio].
  PublishRelatorioProvider call(String relatorioId) {
    return PublishRelatorioProvider(relatorioId);
  }

  @override
  PublishRelatorioProvider getProviderOverride(
    covariant PublishRelatorioProvider provider,
  ) {
    return call(provider.relatorioId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publishRelatorioProvider';
}

/// Use case: Publicar Relatório Técnico — ADR-009
///
/// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
/// para [RelatorioStatus.publicado] e o enfileira para sincronização.
///
/// Responsabilidades:
///   - Validar que o relatório existe e está em [pendente_revisao]
///   - Atualizar status para [RelatorioStatus.publicado]
///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
///   - Persistir a atualização via [IRelatorioRepository.update]
///   - Retornar o relatório atualizado
///
/// Regras ADR-009:
///   ❌ NÃO chama API diretamente — enfileira via pending_sync
///   ❌ Não é possível publicar um relatório já [arquivado]
///   ✅ Produtor passa a ter acesso após esta transição
///
/// Copied from [publishRelatorio].
class PublishRelatorioProvider
    extends AutoDisposeFutureProvider<RelatorioTecnico> {
  /// Use case: Publicar Relatório Técnico — ADR-009
  ///
  /// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
  /// para [RelatorioStatus.publicado] e o enfileira para sincronização.
  ///
  /// Responsabilidades:
  ///   - Validar que o relatório existe e está em [pendente_revisao]
  ///   - Atualizar status para [RelatorioStatus.publicado]
  ///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
  ///   - Persistir a atualização via [IRelatorioRepository.update]
  ///   - Retornar o relatório atualizado
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API diretamente — enfileira via pending_sync
  ///   ❌ Não é possível publicar um relatório já [arquivado]
  ///   ✅ Produtor passa a ter acesso após esta transição
  ///
  /// Copied from [publishRelatorio].
  PublishRelatorioProvider(String relatorioId)
    : this._internal(
        (ref) => publishRelatorio(ref as PublishRelatorioRef, relatorioId),
        from: publishRelatorioProvider,
        name: r'publishRelatorioProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publishRelatorioHash,
        dependencies: PublishRelatorioFamily._dependencies,
        allTransitiveDependencies:
            PublishRelatorioFamily._allTransitiveDependencies,
        relatorioId: relatorioId,
      );

  PublishRelatorioProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.relatorioId,
  }) : super.internal();

  final String relatorioId;

  @override
  Override overrideWith(
    FutureOr<RelatorioTecnico> Function(PublishRelatorioRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublishRelatorioProvider._internal(
        (ref) => create(ref as PublishRelatorioRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        relatorioId: relatorioId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RelatorioTecnico> createElement() {
    return _PublishRelatorioProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublishRelatorioProvider &&
        other.relatorioId == relatorioId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, relatorioId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublishRelatorioRef on AutoDisposeFutureProviderRef<RelatorioTecnico> {
  /// The parameter `relatorioId` of this provider.
  String get relatorioId;
}

class _PublishRelatorioProviderElement
    extends AutoDisposeFutureProviderElement<RelatorioTecnico>
    with PublishRelatorioRef {
  _PublishRelatorioProviderElement(super.provider);

  @override
  String get relatorioId => (origin as PublishRelatorioProvider).relatorioId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
