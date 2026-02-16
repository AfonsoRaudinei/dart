import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/visit_session.dart';
import '../../data/repositories/visit_repository.dart';
import '../../../consultoria/occurrences/data/occurrence_repository.dart';
import '../../../consultoria/reports/data/sqlite_report_repository.dart';
import '../../../consultoria/reports/domain/report_model.dart';
import '../../../consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../consultoria/agenda/data/repositories/agenda_repository.dart';
import '../../../consultoria/agenda/presentation/controllers/agenda_controller.dart';
import '../../../consultoria/agenda/domain/models/agenda_event.dart';
import 'package:uuid/uuid.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

final sqliteReportRepositoryProvider = Provider<SQLiteReportRepository>((ref) {
  return SQLiteReportRepository();
});

final visitControllerProvider =
    StateNotifierProvider<VisitController, AsyncValue<VisitSession?>>((ref) {
      return VisitController(
        ref.watch(visitRepositoryProvider),
        ref.watch(occurrenceRepositoryProvider),
        ref.watch(sqliteReportRepositoryProvider),
        ref.watch(agendaRepositoryProvider),
      );
    });

class VisitController extends StateNotifier<AsyncValue<VisitSession?>> {
  final VisitRepository _repository;
  final OccurrenceRepository _occurrenceRepository;
  final SQLiteReportRepository _reportRepository;
  final AgendaRepository _agendaRepository;

  VisitController(
    this._repository,
    this._occurrenceRepository,
    this._reportRepository,
    this._agendaRepository,
  ) : super(const AsyncValue.loading()) {
    checkActiveSession();
  }

  /// Decide a ação do Check-in baseado no estado atual.
  /// Centraliza a lógica de negócio fora do overlay.
  void handleCheckInTap({
    required void Function() onShowStartSheet,
    required void Function() onShowEndConfirmation,
  }) {
    if (state.isLoading) return;

    final isActive = state.valueOrNull != null;

    if (isActive) {
      onShowEndConfirmation();
    } else {
      onShowStartSheet();
    }
  }

  Future<void> checkActiveSession() async {
    try {
      final session = await _repository.getActiveSession();
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSession(
    String producerId,
    String areaId,
    String activityType,
    double lat,
    double long, {
    String? agendaEventId,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Check if already active
      final existing = await _repository.getActiveSession();
      if (existing != null) {
        throw Exception('Já existe uma sessão ativa.');
      }

      final now = DateTime.now();
      final newSession = VisitSession(
        id: const Uuid().v4(),
        producerId: producerId,
        areaId: areaId,
        activityType: activityType,
        startTime: now,
        initialLat: lat,
        initialLong: long,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      await _repository.saveSession(newSession);

      // Agenda Linkage
      if (agendaEventId != null) {
        final event = await _agendaRepository.getEvent(agendaEventId);
        if (event != null) {
          await _agendaRepository.saveEvent(
            event.copyWith(
              visitSessionId: newSession.id,
              status: AgendaStatus.in_progress,
            ),
          );
        }
      }

      state = AsyncValue.data(newSession);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession() async {
    final currentSession = state.value;
    if (currentSession == null) return;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // 1. Fetch Occurrences linked to session
      final occurrences = await _occurrenceRepository.getOccurrencesBySession(
        currentSession.id,
      );

      // 2. Generate Report Content (Snapshot)
      final duration = now.difference(currentSession.startTime);
      final reportContent =
          '''
Relatório Automático de Visita
------------------------------
Produtor ID: ${currentSession.producerId}
Área ID: ${currentSession.areaId}
Atividade: ${currentSession.activityType}
Início: ${currentSession.startTime}
Fim: $now
Duração: ${duration.inMinutes} minutos
Ocorrências: ${occurrences.length}

Resumo de Ocorrências:
${occurrences.map((o) => '- [${o.type}] ${o.description}').join('\n')}
''';

      final report = Report(
        id: const Uuid().v4(),
        title: 'Visita Técnica - ${currentSession.activityType}',
        type: ReportType.semanal, // Defaulting to simple report type for now
        clientId: currentSession.producerId,
        startDate: currentSession.startTime,
        endDate: now,
        content: reportContent,
        createdAt: now,
        author: 'Consultor (Auto)', // Should get current user
        observations: 'Gerado automaticamente ao encerrar sessão.',
      );

      // 3. Save Report
      await _reportRepository.saveReport(report, currentSession.id);

      // 4. Update Agenda Event
      final linkedEvent = await _agendaRepository.getEventBySessionId(
        currentSession.id,
      );
      if (linkedEvent != null) {
        await _agendaRepository.saveEvent(
          linkedEvent.copyWith(status: AgendaStatus.realized, realizedAt: now),
        );
      }

      // 5. End Session
      await _repository.endSession(currentSession.id, now);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
