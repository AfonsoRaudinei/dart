// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publicacao_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicacoesListHash() => r'67ed6ce3d00fe530856bbd7d517e2f98684c623b';

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

/// Provider de lista de publicações públicas — ADR-008
///
/// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
/// filtradas por [tema].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
/// ```
///
/// Copied from [publicacoesList].
@ProviderFor(publicacoesList)
const publicacoesListProvider = PublicacoesListFamily();

/// Provider de lista de publicações públicas — ADR-008
///
/// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
/// filtradas por [tema].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
/// ```
///
/// Copied from [publicacoesList].
class PublicacoesListFamily
    extends Family<AsyncValue<List<PublicacaoTecnica>>> {
  /// Provider de lista de publicações públicas — ADR-008
  ///
  /// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
  /// filtradas por [tema].
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
  /// ```
  ///
  /// Copied from [publicacoesList].
  const PublicacoesListFamily();

  /// Provider de lista de publicações públicas — ADR-008
  ///
  /// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
  /// filtradas por [tema].
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
  /// ```
  ///
  /// Copied from [publicacoesList].
  PublicacoesListProvider call({PublicacaoTema? tema}) {
    return PublicacoesListProvider(tema: tema);
  }

  @override
  PublicacoesListProvider getProviderOverride(
    covariant PublicacoesListProvider provider,
  ) {
    return call(tema: provider.tema);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicacoesListProvider';
}

/// Provider de lista de publicações públicas — ADR-008
///
/// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
/// filtradas por [tema].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
/// ```
///
/// Copied from [publicacoesList].
class PublicacoesListProvider
    extends AutoDisposeFutureProvider<List<PublicacaoTecnica>> {
  /// Provider de lista de publicações públicas — ADR-008
  ///
  /// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
  /// filtradas por [tema].
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
  /// ```
  ///
  /// Copied from [publicacoesList].
  PublicacoesListProvider({PublicacaoTema? tema})
    : this._internal(
        (ref) => publicacoesList(ref as PublicacoesListRef, tema: tema),
        from: publicacoesListProvider,
        name: r'publicacoesListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicacoesListHash,
        dependencies: PublicacoesListFamily._dependencies,
        allTransitiveDependencies:
            PublicacoesListFamily._allTransitiveDependencies,
        tema: tema,
      );

  PublicacoesListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tema,
  }) : super.internal();

  final PublicacaoTema? tema;

  @override
  Override overrideWith(
    FutureOr<List<PublicacaoTecnica>> Function(PublicacoesListRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicacoesListProvider._internal(
        (ref) => create(ref as PublicacoesListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tema: tema,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PublicacaoTecnica>> createElement() {
    return _PublicacoesListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicacoesListProvider && other.tema == tema;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tema.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicacoesListRef
    on AutoDisposeFutureProviderRef<List<PublicacaoTecnica>> {
  /// The parameter `tema` of this provider.
  PublicacaoTema? get tema;
}

class _PublicacoesListProviderElement
    extends AutoDisposeFutureProviderElement<List<PublicacaoTecnica>>
    with PublicacoesListRef {
  _PublicacoesListProviderElement(super.provider);

  @override
  PublicacaoTema? get tema => (origin as PublicacoesListProvider).tema;
}

String _$publicacaoDetailHash() => r'b6e4621104ceca489502323bd8131f584e6120dd';

/// Provider de detalhe de publicação — ADR-008
///
/// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
/// ```
///
/// Copied from [publicacaoDetail].
@ProviderFor(publicacaoDetail)
const publicacaoDetailProvider = PublicacaoDetailFamily();

/// Provider de detalhe de publicação — ADR-008
///
/// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
/// ```
///
/// Copied from [publicacaoDetail].
class PublicacaoDetailFamily extends Family<AsyncValue<PublicacaoTecnica?>> {
  /// Provider de detalhe de publicação — ADR-008
  ///
  /// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
  /// ```
  ///
  /// Copied from [publicacaoDetail].
  const PublicacaoDetailFamily();

  /// Provider de detalhe de publicação — ADR-008
  ///
  /// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
  /// ```
  ///
  /// Copied from [publicacaoDetail].
  PublicacaoDetailProvider call({required String id}) {
    return PublicacaoDetailProvider(id: id);
  }

  @override
  PublicacaoDetailProvider getProviderOverride(
    covariant PublicacaoDetailProvider provider,
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
  String? get name => r'publicacaoDetailProvider';
}

/// Provider de detalhe de publicação — ADR-008
///
/// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
/// ```
///
/// Copied from [publicacaoDetail].
class PublicacaoDetailProvider
    extends AutoDisposeFutureProvider<PublicacaoTecnica?> {
  /// Provider de detalhe de publicação — ADR-008
  ///
  /// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
  /// AutoDispose para economizar recursos quando a tela sai de foco.
  ///
  /// Consumo típico:
  /// ```dart
  /// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
  /// ```
  ///
  /// Copied from [publicacaoDetail].
  PublicacaoDetailProvider({required String id})
    : this._internal(
        (ref) => publicacaoDetail(ref as PublicacaoDetailRef, id: id),
        from: publicacaoDetailProvider,
        name: r'publicacaoDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicacaoDetailHash,
        dependencies: PublicacaoDetailFamily._dependencies,
        allTransitiveDependencies:
            PublicacaoDetailFamily._allTransitiveDependencies,
        id: id,
      );

  PublicacaoDetailProvider._internal(
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
    FutureOr<PublicacaoTecnica?> Function(PublicacaoDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicacaoDetailProvider._internal(
        (ref) => create(ref as PublicacaoDetailRef),
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
  AutoDisposeFutureProviderElement<PublicacaoTecnica?> createElement() {
    return _PublicacaoDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicacaoDetailProvider && other.id == id;
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
mixin PublicacaoDetailRef on AutoDisposeFutureProviderRef<PublicacaoTecnica?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PublicacaoDetailProviderElement
    extends AutoDisposeFutureProviderElement<PublicacaoTecnica?>
    with PublicacaoDetailRef {
  _PublicacaoDetailProviderElement(super.provider);

  @override
  String get id => (origin as PublicacaoDetailProvider).id;
}

String _$publicacaoFormNotifierHash() =>
    r'f0f0dac7b4e1cb2f3f635fc30709385fd95fce1d';

/// Notifier de estado do formulário de publicação — ADR-008
///
/// Gerencia o estado efêmero do formulário de criação.
/// AutoDispose para limpar automaticamente ao sair da tela.
///
/// Consumo típico:
/// ```dart
/// final formState = ref.watch(publicacaoFormNotifierProvider);
/// ref.read(publicacaoFormNotifierProvider.notifier).setTema(tema);
/// ```
///
/// Copied from [PublicacaoFormNotifier].
@ProviderFor(PublicacaoFormNotifier)
final publicacaoFormNotifierProvider =
    AutoDisposeNotifierProvider<
      PublicacaoFormNotifier,
      PublicacaoFormState
    >.internal(
      PublicacaoFormNotifier.new,
      name: r'publicacaoFormNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicacaoFormNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PublicacaoFormNotifier = AutoDisposeNotifier<PublicacaoFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
