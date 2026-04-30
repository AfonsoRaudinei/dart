// test/modules/visitas/visit_controller_test.dart
//
// Testes de migração ADR-024 — visit_controller.dart
// Valida que o controller funciona com contratos neutros
// sem nenhuma dependência de consultoria/ ou agenda/.
//
// Fakes injetados via ProviderContainer.overrides — padrão ADR-020.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';

// ── Fake 1: VisitRepository  ────────────────────────────────────
class FakeVisitRepository extends VisitRepository {
  VisitSession? _activeSession;
  VisitSession? lastSaved;
  String? lastEndedId;
  String? lastUpdatedAreaId;

  void seedActiveSession(VisitSession session) => _activeSession = session;

  @override
  Future<VisitSession?> getActiveSession() async => _activeSession;

  @override
  Future<void> saveSession(VisitSession session) async {
    lastSaved = session;
    _activeSession = session;
  }

  @override
  Future<void> endSession(String sessionId, DateTime endTime) async {
    lastEndedId = sessionId;
    _activeSession = null;
  }

  @override
  Future<void> updateArea(String sessionId, String newAreaId) async {
    lastUpdatedAreaId = newAreaId;
  }
}

// ── Fake 2: IAgendaSessionBridge ───────────────────────────────────────────
class FakeAgendaSessionBridge implements IAgendaSessionBridge {
  String? lastLinkedEventId;
  String? lastLinkedSessionId;
  String? lastDoneSessionId;

  @override
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  }) async {
    lastLinkedEventId = agendaEventId;
    lastLinkedSessionId = sessionId;
  }

  @override
  Future<void> markEventAsDone(String sessionId) async {
    lastDoneSessionId = sessionId;
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────
VisitSession _makeSession({String status = 'active'}) => VisitSession(
      id: 'session-test-001',
      producerId: 'producer-001',
      areaId: 'area-001',
      activityType: 'Visita técnica',
      startTime: DateTime(2026, 4, 1, 8, 0),
      initialLat: -15.0,
      initialLong: -47.0,
      status: status,
      createdAt: DateTime(2026, 4, 1, 8, 0),
      updatedAt: DateTime(2026, 4, 1, 8, 0),
    );

// ── Testes ──────────────────────────────────────────────────────────────────
void main() {
  late FakeVisitRepository fakeVisitRepo;
  late FakeAgendaSessionBridge fakeAgendaBridge;
  late ProviderContainer container;

  setUp(() {
    fakeVisitRepo = FakeVisitRepository();
    fakeAgendaBridge = FakeAgendaSessionBridge();

    container = ProviderContainer(
      overrides: [
        visitRepositoryProvider.overrideWithValue(fakeVisitRepo),
        agendaSessionBridgeProvider.overrideWithValue(fakeAgendaBridge),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('VisitController — contratos neutros ADR-024', () {
    test('startSession cria sessão quando não há sessão ativa', () async {
      final controller = container.read(visitControllerProvider.notifier);

      await controller.startSession(
        'producer-001',
        'area-001',
        'Visita técnica',
        -15.0,
        -47.0,
      );

      expect(fakeVisitRepo.lastSaved, isNotNull);
      expect(fakeVisitRepo.lastSaved!.producerId, equals('producer-001'));
      final state = container.read(visitControllerProvider);
      expect(state.valueOrNull, isNotNull);
      expect(state.valueOrNull!.areaId, equals('area-001'));
    });

    test('startSession falha com exceção quando sessão já está ativa', () async {
      fakeVisitRepo.seedActiveSession(_makeSession());
      await Future.delayed(Duration.zero);

      final controller = container.read(visitControllerProvider.notifier);

      await controller.startSession(
        'producer-002',
        'area-002',
        'Consulta',
        -15.0,
        -47.0,
      );

      final state = container.read(visitControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error.toString(),
        contains('Já existe uma sessão ativa'),
      );
    });

    test('endSession encerra sessão', () async {
      fakeVisitRepo.seedActiveSession(_makeSession());
      await Future.delayed(Duration.zero); 

      final controller = container.read(visitControllerProvider.notifier);

      await controller.endSession();

      expect(fakeVisitRepo.lastEndedId, equals('session-test-001'));
      expect(fakeAgendaBridge.lastDoneSessionId, equals('session-test-001'));
    });
  });
}
