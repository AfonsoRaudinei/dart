// lib/modules/visitas/presentation/controllers/visit_controller.dart
// ADR-024: imports de consultoria/ e agenda/ removidos — substituídos por contratos neutros.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/visit_route_stop.dart';
import '../../domain/models/visit_session.dart';
import '../../domain/visit_route_advance.dart';
import '../../domain/visit_route_notification.dart';
import '../../data/repositories/visit_repository.dart';
import '../visit_route_notification_port.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

final visitRouteNotificationPortProvider = Provider<VisitRouteNotificationPort>(
  (ref) => NotificationServiceVisitRoutePort(),
);

final visitControllerProvider =
    StateNotifierProvider<VisitController, AsyncValue<VisitSession?>>((ref) {
      return VisitController(
        ref.watch(visitRepositoryProvider),
        ref.watch(
          agendaSessionBridgeProvider,
        ), // IAgendaSessionBridge — ADR-024
        notifications: ref.watch(visitRouteNotificationPortProvider),
      );
    });

// ignore: unused_element
final _visitLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'visitControllerProvider',
    invalidate: (ref) => ref.invalidate(visitControllerProvider),
  );
  return true;
}();

class VisitController extends StateNotifier<AsyncValue<VisitSession?>> {
  final VisitRepository _repository;
  final IAgendaSessionBridge _agendaBridge; // ADR-024
  final VisitRouteNotificationPort _notifications;

  VisitController(
    this._repository,
    this._agendaBridge, {
    VisitRouteNotificationPort? notifications,
  }) : _notifications = notifications ?? NotificationServiceVisitRoutePort(),
       super(const AsyncValue.loading()) {
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
      } else {
        // ADR-060: check-in no mapa entra na agenda. Falha não cancela a visita.
        try {
          await _agendaBridge.registerFieldCheckIn(
            _checkInOf(newSession),
          );
        } catch (error) {
          AppLogger.warning(
            'Falha ao registrar check-in na agenda',
            tag: 'VisitController',
            error: error,
          );
        }
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
      await _syncPlace(
        currentSession.id,
        farmId: newFarmId,
        clearArea: true,
      );
      state = AsyncValue.data(
        currentSession.copyWith(
          farmId: newFarmId,
          clearAreaId: true,
          clearRoute: true,
        ),
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
      await _syncPlace(
        currentSession.id,
        farmId: farmId,
        areaId: newAreaId,
      );
      state = AsyncValue.data(
        currentSession.copyWith(
          areaId: newAreaId,
          farmId: farmId,
          clearRoute: true,
        ),
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

      // Agenda: registra de novo se o check-in não conseguiu, depois conclui.
      // A falha aqui não impede encerrar a sessão de visita (ADR-060).
      try {
        await _agendaBridge.registerFieldCheckIn(_checkInOf(currentSession));
        await _agendaBridge.closeFieldVisit(currentSession.id);
      } catch (error) {
        AppLogger.warning(
          'Falha ao concluir a visita na agenda',
          tag: 'VisitController',
          error: error,
        );
      }

      await _repository.endSession(currentSession.id, now);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  FieldVisitCheckIn _checkInOf(VisitSession session) {
    return FieldVisitCheckIn(
      sessionId: session.id,
      clientId: session.producerId,
      farmId: session.farmId,
      areaId: session.areaId,
      activityType: session.activityType,
      startTime: session.startTime,
      latitude: session.initialLat,
      longitude: session.initialLong,
      endTime: session.endTime,
    );
  }

  Future<void> _syncPlace(
    String sessionId, {
    String? farmId,
    String? areaId,
    bool clearArea = false,
  }) async {
    try {
      await _agendaBridge.updateFieldVisitPlace(
        sessionId: sessionId,
        farmId: farmId,
        areaId: areaId,
        clearArea: clearArea,
      );
    } catch (error) {
      AppLogger.warning(
        'Falha ao atualizar fazenda ou talhão na agenda',
        tag: 'VisitController',
        error: error,
      );
    }
  }

  /// Grava paradas geradas dentro do talhão. Não marca a visita para sync.
  Future<void> saveSuggestedRoute(List<VisitRouteStop> stops) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null || stops.isEmpty) return;
    final json = VisitRouteStop.encodeList(stops);
    final index = stops.first.index;
    try {
      await _repository.saveRouteState(
        currentSession.id,
        routeStopsJson: json,
        routeCurrentIndex: index,
      );
      state = AsyncValue.data(
        currentSession.copyWithRoute(
          routeStopsJson: json,
          routeCurrentIndex: index,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearSuggestedRoute() async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;
    try {
      await _repository.saveRouteState(
        currentSession.id,
        routeStopsJson: null,
        routeCurrentIndex: null,
      );
      state = AsyncValue.data(
        currentSession.copyWithRoute(
          routeStopsJson: null,
          routeCurrentIndex: null,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Conclusão da ocorrência na parada atual: marca feita e avisa a próxima.
  ///
  /// A notificação é local e permanece na bandeja se o usuário bloquear a
  /// tela em seguida. O payload abre `/map?modo=foco` na próxima parada.
  Future<void> completeCurrentStop({String? occurrenceId}) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;
    final advance = advanceVisitRoute(
      stops: currentSession.routeStops,
      currentIndex: currentSession.routeCurrentIndex,
      occurrenceId: occurrenceId,
    );
    if (advance == null) return;

    final json = VisitRouteStop.encodeList(advance.stops);
    try {
      await _repository.saveRouteState(
        currentSession.id,
        routeStopsJson: json,
        routeCurrentIndex: advance.currentIndex,
      );
      state = AsyncValue.data(
        currentSession.copyWithRoute(
          routeStopsJson: json,
          routeCurrentIndex: advance.currentIndex,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return;
    }

    try {
      final next = advance.next;
      final sent = next != null
          ? await _notifications.showNextStop(
              index: next.index,
              total: advance.stops.length,
              payload: visitRouteMapFocusLocationFor(next),
            )
          : await _notifications.showRouteCompleted(
              total: advance.stops.length,
            );
      if (!sent) {
        AppLogger.warning(
          'aviso não enviado: sem permissão',
          tag: 'VisitRoute',
        );
      }
    } catch (error) {
      AppLogger.warning(
        'Falha ao notificar a próxima parada',
        tag: 'VisitRoute',
        error: error,
      );
    }
  }
}
