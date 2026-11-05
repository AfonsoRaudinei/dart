import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_amostra_solo.dart';

void main() {
  group('occurrenceIsAmostraSolo', () {
    test('detecta flag e categoria', () {
      expect(
        occurrenceIsAmostraSolo(
          Occurrence(
            id: '1',
            type: 'Média',
            description: '',
            createdAt: DateTime.utc(2026),
            amostraSolo: true,
          ),
        ),
        isTrue,
      );
      expect(
        occurrenceIsAmostraSolo(
          Occurrence(
            id: '2',
            type: 'Média',
            description: '',
            createdAt: DateTime.utc(2026),
            category: 'amostra_solo',
          ),
        ),
        isTrue,
      );
    });
  });

  group('OccurrenceAmostraTramite', () {
    test('round-trip storage', () {
      for (final step in OccurrenceAmostraTramite.values) {
        expect(
          OccurrenceAmostraTramite.fromStorage(step.storageValue),
          step,
        );
      }
    });
  });

  group('formatAmostraTramiteLinha', () {
    test('monta linha com laudo quando pronto', () {
      final line = formatAmostraTramiteLinha(
        codigo: 'AS-01',
        coletor: 'Técnico A',
        tramite: OccurrenceAmostraTramite.laudoPronto,
        laudoTexto: 'pH 5,8 · V% adequado',
      );
      expect(line, contains('AS-01'));
      expect(line, contains('Coletor: Técnico A'));
      expect(line, contains('Laudo pronto'));
      expect(line, contains('pH 5,8'));
    });
  });

  group('Occurrence map v49', () {
    test('persiste campos de amostra', () {
      final occurrence = Occurrence(
        id: 'occ-amostra',
        type: 'Média',
        description: 'Coleta',
        createdAt: DateTime.utc(2026, 11, 5),
        category: 'amostra_solo',
        amostraSolo: true,
        amostraCodigo: 'AS-2026-014',
        amostraColetor: 'Equipe campo',
        amostraTramite: 'laboratorio',
        amostraLaudoTexto: null,
        amostraAnalisesJson: '{"fase":2}',
      );

      final map = occurrence.toMap();
      expect(map['amostra_codigo'], 'AS-2026-014');
      expect(map['amostra_tramite'], 'laboratorio');
      expect(map['amostra_analises_json'], '{"fase":2}');

      final restored = Occurrence.fromMap(map);
      expect(restored.amostraCodigo, 'AS-2026-014');
      expect(restored.amostraTramite, 'laboratorio');
    });
  });
}
