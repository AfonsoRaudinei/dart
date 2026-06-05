// lib/modules/visitas/presentation/controllers/visit_controller.dart
// ADR-024: imports de consultoria/ e agenda/ removidos — substituídos por contratos neutros.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/visit_session.dart';
import '../../data/repositories/visit_repository.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:uuid/uuid.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

final visitControllerProvider =
    StateNotifierProvider<VisitController, AsyncValue<VisitSession?>>((ref) {
      return VisitController(
        ref.watch(visitRepositoryProvider),
        ref.watch(
          agendaSessionBridgeProvider,
        ), // IAgendaSessionBridge — ADR-024
      );
    });

class VisitController extends StateNotifier<AsyncValue<VisitSession?>> {
  final VisitRepository _repository;
  final IAgendaSessionBridge _agendaBridge; // ADR-024

  VisitController(this._repository, this._agendaBridge)
    : super(const AsyncValue.loading()) {
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
    String? areaId,
    String? activityType,
    double lat,
    double long, {
    String? farmId,
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
        farmId: farmId,
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

      // Agenda Linkage — via contrato neutro IAgendaSessionBridge (ADR-024)
      if (agendaEventId != null) {
        await _agendaBridge.linkSessionToEvent(
          agendaEventId: agendaEventId,
          sessionId: newSession.id,
        );
      }

      state = AsyncValue.data(newSession);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Atualiza a fazenda e limpa o talhão anterior sem encerrar a sessão.
  Future<void> updateFarm(String newFarmId) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;
    try {
      await _repository.updateFarm(currentSession.id, newFarmId);
      state = AsyncValue.data(
        currentSession.copyWith(farmId: newFarmId, clearAreaId: true),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Atualiza o talhão da visita ativa sem encerrar a sessão.
  Future<void> updateArea(String newAreaId, {String? farmId}) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;
    try {
      await _repository.updateArea(
        currentSession.id,
        newAreaId,
        farmId: farmId,
      );
      state = AsyncValue.data(
        currentSession.copyWith(areaId: newAreaId, farmId: farmId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession() async {
    // Bug fix: state.valueOrNull pode ser null se state for AsyncLoading/AsyncError
    // (ex: após restart do app). Fallback para SQLite garante que a sessão ativa
    // seja encontrada mesmo com estado em memória desatualizado.
    VisitSession? currentSession = state.valueOrNull;
    currentSession ??= await _repository.getActiveSession();
    if (currentSession == null) return;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // 1. Fetch Occurrences — via contrato neutro IOccurrenceRead (ADR-024)
      // 4. Update Agenda Event — via contrato neutro IAgendaSessionBridge (ADR-024)
      await _agendaBridge.markEventAsDone(currentSession.id);

      // 5. End Session
      await _repository.endSession(currentSession.id, now);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
