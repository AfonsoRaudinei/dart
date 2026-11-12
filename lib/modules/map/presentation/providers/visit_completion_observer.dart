import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/contracts/i_agenda_observable.dart';
import '../../../../core/contracts/i_agenda_observable_provider.dart';
import '../../../../core/contracts/i_agenda_session_bridge.dart';
import '../../../../core/contracts/i_agenda_session_bridge_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../../../core/contracts/i_field_lookup_provider.dart';
import '../../../../core/contracts/i_occurrence_read.dart';
import '../../../../core/contracts/i_occurrence_read_provider.dart';
import '../../../../core/contracts/i_report_writer.dart';
import '../../../../core/contracts/i_report_writer_provider.dart';
import '../../../../core/contracts/i_visit_photo_read_provider.dart';
import '../../../../core/contracts/i_visit_session_lookup_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/visit_report_place_name.dart';

part 'visit_completion_observer.g.dart';

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
@Riverpod(keepAlive: true)
class VisitCompletionObserver extends _$VisitCompletionObserver {
  static const String _tag = 'VisitCompletionObserver';
  bool _reconciled = false;

  @override
  void build() {
    ref.listen<AgendaObservableState>(
      agendaObservableProvider,
      (previous, next) => _onAgendaStateChanged(previous, next),
      fireImmediately: false,
    );
  }

  // ── Detecção de transição ─────────────────────────────────────────────

  /// Chamado a cada mudança no [agendaObservableProvider].
  ///
  /// Detecta sessões que acabaram de ser concluídas comparando o estado
  /// anterior com o novo. Só dispara para transições reais
  /// (endAtReal era null → passou a não-null), evitando:
  ///   - reprocessamento ao reiniciar o app
  ///   - duplicação por múltiplas reconstruções
  void _onAgendaStateChanged(
    AgendaObservableState? previous,
    AgendaObservableState next,
  ) {
    final previousSessions = previous?.sessions ?? const [];

    for (final session in next.sessions) {
      // Só interessa sessões que acabaram de ser concluídas
      if (session.endAtReal == null) continue;

      // Verifica se estava ativa (sem endAtReal) no estado anterior
      final wasActive = previousSessions.any(
        (s) => s.id == session.id && s.endAtReal == null,
      );

      if (!wasActive) continue; // Já estava concluída ou é nova — ignorar

      // Encontra o evento associado à sessão
      final event = next.events
          .where((e) => e.visitSessionId == session.id)
          .firstOrNull;

      if (event == null) {
        AppLogger.warning(
          'Sessão ${session.id} concluída mas evento associado não encontrado.',
          tag: _tag,
        );
        continue;
      }

      _dispatchReportGeneration(event: event, session: session);
    }

    if (next.ready && !_reconciled) {
      _reconciled = true;
      unawaited(_reconcileUnlinkedFinishedVisits());
    }
  }

  /// Visitas encerradas no mapa antes desta entrega não têm evento.
  /// Entram na agenda já concluídas e ganham relatório uma vez. ADR-060.
  Future<void> _reconcileUnlinkedFinishedVisits() async {
    try {
      final finished = await ref
          .read(visitSessionLookupProvider)
          .listFinished();
      final linked = ref
          .read(agendaObservableProvider)
          .events
          .map((event) => event.visitSessionId)
          .whereType<String>()
          .toSet();

      for (final session in finished) {
        if (session.id.isEmpty || linked.contains(session.id)) continue;
        final end =
            session.endTime ??
            session.startTime.add(const Duration(minutes: 5));
        await ref
            .read(agendaSessionBridgeProvider)
            .registerFinishedFieldVisit(
              FieldVisitCheckIn(
                sessionId: session.id,
                clientId: session.producerId,
                farmId: session.farmId,
                areaId: session.areaId,
                activityType: session.activityType,
                startTime: session.startTime,
                latitude: session.initialLat ?? 0,
                longitude: session.initialLong ?? 0,
                endTime: end,
              ),
            );
        linked.add(session.id);

        final state = ref.read(agendaObservableProvider);
        final event = state.events
            .where((item) => item.visitSessionId == session.id)
            .firstOrNull;
        final agendaSession = state.sessions
            .where((item) => item.id == session.id && item.endAtReal != null)
            .firstOrNull;
        if (event == null || agendaSession == null) continue;
        await _buildAndDispatch(event: event, session: agendaSession);
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao registrar visitas encerradas sem evento de agenda.',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Disparo do use case ───────────────────────────────────────────────

  /// Constrói [VisitReportInput] e dispara [IReportWriter.generateReport].
  ///
  /// Fire-and-forget: erros são logados mas NÃO propagados para não
  /// bloquear o fluxo de conclusão da visita.
  void _dispatchReportGeneration({
    required AgendaEventData event,
    required AgendaSessionData session,
  }) {
    _buildAndDispatch(event: event, session: session).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      AppLogger.error(
        'Falha ao gerar relatório para sessão ${session.id}.',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Busca ocorrências, monta [VisitReportInput] e chama [IReportWriter].
  Future<void> _buildAndDispatch({
    required AgendaEventData event,
    required AgendaSessionData session,
  }) async {
    AppLogger.debug(
      'Buscando dados enriquecidos para sessão ${session.id} '
      '(cliente: ${event.clienteId})',
      tag: _tag,
    );

    final input = await _buildReportInput(event: event, session: session);

    AppLogger.debug(
      'Gerando relatório para sessão ${session.id} — '
      '${input.occurrences.length} ocorrência(s), '
      '${input.fotos.length} foto(s).',
      tag: _tag,
    );

    final reportId = await ref.read(reportWriterProvider).generateReport(input);

    AppLogger.debug(
      'Relatório $reportId gerado com sucesso (sessão ${session.id}).',
      tag: _tag,
    );
  }

  // ── Construção do VisitReportInput ────────────────────────────────────

  /// Mapeia [AgendaEventData] + [AgendaSessionData] para [VisitReportInput].
  ///
  /// Busca ocorrências via [IOccurrenceRead] (ADR-024) antes de montar o DTO.
  Future<VisitReportInput> _buildReportInput({
    required AgendaEventData event,
    required AgendaSessionData session,
  }) async {
    final farmName = await _placeName(
      id: event.fazendaId,
      unidentified: 'Fazenda não identificada',
      lookup: (id) async =>
          (await ref.read(iFarmLookupProvider).findById(id))?.name,
    );
    final fieldName = await _placeName(
      id: event.talhaoId,
      unidentified: 'Talhão',
      lookup: (id) async =>
          (await ref.read(iFieldLookupProvider).findById(id))?.name,
    );

    // ── Ocorrências via IOccurrenceRead (ADR-024) ─────────────────────
    final occurrences = await ref
        .read(occurrenceReadProvider)
        .getBySessionId(session.id);
    final fotos = await ref
        .read(visitPhotoReadProvider)
        .getBySessionId(session.id);

    return VisitReportInput(
      sessionId: session.id,
      clientId: event.clienteId,
      farmName: farmName,
      agronomistId: session.createdBy,
      startedAt: session.startAtReal,
      finishedAt: session.endAtReal!, // endAtReal != null garantido
      occurrences: occurrences,
      fotos: fotos,
      talhaoId: event.talhaoId,
      talhaoName: event.talhaoId == null ? null : fieldName,
    );
  }

  Future<String> _placeName({
    required String? id,
    required String unidentified,
    required Future<String?> Function(String id) lookup,
  }) async {
    final normalized = id?.trim() ?? '';
    if (normalized.isEmpty) return unidentified;
    try {
      final lookedUp = await lookup(normalized);
      return resolveVisitPlaceName(
        lookedUpName: lookedUp,
        unidentified: unidentified,
      );
    } catch (error) {
      AppLogger.warning(
        'Nome de $unidentified indisponível',
        tag: _tag,
        error: error,
      );
      return unidentified;
    }
  }
}
