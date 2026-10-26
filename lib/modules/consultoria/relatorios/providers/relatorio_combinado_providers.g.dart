// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relatorio_combinado_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$relatorioCombinadoRepositoryHash() =>
    r'33155a455a87842e16aa74f703c3c4666dcbf591';

/// Repositório SQLite de combinações salvas. Sobrescrevível em teste.
///
/// Copied from [relatorioCombinadoRepository].
@ProviderFor(relatorioCombinadoRepository)
final relatorioCombinadoRepositoryProvider =
    Provider<RelatorioCombinadoRepository>.internal(
      relatorioCombinadoRepository,
      name: r'relatorioCombinadoRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$relatorioCombinadoRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RelatorioCombinadoRepositoryRef =
    ProviderRef<RelatorioCombinadoRepository>;
String _$relatoriosCombinadosHash() =>
    r'fcf103e558ba070de057627e906929a319b9b29d';

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

/// Combinações vivas do produtor, mais recentes primeiro.
///
/// Copied from [relatoriosCombinados].
@ProviderFor(relatoriosCombinados)
const relatoriosCombinadosProvider = RelatoriosCombinadosFamily();

/// Combinações vivas do produtor, mais recentes primeiro.
///
/// Copied from [relatoriosCombinados].
class RelatoriosCombinadosFamily
    extends Family<AsyncValue<List<RelatorioCombinado>>> {
  /// Combinações vivas do produtor, mais recentes primeiro.
  ///
  /// Copied from [relatoriosCombinados].
  const RelatoriosCombinadosFamily();

  /// Combinações vivas do produtor, mais recentes primeiro.
  ///
  /// Copied from [relatoriosCombinados].
  RelatoriosCombinadosProvider call(String clientId) {
    return RelatoriosCombinadosProvider(clientId);
  }

  @override
  RelatoriosCombinadosProvider getProviderOverride(
    covariant RelatoriosCombinadosProvider provider,
  ) {
    return call(provider.clientId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relatoriosCombinadosProvider';
}

/// Combinações vivas do produtor, mais recentes primeiro.
///
/// Copied from [relatoriosCombinados].
class RelatoriosCombinadosProvider
    extends AutoDisposeFutureProvider<List<RelatorioCombinado>> {
  /// Combinações vivas do produtor, mais recentes primeiro.
  ///
  /// Copied from [relatoriosCombinados].
  RelatoriosCombinadosProvider(String clientId)
    : this._internal(
        (ref) => relatoriosCombinados(ref as RelatoriosCombinadosRef, clientId),
        from: relatoriosCombinadosProvider,
        name: r'relatoriosCombinadosProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$relatoriosCombinadosHash,
        dependencies: RelatoriosCombinadosFamily._dependencies,
        allTransitiveDependencies:
            RelatoriosCombinadosFamily._allTransitiveDependencies,
        clientId: clientId,
      );

  RelatoriosCombinadosProvider._internal(
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
    FutureOr<List<RelatorioCombinado>> Function(
      RelatoriosCombinadosRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelatoriosCombinadosProvider._internal(
        (ref) => create(ref as RelatoriosCombinadosRef),
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
  AutoDisposeFutureProviderElement<List<RelatorioCombinado>> createElement() {
    return _RelatoriosCombinadosProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatoriosCombinadosProvider && other.clientId == clientId;
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
mixin RelatoriosCombinadosRef
    on AutoDisposeFutureProviderRef<List<RelatorioCombinado>> {
  /// The parameter `clientId` of this provider.
  String get clientId;
}

class _RelatoriosCombinadosProviderElement
    extends AutoDisposeFutureProviderElement<List<RelatorioCombinado>>
    with RelatoriosCombinadosRef {
  _RelatoriosCombinadosProviderElement(super.provider);

  @override
  String get clientId => (origin as RelatoriosCombinadosProvider).clientId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
