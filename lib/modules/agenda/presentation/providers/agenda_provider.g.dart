// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$agendaRepositoryHash() => r'5ebe394e05f7b3655918a5cabe89681c4ce63a59';

/// See also [agendaRepository].
@ProviderFor(agendaRepository)
final agendaRepositoryProvider = Provider<AgendaRepository>.internal(
  agendaRepository,
  name: r'agendaRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$agendaRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AgendaRepositoryRef = ProviderRef<AgendaRepository>;
String _$agendaNotificationServiceHash() =>
    r'e41aa93b06749ea7854d21d29a84b4d127af9c13';

/// See also [agendaNotificationService].
@ProviderFor(agendaNotificationService)
final agendaNotificationServiceProvider =
    Provider<AgendaNotificationService>.internal(
      agendaNotificationService,
      name: r'agendaNotificationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$agendaNotificationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AgendaNotificationServiceRef = ProviderRef<AgendaNotificationService>;
String _$agendaHash() => r'a3559c1add31e27a69b82a5e614fadae35764930';

/// Provider global da agenda — ADR-008 (Fase 4: @riverpod, substitui StateNotifier).
///
/// Copied from [Agenda].
@ProviderFor(Agenda)
final agendaProvider = NotifierProvider<Agenda, AgendaState>.internal(
  Agenda.new,
  name: r'agendaProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$agendaHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Agenda = Notifier<AgendaState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
