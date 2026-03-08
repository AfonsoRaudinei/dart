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

  @override
  Future<VisitSessionSummary?> getActiveSession() async => session;
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
      fakeVisitLookup.session = const VisitSessionSummary(
        id: 'visit-active-1',
        status: 'active',
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
    },
  );
}
