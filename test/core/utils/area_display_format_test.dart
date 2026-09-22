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
    test('omits area when zero or negative', () {
      expect(
        buildTalhaoMapLabel('Talhão A', 0, AreaDisplayUnit.hectare),
        'Talhão A',
      );
      expect(
        buildTalhaoMapLabel('Talhão B', -1, AreaDisplayUnit.hectare),
        'Talhão B',
      );
    });

    test('includes name and formatted area on separate lines', () {
      expect(
        buildTalhaoMapLabel('North', 2, AreaDisplayUnit.hectare),
        'North\n2.000 ha',
      );
    });
  });
}
