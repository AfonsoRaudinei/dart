// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_relatorio_use_case.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$generateRelatorioHash() => r'dde426735fd3f423bba2f9b70ae9712d3a35096b';

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

/// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
///
/// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
/// [RelatorioTecnico] persistido localmente.
///
/// Responsabilidades:
///   - Atribuir ID único (UUID v4) ao relatório
///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
///   - Persistir via [IRelatorioRepository.save]
///   - Retornar o relatório criado para a camada de apresentação
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
///
/// Copied from [generateRelatorio].
@ProviderFor(generateRelatorio)
const generateRelatorioProvider = GenerateRelatorioFamily();

/// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
///
/// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
/// [RelatorioTecnico] persistido localmente.
///
/// Responsabilidades:
///   - Atribuir ID único (UUID v4) ao relatório
///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
///   - Persistir via [IRelatorioRepository.save]
///   - Retornar o relatório criado para a camada de apresentação
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
///
/// Copied from [generateRelatorio].
class GenerateRelatorioFamily extends Family<AsyncValue<RelatorioTecnico>> {
  /// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
  ///
  /// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
  /// [RelatorioTecnico] persistido localmente.
  ///
  /// Responsabilidades:
  ///   - Atribuir ID único (UUID v4) ao relatório
  ///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
  ///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
  ///   - Persistir via [IRelatorioRepository.save]
  ///   - Retornar o relatório criado para a camada de apresentação
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API — offline-first
  ///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
  ///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
  ///
  /// Copied from [generateRelatorio].
  const GenerateRelatorioFamily();

  /// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
  ///
  /// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
  /// [RelatorioTecnico] persistido localmente.
  ///
  /// Responsabilidades:
  ///   - Atribuir ID único (UUID v4) ao relatório
  ///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
  ///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
  ///   - Persistir via [IRelatorioRepository.save]
  ///   - Retornar o relatório criado para a camada de apresentação
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API — offline-first
  ///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
  ///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
  ///
  /// Copied from [generateRelatorio].
  GenerateRelatorioProvider call(VisitSessionSnapshot snapshot) {
    return GenerateRelatorioProvider(snapshot);
  }

  @override
  GenerateRelatorioProvider getProviderOverride(
    covariant GenerateRelatorioProvider provider,
  ) {
    return call(provider.snapshot);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'generateRelatorioProvider';
}

/// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
///
/// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
/// [RelatorioTecnico] persistido localmente.
///
/// Responsabilidades:
///   - Atribuir ID único (UUID v4) ao relatório
///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
///   - Persistir via [IRelatorioRepository.save]
///   - Retornar o relatório criado para a camada de apresentação
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
///
/// Copied from [generateRelatorio].
class GenerateRelatorioProvider
    extends AutoDisposeFutureProvider<RelatorioTecnico> {
  /// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
  ///
  /// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
  /// [RelatorioTecnico] persistido localmente.
  ///
  /// Responsabilidades:
  ///   - Atribuir ID único (UUID v4) ao relatório
  ///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
  ///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
  ///   - Persistir via [IRelatorioRepository.save]
  ///   - Retornar o relatório criado para a camada de apresentação
  ///
  /// Regras ADR-009:
  ///   ❌ NÃO chama API — offline-first
  ///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
  ///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
  ///
  /// Copied from [generateRelatorio].
  GenerateRelatorioProvider(VisitSessionSnapshot snapshot)
    : this._internal(
        (ref) => generateRelatorio(ref as GenerateRelatorioRef, snapshot),
        from: generateRelatorioProvider,
        name: r'generateRelatorioProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$generateRelatorioHash,
        dependencies: GenerateRelatorioFamily._dependencies,
        allTransitiveDependencies:
            GenerateRelatorioFamily._allTransitiveDependencies,
        snapshot: snapshot,
      );

  GenerateRelatorioProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.snapshot,
  }) : super.internal();

  final VisitSessionSnapshot snapshot;

  @override
  Override overrideWith(
    FutureOr<RelatorioTecnico> Function(GenerateRelatorioRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GenerateRelatorioProvider._internal(
        (ref) => create(ref as GenerateRelatorioRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        snapshot: snapshot,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RelatorioTecnico> createElement() {
    return _GenerateRelatorioProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GenerateRelatorioProvider && other.snapshot == snapshot;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, snapshot.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GenerateRelatorioRef on AutoDisposeFutureProviderRef<RelatorioTecnico> {
  /// The parameter `snapshot` of this provider.
  VisitSessionSnapshot get snapshot;
}

class _GenerateRelatorioProviderElement
    extends AutoDisposeFutureProviderElement<RelatorioTecnico>
    with GenerateRelatorioRef {
  _GenerateRelatorioProviderElement(super.provider);

  @override
  VisitSessionSnapshot get snapshot =>
      (origin as GenerateRelatorioProvider).snapshot;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
