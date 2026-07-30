import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';

/// BUG-003 — Occurrences: sheet errado na criação / sync_status incorreto.
void main() {
  late FakeOccurrenceRepository fakeRepository;
  late FakeVisitSessionLookup fakeVisitLookup;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeOccurrenceRepository();
    fakeVisitLookup = FakeVisitSessionLookup();

    container = ProviderContainer(
      overrides: [
        occurrenceRepositoryProvider.overrideWithValue(fakeRepository),
        visitSessionLookupProvider.overrideWithValue(fakeVisitLookup),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BUG-003 occurrence_sheet_regression', () {
    test(
      'createOccurrence grava sync_status local sem lançar exceção',
      () async {
        fakeVisitLookup.session = null;

        final controller = container.read(occurrenceControllerProvider);

        await expectLater(
          controller.createOccurrence(
            type: 'Praga',
            description: 'Regressão sync_status',
          ),
          completes,
        );

        expect(fakeRepository.lastSaved, isNotNull);
        expect(fakeRepository.lastSaved!.syncStatus, 'local');
      },
    );

    test(
      'createOccurrence não bloqueia criação sem sessão ativa',
      () async {
        fakeVisitLookup.session = null;

        final controller = container.read(occurrenceControllerProvider);

        await controller.createOccurrence(
          type: 'Doença',
          description: 'Sem sessão ativa',
        );

        expect(fakeRepository.lastSaved, isNotNull);
        expect(fakeRepository.lastSaved!.visitSessionId, isNull);
      },
    );

    test(
      'createOccurrence herda visit_session_id quando sessão existe',
      () async {
        fakeVisitLookup.session = VisitSessionSummary(
          id: 'sess-123',
          producerId: 'producer-regression',
          status: 'active',
          startTime: DateTime(2026, 7, 30, 8),
        );

        final controller = container.read(occurrenceControllerProvider);

        await controller.createOccurrence(
          type: 'Nutricional',
          description: 'Com sessão ativa',
        );

        expect(fakeRepository.lastSaved, isNotNull);
        expect(fakeRepository.lastSaved!.visitSessionId, 'sess-123');
      },
    );

    test(
      'OccurrenceCreationSheet é usado no mapa, não MapOccurrenceSheet legado',
      () {
        final mapBottomSheetSource = StringBuffer();
        for (final path in [
          'lib/ui/components/map/map_bottom_sheet.dart',
          'lib/ui/screens/private_map_screen.dart',
        ]) {
          mapBottomSheetSource.write(File(path).readAsStringSync());
        }
        final source = mapBottomSheetSource.toString();

        expect(source.contains('OccurrenceCreationSheet'), isTrue);
        expect(source.contains('MapOccurrenceSheet'), isFalse);
      },
    );
  });
}

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

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async {
    final active = await getActiveSession();
    if (active != null && active.id == sessionId) return active;
    return null;
  }
}
