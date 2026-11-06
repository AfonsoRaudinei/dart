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
}
