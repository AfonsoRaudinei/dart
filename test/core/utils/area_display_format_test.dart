import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';

void main() {
  group('formatAreaFromHectares', () {
    test('hectare uses 3 decimal places', () {
      expect(
        formatAreaFromHectares(12.5, AreaDisplayUnit.hectare),
        '12.500 ha',
      );
    });

    test('square meter converts from hectares', () {
      expect(
        formatAreaFromHectares(1, AreaDisplayUnit.squareMeter),
        '10000 m²',
      );
    });

    test('alqueire uses GO/MG factor 4.84', () {
      expect(
        formatAreaFromHectares(4.84, AreaDisplayUnit.alqueire),
        '1.000 alq GO/MG',
      );
    });
  });

  group('buildTalhaoMapLabel', () {
    test('default is name plus cultura and material', () {
      expect(
        buildTalhaoMapLabel(
          'Th 10',
          95,
          AreaDisplayUnit.hectare,
          cultura: 'Soja',
          material: 'Olimpo RR',
        ),
        'Th 10\nSoja · Olimpo RR',
      );
    });

    test('omits area by default even when areaHa > 0', () {
      expect(
        buildTalhaoMapLabel('Talhão A', 12.5, AreaDisplayUnit.hectare),
        'Talhão A',
      );
    });

    test('includes short area when showArea is true', () {
      expect(
        buildTalhaoMapLabel(
          'South',
          4.84,
          AreaDisplayUnit.alqueire,
          prefs: const TalhaoMapLabelPrefs(showCultura: false, showArea: true),
        ),
        'South\n1.000 alq',
      );
    });

    test('cultura only when name is hidden', () {
      expect(
        buildTalhaoMapLabel(
          'Th 10',
          10,
          AreaDisplayUnit.hectare,
          prefs: const TalhaoMapLabelPrefs(showName: false),
          cultura: 'soja',
          material: 'Olimpo RR',
        ),
        'Soja · Olimpo RR',
      );
    });

    test('hidden prefs return empty string', () {
      expect(
        buildTalhaoMapLabel(
          'Talhão Norte',
          12.34,
          AreaDisplayUnit.hectare,
          prefs: TalhaoMapLabelPrefs.hidden,
          cultura: 'Soja',
        ),
        '',
      );
    });

    test('formatCulturaMaterialLine joins crop and seed', () {
      expect(
        formatCulturaMaterialLine('soja', 'Olimpo RR'),
        'Soja · Olimpo RR',
      );
      expect(formatCulturaMaterialLine('Milho', null), 'Milho');
      expect(formatCulturaMaterialLine(null, 'Olimpo RR'), 'Olimpo RR');
    });

    test('uses short unit suffixes for map labels only', () {
      expect(
        formatAreaFromHectares(4.84, AreaDisplayUnit.alqueire),
        '1.000 alq GO/MG',
      );
    });
  });
}
