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

  test('edição atualiza amostra e preserva andamento do registro vivo', () {
    final fresh = stale.copyWith(
      category: 'amostra_solo',
      amostraSolo: true,
      andamento: OccurrenceAndamento.emAtendimento.storageValue,
      amostraCodigo: 'AS-1',
      amostraColetor: 'João',
      amostraTramite: 'coletada',
      amostraAnalisesJson: '{"fase":2}',
    );
    const amostraForm = OccurrenceFormData(
      type: 'Média',
      description: 'Coleta',
      latitude: -10.25,
      longitude: -48.32,
      category: 'amostra_solo',
      amostraSolo: true,
      amostraCodigo: ' AS-2 ',
      amostraColetor: 'João',
      amostraTramite: 'laudo_pronto',
      amostraLaudoTexto: 'pH 5,8',
    );

    final edited = applyOccurrenceFormEdit(
      resolveLiveOccurrence([fresh], stale),
      amostraForm,
    );

    expect(edited.andamentoEnum, OccurrenceAndamento.emAtendimento);
    expect(edited.amostraCodigo, 'AS-2');
    expect(edited.amostraColetor, 'João');
    expect(edited.amostraTramite, 'laudo_pronto');
    expect(edited.amostraLaudoTexto, 'pH 5,8');
    expect(edited.amostraAnalisesJson, '{"fase":2}');
  });

  test('edição sem campos de amostra limpa os existentes', () {
    final fresh = stale.copyWith(
      amostraCodigo: 'AS-1',
      amostraColetor: 'João',
      amostraTramite: 'laboratorio',
      amostraLaudoTexto: 'antigo',
    );

    final edited = applyOccurrenceFormEdit(fresh, form);

    expect(edited.amostraCodigo, isNull);
    expect(edited.amostraColetor, isNull);
    expect(edited.amostraTramite, isNull);
    expect(edited.amostraLaudoTexto, isNull);
  });

  test('edição preserva field_id gravado na criação', () {
    final fresh = stale.copyWith(fieldId: 'field-1');

    final edited = applyOccurrenceFormEdit(fresh, form);

    expect(edited.fieldId, 'field-1');
    expect(Occurrence.fromMap(edited.toMap()).fieldId, 'field-1');
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
