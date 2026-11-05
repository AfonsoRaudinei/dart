import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_andamento.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';

void main() {
  test('fromStorage normaliza andamento desconhecido para aberta', () {
    expect(
      OccurrenceAndamento.fromStorage('xyz').storageValue,
      OccurrenceAndamento.aberta.storageValue,
    );
  });

  test('Occurrence persiste andamento e responsavel no map', () {
    final occ = Occurrence(
      id: 'id-1',
      type: 'Alta',
      description: 'Teste',
      createdAt: DateTime(2026, 11, 5),
      status: 'confirmed',
      andamento: OccurrenceAndamento.emAtendimento.storageValue,
      responsavelNome: 'Maria',
    );
    final map = occ.toMap();
    expect(map['andamento'], 'em_atendimento');
    expect(map['responsavel_nome'], 'Maria');
    final roundTrip = Occurrence.fromMap(map);
    expect(roundTrip.andamentoEnum, OccurrenceAndamento.emAtendimento);
    expect(roundTrip.responsavelNome, 'Maria');
  });

  test('resolveLiveOccurrence usa registro atualizado da lista', () {
    final seed = Occurrence(
      id: 'a',
      type: 'Alta',
      description: 'x',
      createdAt: DateTime(2026),
    );
    final updated = seed.copyWith(
      andamento: OccurrenceAndamento.emAtendimento.storageValue,
      responsavelNome: 'João',
    );
    final live = resolveLiveOccurrence([updated], seed);
    expect(live.andamentoEnum, OccurrenceAndamento.emAtendimento);
    expect(live.responsavelNome, 'João');
  });
}
