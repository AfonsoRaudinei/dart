import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';

void main() {
  group('mergeFarmLinkedFieldSummaries', () {
    test('combina fields e drawings vinculados sem duplicar ids', () {
      const field = FarmLinkedFieldSummary(
        id: 'talhao-1',
        name: 'Talhao em fields',
        areaHa: 10,
        source: FarmLinkedFieldSource.field,
      );
      const duplicatedDrawing = FarmLinkedFieldSummary(
        id: 'talhao-1',
        name: 'Talhao duplicado em drawings',
        areaHa: 99,
        source: FarmLinkedFieldSource.drawing,
      );
      const drawing = FarmLinkedFieldSummary(
        id: 'drawing-1',
        name: 'Talhao do mapa',
        areaHa: 25.5,
        source: FarmLinkedFieldSource.drawing,
      );

      final merged = mergeFarmLinkedFieldSummaries(
        fieldSummaries: [field],
        drawingSummaries: [duplicatedDrawing, drawing],
      );

      expect(merged, hasLength(2));
      expect(merged.map((item) => item.id), ['talhao-1', 'drawing-1']);
      expect(merged.first.name, 'Talhao em fields');
      expect(totalFarmLinkedAreaHa(merged), 35.5);
    });

    test('ignora registros sem id para evitar item sem chave estável', () {
      final merged = mergeFarmLinkedFieldSummaries(
        fieldSummaries: const [
          FarmLinkedFieldSummary(
            id: '',
            name: 'Sem id',
            areaHa: 12,
            source: FarmLinkedFieldSource.field,
          ),
        ],
        drawingSummaries: const [
          FarmLinkedFieldSummary(
            id: 'drawing-1',
            name: 'Talhao do mapa',
            areaHa: 8,
            source: FarmLinkedFieldSource.drawing,
          ),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.id, 'drawing-1');
      expect(totalFarmLinkedAreaHa(merged), 8);
    });
  });
}
