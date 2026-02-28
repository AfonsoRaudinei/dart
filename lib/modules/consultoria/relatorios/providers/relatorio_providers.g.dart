// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relatorio_providers.dart';

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
/// Toda camada de domínio ou apresentação deve assistir a este provider.
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
String _$relatoriosListHash() => r'a0040ceb50bc952077bfba2c1a7db30b034a29db';

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

/// Provider de lista de relatórios por cliente — ADR-008
///
/// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
/// ```
///
/// Copied from [relatoriosList].
@ProviderFor(relatoriosList)
const relatoriosListProvider = RelatoriosListFamily();

/// Provider de lista de relatórios por cliente — ADR-008
///
/// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
/// ```
///
/// Copied from [relatoriosList].
class RelatoriosListFamily extends Family<AsyncValue<List<RelatorioTecnico>>> {
  /// Provider de lista de relatórios por cliente — ADR-008
  ///
  /// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
  /// ```
  ///
  /// Copied from [relatoriosList].
  const RelatoriosListFamily();

  /// Provider de lista de relatórios por cliente — ADR-008
  ///
  /// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
  /// ```
  ///
  /// Copied from [relatoriosList].
  RelatoriosListProvider call({required String clientId}) {
    return RelatoriosListProvider(clientId: clientId);
  }

  @override
  RelatoriosListProvider getProviderOverride(
    covariant RelatoriosListProvider provider,
  ) {
    return call(clientId: provider.clientId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relatoriosListProvider';
}

/// Provider de lista de relatórios por cliente — ADR-008
///
/// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
/// ```
///
/// Copied from [relatoriosList].
class RelatoriosListProvider
    extends AutoDisposeFutureProvider<List<RelatorioTecnico>> {
  /// Provider de lista de relatórios por cliente — ADR-008
  ///
  /// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
  /// ```
  ///
  /// Copied from [relatoriosList].
  RelatoriosListProvider({required String clientId})
    : this._internal(
        (ref) => relatoriosList(ref as RelatoriosListRef, clientId: clientId),
        from: relatoriosListProvider,
        name: r'relatoriosListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$relatoriosListHash,
        dependencies: RelatoriosListFamily._dependencies,
        allTransitiveDependencies:
            RelatoriosListFamily._allTransitiveDependencies,
        clientId: clientId,
      );

  RelatoriosListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.clientId,
  }) : super.internal();

  final String clientId;

  @override
  Override overrideWith(
    FutureOr<List<RelatorioTecnico>> Function(RelatoriosListRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelatoriosListProvider._internal(
        (ref) => create(ref as RelatoriosListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        clientId: clientId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RelatorioTecnico>> createElement() {
    return _RelatoriosListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatoriosListProvider && other.clientId == clientId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, clientId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RelatoriosListRef
    on AutoDisposeFutureProviderRef<List<RelatorioTecnico>> {
  /// The parameter `clientId` of this provider.
  String get clientId;
}

class _RelatoriosListProviderElement
    extends AutoDisposeFutureProviderElement<List<RelatorioTecnico>>
    with RelatoriosListRef {
  _RelatoriosListProviderElement(super.provider);

  @override
  String get clientId => (origin as RelatoriosListProvider).clientId;
}

String _$relatorioDetailHash() => r'ee2acb9761703e7441304a4bf8ff243cc61f1e71';

/// Provider de detalhe de relatório — ADR-008
///
/// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorio = ref.watch(relatorioDetailProvider(id: id));
/// ```
///
/// Copied from [relatorioDetail].
@ProviderFor(relatorioDetail)
const relatorioDetailProvider = RelatorioDetailFamily();

/// Provider de detalhe de relatório — ADR-008
///
/// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorio = ref.watch(relatorioDetailProvider(id: id));
/// ```
///
/// Copied from [relatorioDetail].
class RelatorioDetailFamily extends Family<AsyncValue<RelatorioTecnico?>> {
  /// Provider de detalhe de relatório — ADR-008
  ///
  /// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final relatorio = ref.watch(relatorioDetailProvider(id: id));
  /// ```
  ///
  /// Copied from [relatorioDetail].
  const RelatorioDetailFamily();

  /// Provider de detalhe de relatório — ADR-008
  ///
  /// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final relatorio = ref.watch(relatorioDetailProvider(id: id));
  /// ```
  ///
  /// Copied from [relatorioDetail].
  RelatorioDetailProvider call({required String id}) {
    return RelatorioDetailProvider(id: id);
  }

  @override
  RelatorioDetailProvider getProviderOverride(
    covariant RelatorioDetailProvider provider,
  ) {
    return call(id: provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relatorioDetailProvider';
}

/// Provider de detalhe de relatório — ADR-008
///
/// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorio = ref.watch(relatorioDetailProvider(id: id));
/// ```
///
/// Copied from [relatorioDetail].
class RelatorioDetailProvider
    extends AutoDisposeFutureProvider<RelatorioTecnico?> {
  /// Provider de detalhe de relatório — ADR-008
  ///
  /// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final relatorio = ref.watch(relatorioDetailProvider(id: id));
  /// ```
  ///
  /// Copied from [relatorioDetail].
  RelatorioDetailProvider({required String id})
    : this._internal(
        (ref) => relatorioDetail(ref as RelatorioDetailRef, id: id),
        from: relatorioDetailProvider,
        name: r'relatorioDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$relatorioDetailHash,
        dependencies: RelatorioDetailFamily._dependencies,
        allTransitiveDependencies:
            RelatorioDetailFamily._allTransitiveDependencies,
        id: id,
      );

  RelatorioDetailProvider._internal(
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
    FutureOr<RelatorioTecnico?> Function(RelatorioDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelatorioDetailProvider._internal(
        (ref) => create(ref as RelatorioDetailRef),
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
    return _RelatorioDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatorioDetailProvider && other.id == id;
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
mixin RelatorioDetailRef on AutoDisposeFutureProviderRef<RelatorioTecnico?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _RelatorioDetailProviderElement
    extends AutoDisposeFutureProviderElement<RelatorioTecnico?>
    with RelatorioDetailRef {
  _RelatorioDetailProviderElement(super.provider);

  @override
  String get id => (origin as RelatorioDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
