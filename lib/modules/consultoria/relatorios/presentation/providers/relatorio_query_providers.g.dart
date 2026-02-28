// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relatorio_query_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$relatoriosByAgronomistHash() =>
    r'24f74a6572c002a70c0c677fc6592fa90588e187';

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

/// Retorna todos os relatórios do agrônomo especificado, ordenados por
/// [updatedAt] DESC, excluindo os logicamente deletados.
///
/// Filtro de status:
///   - `null` → todos (pendente_revisao + publicado + arquivado)
///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
///   - `RelatorioStatus.publicado` → aba "Compartilhados"
///
/// Copied from [relatoriosByAgronomist].
@ProviderFor(relatoriosByAgronomist)
const relatoriosByAgronomistProvider = RelatoriosByAgronomistFamily();

/// Retorna todos os relatórios do agrônomo especificado, ordenados por
/// [updatedAt] DESC, excluindo os logicamente deletados.
///
/// Filtro de status:
///   - `null` → todos (pendente_revisao + publicado + arquivado)
///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
///   - `RelatorioStatus.publicado` → aba "Compartilhados"
///
/// Copied from [relatoriosByAgronomist].
class RelatoriosByAgronomistFamily
    extends Family<AsyncValue<List<RelatorioTecnico>>> {
  /// Retorna todos os relatórios do agrônomo especificado, ordenados por
  /// [updatedAt] DESC, excluindo os logicamente deletados.
  ///
  /// Filtro de status:
  ///   - `null` → todos (pendente_revisao + publicado + arquivado)
  ///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
  ///   - `RelatorioStatus.publicado` → aba "Compartilhados"
  ///
  /// Copied from [relatoriosByAgronomist].
  const RelatoriosByAgronomistFamily();

  /// Retorna todos os relatórios do agrônomo especificado, ordenados por
  /// [updatedAt] DESC, excluindo os logicamente deletados.
  ///
  /// Filtro de status:
  ///   - `null` → todos (pendente_revisao + publicado + arquivado)
  ///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
  ///   - `RelatorioStatus.publicado` → aba "Compartilhados"
  ///
  /// Copied from [relatoriosByAgronomist].
  RelatoriosByAgronomistProvider call(
    String agronomistId, {
    RelatorioStatus? status,
  }) {
    return RelatoriosByAgronomistProvider(agronomistId, status: status);
  }

  @override
  RelatoriosByAgronomistProvider getProviderOverride(
    covariant RelatoriosByAgronomistProvider provider,
  ) {
    return call(provider.agronomistId, status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relatoriosByAgronomistProvider';
}

/// Retorna todos os relatórios do agrônomo especificado, ordenados por
/// [updatedAt] DESC, excluindo os logicamente deletados.
///
/// Filtro de status:
///   - `null` → todos (pendente_revisao + publicado + arquivado)
///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
///   - `RelatorioStatus.publicado` → aba "Compartilhados"
///
/// Copied from [relatoriosByAgronomist].
class RelatoriosByAgronomistProvider
    extends AutoDisposeFutureProvider<List<RelatorioTecnico>> {
  /// Retorna todos os relatórios do agrônomo especificado, ordenados por
  /// [updatedAt] DESC, excluindo os logicamente deletados.
  ///
  /// Filtro de status:
  ///   - `null` → todos (pendente_revisao + publicado + arquivado)
  ///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
  ///   - `RelatorioStatus.publicado` → aba "Compartilhados"
  ///
  /// Copied from [relatoriosByAgronomist].
  RelatoriosByAgronomistProvider(String agronomistId, {RelatorioStatus? status})
    : this._internal(
        (ref) => relatoriosByAgronomist(
          ref as RelatoriosByAgronomistRef,
          agronomistId,
          status: status,
        ),
        from: relatoriosByAgronomistProvider,
        name: r'relatoriosByAgronomistProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$relatoriosByAgronomistHash,
        dependencies: RelatoriosByAgronomistFamily._dependencies,
        allTransitiveDependencies:
            RelatoriosByAgronomistFamily._allTransitiveDependencies,
        agronomistId: agronomistId,
        status: status,
      );

  RelatoriosByAgronomistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.agronomistId,
    required this.status,
  }) : super.internal();

  final String agronomistId;
  final RelatorioStatus? status;

  @override
  Override overrideWith(
    FutureOr<List<RelatorioTecnico>> Function(
      RelatoriosByAgronomistRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelatoriosByAgronomistProvider._internal(
        (ref) => create(ref as RelatoriosByAgronomistRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        agronomistId: agronomistId,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RelatorioTecnico>> createElement() {
    return _RelatoriosByAgronomistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatoriosByAgronomistProvider &&
        other.agronomistId == agronomistId &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, agronomistId.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RelatoriosByAgronomistRef
    on AutoDisposeFutureProviderRef<List<RelatorioTecnico>> {
  /// The parameter `agronomistId` of this provider.
  String get agronomistId;

  /// The parameter `status` of this provider.
  RelatorioStatus? get status;
}

class _RelatoriosByAgronomistProviderElement
    extends AutoDisposeFutureProviderElement<List<RelatorioTecnico>>
    with RelatoriosByAgronomistRef {
  _RelatoriosByAgronomistProviderElement(super.provider);

  @override
  String get agronomistId =>
      (origin as RelatoriosByAgronomistProvider).agronomistId;
  @override
  RelatorioStatus? get status =>
      (origin as RelatoriosByAgronomistProvider).status;
}

String _$relatorioByIdHash() => r'f97aa5b997dd45fafc9440d2383faf9fa75c36ce';

/// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
///
/// Copied from [relatorioById].
@ProviderFor(relatorioById)
const relatorioByIdProvider = RelatorioByIdFamily();

/// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
///
/// Copied from [relatorioById].
class RelatorioByIdFamily extends Family<AsyncValue<RelatorioTecnico?>> {
  /// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
  ///
  /// Copied from [relatorioById].
  const RelatorioByIdFamily();

  /// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
  ///
  /// Copied from [relatorioById].
  RelatorioByIdProvider call(String id) {
    return RelatorioByIdProvider(id);
  }

  @override
  RelatorioByIdProvider getProviderOverride(
    covariant RelatorioByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relatorioByIdProvider';
}

/// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
///
/// Copied from [relatorioById].
class RelatorioByIdProvider
    extends AutoDisposeFutureProvider<RelatorioTecnico?> {
  /// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
  ///
  /// Copied from [relatorioById].
  RelatorioByIdProvider(String id)
    : this._internal(
        (ref) => relatorioById(ref as RelatorioByIdRef, id),
        from: relatorioByIdProvider,
        name: r'relatorioByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$relatorioByIdHash,
        dependencies: RelatorioByIdFamily._dependencies,
        allTransitiveDependencies:
            RelatorioByIdFamily._allTransitiveDependencies,
        id: id,
      );

  RelatorioByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<RelatorioTecnico?> Function(RelatorioByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelatorioByIdProvider._internal(
        (ref) => create(ref as RelatorioByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RelatorioTecnico?> createElement() {
    return _RelatorioByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatorioByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RelatorioByIdRef on AutoDisposeFutureProviderRef<RelatorioTecnico?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _RelatorioByIdProviderElement
    extends AutoDisposeFutureProviderElement<RelatorioTecnico?>
    with RelatorioByIdRef {
  _RelatorioByIdProviderElement(super.provider);

  @override
  String get id => (origin as RelatorioByIdProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
