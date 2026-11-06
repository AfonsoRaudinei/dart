import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_andamento.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';

class _FakeByIdRepository extends OccurrenceRepository {
  _FakeByIdRepository(this.stored);

  final Occurrence? stored;
  final List<String> requestedIds = [];

  @override
  Future<Occurrence?> getById(String id) async {
    requestedIds.add(id);
    return stored;
  }

  final List<Occurrence> updates = [];

  @override
  Future<void> updateOccurrence(Occurrence occurrence) async {
    updates.add(occurrence);
  }
}

void main() {
  final seed = Occurrence(
    id: 'occ-1',
    type: 'Média',
    description: 'Snapshot',
    createdAt: DateTime(2026, 11, 5),
    status: 'confirmed',
    andamento: OccurrenceAndamento.aberta.storageValue,
  );

  test('devolve a versão do repositório (andamento resolvida)', () async {
    final stored = seed.copyWith(
      andamento: OccurrenceAndamento.resolvida.storageValue,
    );
    final repo = _FakeByIdRepository(stored);

    final live = await loadLiveOccurrence(repo, seed);

    expect(repo.requestedIds, ['occ-1']);
    expect(live.andamentoEnum, OccurrenceAndamento.resolvida);
  });

  test('repositório sem registro devolve o seed', () async {
    final repo = _FakeByIdRepository(null);

    final live = await loadLiveOccurrence(repo, seed);

    expect(identical(live, seed), isTrue);
  });

  group('isOccurrenceDeleted', () {
    test('ativa não é excluída', () {
      expect(isOccurrenceDeleted(seed), isFalse);
    });

    test('deleted_local é excluída', () {
      expect(
        isOccurrenceDeleted(seed.copyWith(syncStatus: 'deleted_local')),
        isTrue,
      );
    });

    test('deleted legado é excluída', () {
      expect(isOccurrenceDeleted(seed.copyWith(syncStatus: 'deleted')), isTrue);
    });

    test('deletedAt preenchido é excluída', () {
      expect(
        isOccurrenceDeleted(seed.copyWith(deletedAt: '2026-11-06T12:00:00Z')),
        isTrue,
      );
    });
  });

  group('updateLiveOccurrence', () {
    test('tombstone no repositório não grava', () async {
      final repo = _FakeByIdRepository(
        seed.copyWith(
          syncStatus: 'deleted_local',
          deletedAt: '2026-11-06T12:00:00Z',
        ),
      );

      final saved = await updateLiveOccurrence(
        repo,
        seed,
        (live) => live.copyWith(description: 'Editada'),
      );

      expect(saved, isFalse);
      expect(repo.updates, isEmpty);
    });

    test('ativa grava a partir do registro vivo', () async {
      final stored = seed.copyWith(
        andamento: OccurrenceAndamento.resolvida.storageValue,
      );
      final repo = _FakeByIdRepository(stored);

      final saved = await updateLiveOccurrence(
        repo,
        seed,
        (live) => live.copyWith(description: 'Editada'),
      );

      expect(saved, isTrue);
      expect(repo.updates, hasLength(1));
      expect(repo.updates.single.description, 'Editada');
      expect(repo.updates.single.andamentoEnum, OccurrenceAndamento.resolvida);
    });
  });
}
