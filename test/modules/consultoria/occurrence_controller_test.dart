import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';

class FakeOccurrenceRepository extends OccurrenceRepository {
  Occurrence? lastSaved;

  @override
  Future<void> saveOccurrence(Occurrence occurrence) async {
    lastSaved = occurrence;
  }
}

class FakeVisitSessionLookup implements IVisitSessionLookup {
  VisitSessionSummary? session;
  Object? throwOnGetActive;

  @override
  Future<VisitSessionSummary?> getActiveSession() async {
    if (throwOnGetActive != null) throw throwOnGetActive!;
    return session;
  }

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async {
    final active = await getActiveSession();
    if (active != null && active.id == sessionId) return active;
    return null;
  }
}

void main() {
  late FakeOccurrenceRepository fakeOccurrenceRepository;
  late FakeVisitSessionLookup fakeVisitLookup;
  late ProviderContainer container;

  setUp(() {
    fakeOccurrenceRepository = FakeOccurrenceRepository();
    fakeVisitLookup = FakeVisitSessionLookup();

    container = ProviderContainer(
      overrides: [
        occurrenceRepositoryProvider.overrideWithValue(
          fakeOccurrenceRepository,
        ),
        visitSessionLookupProvider.overrideWithValue(fakeVisitLookup),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'createOccurrence vincula visitSessionId quando sessão ativa existe',
    () async {
      fakeVisitLookup.session = VisitSessionSummary(
        id: 'visit-active-1',
        producerId: 'producer-test-1',
        status: 'active',
        startTime: DateTime(2025, 1, 1, 8, 0),
      );

      final controller = container.read(occurrenceControllerProvider);

      await controller.createOccurrence(
        type: 'Praga',
        description: 'Lagarta observada',
      );

      expect(fakeOccurrenceRepository.lastSaved, isNotNull);
      expect(
        fakeOccurrenceRepository.lastSaved!.visitSessionId,
        'visit-active-1',
      );
      expect(fakeOccurrenceRepository.lastSaved!.clientId, 'producer-test-1');
    },
  );

  test(
    'createOccurrence mantém visitSessionId nulo quando não há sessão ativa',
    () async {
      fakeVisitLookup.session = null;

      final controller = container.read(occurrenceControllerProvider);

      await controller.createOccurrence(
        type: 'Doença',
        description: 'Sintomas iniciais',
      );

      expect(fakeOccurrenceRepository.lastSaved, isNotNull);
      expect(fakeOccurrenceRepository.lastSaved!.visitSessionId, isNull);
      expect(fakeOccurrenceRepository.lastSaved!.syncStatus, 'pending_sync');
    },
  );

  test(
    'createOccurrence grava localmente mesmo se lookup de visita falhar',
    () async {
      fakeVisitLookup.throwOnGetActive = StateError('offline');

      final controller = container.read(occurrenceControllerProvider);

      await controller.createOccurrence(
        type: 'Insetos',
        description: 'Registro offline',
        lat: -15.1,
        long: -47.2,
      );

      expect(fakeOccurrenceRepository.lastSaved, isNotNull);
      expect(fakeOccurrenceRepository.lastSaved!.visitSessionId, isNull);
      expect(fakeOccurrenceRepository.lastSaved!.lat, -15.1);
      expect(fakeOccurrenceRepository.lastSaved!.syncStatus, 'pending_sync');
    },
  );
}
