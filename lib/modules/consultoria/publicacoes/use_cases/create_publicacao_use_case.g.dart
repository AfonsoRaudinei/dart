// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_publicacao_use_case.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$createPublicacaoHash() => r'cc1fba816fc48c7d6548801fd7e0c5c8ae376d97';

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

/// Use case: Criar Publicação Técnica — ADR-009
///
/// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
/// localmente com syncStatus [PublicacaoSyncStatus.local_only].
///
/// Responsabilidades:
///   - Validar campos obrigatórios (título, conteúdo não vazios)
///   - Atribuir ID único (UUID v4)
///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
///   - Persistir via [IPublicacaoRepository.save]
///   - Retornar a publicação criada
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ✅ Publicação fica disponível localmente imediatamente
///   ✅ Sincronização ocorre em etapa separada via pending_sync
///
/// Copied from [createPublicacao].
@ProviderFor(createPublicacao)
const createPublicacaoProvider = CreatePublicacaoFamily();

/// Use case: Criar Publicação Técnica — ADR-009
///
/// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
/// localmente com syncStatus [PublicacaoSyncStatus.local_only].
///
/// Responsabilidades:
///   - Validar campos obrigatórios (título, conteúdo não vazios)
///   - Atribuir ID único (UUID v4)
///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
///   - Persistir via [IPublicacaoRepository.save]
///   - Retornar a publicação criada
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ✅ Publicação fica disponível localmente imediatamente
///   ✅ Sincronização ocorre em etapa separada via pending_sync
///
/// Copied from [createPublicacao].
class CreatePublicacaoFamily extends Family<AsyncValue<PublicacaoTecnica>> {
  /// Use case: Criar Publicação Técnica — ADR-009
  ///
  /// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
  /// localmente com syncStatus [PublicacaoSyncStatus.local_only].
  ///
  /// Responsabilidades:
  ///   - Validar campos obrigatórios (título, conteúdo não vazios)
  ///   - Atribuir ID único (UUID v4)
  ///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
  ///   - Persistir via [IPublicacaoRepository.save]
  ///   - Retornar a publicação criada
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API — offline-first
  ///   ✅ Publicação fica disponível localmente imediatamente
  ///   ✅ Sincronização ocorre em etapa separada via pending_sync
  ///
  /// Copied from [createPublicacao].
  const CreatePublicacaoFamily();

  /// Use case: Criar Publicação Técnica — ADR-009
  ///
  /// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
  /// localmente com syncStatus [PublicacaoSyncStatus.local_only].
  ///
  /// Responsabilidades:
  ///   - Validar campos obrigatórios (título, conteúdo não vazios)
  ///   - Atribuir ID único (UUID v4)
  ///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
  ///   - Persistir via [IPublicacaoRepository.save]
  ///   - Retornar a publicação criada
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API — offline-first
  ///   ✅ Publicação fica disponível localmente imediatamente
  ///   ✅ Sincronização ocorre em etapa separada via pending_sync
  ///
  /// Copied from [createPublicacao].
  CreatePublicacaoProvider call(CreatePublicacaoInput input) {
    return CreatePublicacaoProvider(input);
  }

  @override
  CreatePublicacaoProvider getProviderOverride(
    covariant CreatePublicacaoProvider provider,
  ) {
    return call(provider.input);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createPublicacaoProvider';
}

/// Use case: Criar Publicação Técnica — ADR-009
///
/// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
/// localmente com syncStatus [PublicacaoSyncStatus.local_only].
///
/// Responsabilidades:
///   - Validar campos obrigatórios (título, conteúdo não vazios)
///   - Atribuir ID único (UUID v4)
///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
///   - Persistir via [IPublicacaoRepository.save]
///   - Retornar a publicação criada
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ✅ Publicação fica disponível localmente imediatamente
///   ✅ Sincronização ocorre em etapa separada via pending_sync
///
/// Copied from [createPublicacao].
class CreatePublicacaoProvider
    extends AutoDisposeFutureProvider<PublicacaoTecnica> {
  /// Use case: Criar Publicação Técnica — ADR-009
  ///
  /// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
  /// localmente com syncStatus [PublicacaoSyncStatus.local_only].
  ///
  /// Responsabilidades:
  ///   - Validar campos obrigatórios (título, conteúdo não vazios)
  ///   - Atribuir ID único (UUID v4)
  ///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
  ///   - Persistir via [IPublicacaoRepository.save]
  ///   - Retornar a publicação criada
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API — offline-first
  ///   ✅ Publicação fica disponível localmente imediatamente
  ///   ✅ Sincronização ocorre em etapa separada via pending_sync
  ///
  /// Copied from [createPublicacao].
  CreatePublicacaoProvider(CreatePublicacaoInput input)
    : this._internal(
        (ref) => createPublicacao(ref as CreatePublicacaoRef, input),
        from: createPublicacaoProvider,
        name: r'createPublicacaoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$createPublicacaoHash,
        dependencies: CreatePublicacaoFamily._dependencies,
        allTransitiveDependencies:
            CreatePublicacaoFamily._allTransitiveDependencies,
        input: input,
      );

  CreatePublicacaoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.input,
  }) : super.internal();

  final CreatePublicacaoInput input;

  @override
  Override overrideWith(
    FutureOr<PublicacaoTecnica> Function(CreatePublicacaoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreatePublicacaoProvider._internal(
        (ref) => create(ref as CreatePublicacaoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        input: input,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PublicacaoTecnica> createElement() {
    return _CreatePublicacaoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreatePublicacaoProvider && other.input == input;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, input.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreatePublicacaoRef on AutoDisposeFutureProviderRef<PublicacaoTecnica> {
  /// The parameter `input` of this provider.
  CreatePublicacaoInput get input;
}

class _CreatePublicacaoProviderElement
    extends AutoDisposeFutureProviderElement<PublicacaoTecnica>
    with CreatePublicacaoRef {
  _CreatePublicacaoProviderElement(super.provider);

  @override
  CreatePublicacaoInput get input => (origin as CreatePublicacaoProvider).input;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
