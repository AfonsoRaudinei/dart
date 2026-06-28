// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$agendaFiltersHash() => r'607a8e55f262ec8dd44404a7b2c5caefc0060883';

/// Filtros persistidos da agenda — ADR-008 (Fase 4: @riverpod).
///
/// Copied from [AgendaFilters].
@ProviderFor(AgendaFilters)
final agendaFiltersProvider =
    NotifierProvider<AgendaFilters, AgendaFilterCriteria>.internal(
      AgendaFilters.new,
      name: r'agendaFiltersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$agendaFiltersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AgendaFilters = Notifier<AgendaFilterCriteria>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
