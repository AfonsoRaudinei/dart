import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_andamento.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

void main() {
  final stale = Occurrence(
    id: 'occ-1',
    type: 'Média',
    description: 'Antiga',
    createdAt: DateTime(2026, 11, 5),
    status: 'confirmed',
  );
  const form = OccurrenceFormData(
    type: 'Alta',
    description: 'Editada',
    latitude: -10.25,
    longitude: -48.32,
  );

  test('edição sobre registro vivo preserva andamento e responsável', () {
    final fresh = stale.copyWith(
      andamento: OccurrenceAndamento.emAtendimento.storageValue,
      responsavelNome: 'Maria',
    );
    final current = resolveLiveOccurrence([fresh], stale);

    final edited = applyOccurrenceFormEdit(current, form);

    expect(edited.andamentoEnum, OccurrenceAndamento.emAtendimento);
    expect(edited.responsavelNome, 'Maria');
    expect(edited.status, 'confirmed');
    expect(edited.type, 'Alta');
    expect(edited.description, 'Editada');
    expect(edited.lat, -10.25);
    expect(edited.long, -48.32);
  });

  test('sem lista carregada usa o snapshot recebido', () {
    final edited = applyOccurrenceFormEdit(
      resolveLiveOccurrence(null, stale),
      form,
    );
    expect(edited.id, 'occ-1');
    expect(edited.description, 'Editada');
  });
}
