import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/selected_talhao_card.dart';

void main() {
  group('TalhaoSummary.subtitle', () {
    test('area + cultura', () {
      const s = TalhaoSummary(name: 'T1', areaHa: 12.5, crop: 'Soja');
      expect(s.subtitle, '12.5 ha · Soja');
    });

    test('somente area', () {
      const s = TalhaoSummary(name: 'T1', areaHa: 100, crop: '  ');
      expect(s.subtitle, '100 ha');
    });

    test('somente cultura', () {
      const s = TalhaoSummary(name: 'T1', areaHa: 0, crop: 'Milho');
      expect(s.subtitle, 'Milho');
    });

    test('fallback', () {
      const s = TalhaoSummary(name: 'T1', areaHa: 0, crop: '');
      expect(s.subtitle, 'Talhão selecionado');
    });
  });
}
