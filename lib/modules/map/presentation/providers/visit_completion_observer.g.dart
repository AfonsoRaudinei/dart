// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_completion_observer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$visitCompletionObserverHash() =>
    r'fd14dfe6906b34ea2a99f6e15c456af366913353';

/// Orquestrador: VisitSession finalizada → RelatórioTécnico gerado — ADR-009
///
/// Observa o [agendaObservableProvider] e, quando uma [AgendaSessionData]
/// transiciona de ativa (endAtReal == null) para concluída (endAtReal != null),
/// constrói um [VisitReportInput] e dispara [reportWriterProvider.generateReport]
/// de forma assíncrona (fire-and-forget — sem bloquear a UI).
///
/// **Bounded context (ADR-025):**
///   - `core/contracts/` → fonte dos contratos neutros (IAgendaObservable,
///     IOccurrenceRead, IReportWriter)
///   - `map/` → orquestrador (este arquivo)
///   - SEM imports diretos de `agenda/`, `consultoria/` ou `visitas/`
///
/// **Mapeamento de campos (declarado explicitamente conforme ADR-009):**
///
/// | Fonte (AgendaEventData / AgendaSessionData) | VisitReportInput.campo | Observação               |
/// |--------------------------------------------|------------------------|--------------------------|
/// | session.id                                 | sessionId              | direto                   |
/// | event.clienteId                            | clientId               | direto                   |
/// | event.fazendaId                            | farmName               | proxy DT-025-8¹          |
/// | session.createdBy                          | agronomistId           | direto                   |
/// | session.startAtReal                        | startedAt              | direto                   |
/// | session.endAtReal!                         | finishedAt             | não-null garantido       |
/// | IOccurrenceRead                            | occurrences            | query por session.id²    |
/// | event.talhaoId                             | talhaoId               | ID disponível, nome TODO |
///
/// ¹ DT-025-8: `event.fazendaId` como farmName. Proxy ADR-010 enquanto
///   lookup de nome da fazenda não está implementado.
///
/// ² `IOccurrenceRead.getBySessionId(session.id)` via `occurrenceReadProvider`.
///
/// **Ativação:** lido no boot do app para registrar o listener.
/// Ver `main.dart`: `ref.read(visitCompletionObserverProvider); // ADR-010`
///
/// Copied from [VisitCompletionObserver].
@ProviderFor(VisitCompletionObserver)
final visitCompletionObserverProvider =
    NotifierProvider<VisitCompletionObserver, void>.internal(
      VisitCompletionObserver.new,
      name: r'visitCompletionObserverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$visitCompletionObserverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VisitCompletionObserver = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
