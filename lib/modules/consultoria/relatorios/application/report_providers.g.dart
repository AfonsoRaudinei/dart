// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reportRepositoryHash() => r'589e0968d1108eb5c2836a028c37302cfafd8846';

/// See also [reportRepository].
@ProviderFor(reportRepository)
final reportRepositoryProvider =
    AutoDisposeProvider<IReportRepository>.internal(
      reportRepository,
      name: r'reportRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReportRepositoryRef = AutoDisposeProviderRef<IReportRepository>;
String _$relatoriosListHash() => r'59cb5a0e84208e7418df3412c626a318d68a7668';

/// See also [relatoriosList].
@ProviderFor(relatoriosList)
final relatoriosListProvider =
    AutoDisposeFutureProvider<List<Relatorio>>.internal(
      relatoriosList,
      name: r'relatoriosListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$relatoriosListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RelatoriosListRef = AutoDisposeFutureProviderRef<List<Relatorio>>;
String _$relatoriosFilteredHash() =>
    r'7925c30b1ce3b9282f35c606dc3f5f42dbd35669';

/// See also [relatoriosFiltered].
@ProviderFor(relatoriosFiltered)
final relatoriosFilteredProvider =
    AutoDisposeFutureProvider<List<Relatorio>>.internal(
      relatoriosFiltered,
      name: r'relatoriosFilteredProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$relatoriosFilteredHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RelatoriosFilteredRef = AutoDisposeFutureProviderRef<List<Relatorio>>;
String _$relatorioFilterNotifierHash() =>
    r'24b69117fe66fcda75a4141867e6891903f348fe';

/// See also [RelatorioFilterNotifier].
@ProviderFor(RelatorioFilterNotifier)
final relatorioFilterNotifierProvider =
    AutoDisposeNotifierProvider<
      RelatorioFilterNotifier,
      RelatorioFilter
    >.internal(
      RelatorioFilterNotifier.new,
      name: r'relatorioFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$relatorioFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RelatorioFilterNotifier = AutoDisposeNotifier<RelatorioFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
