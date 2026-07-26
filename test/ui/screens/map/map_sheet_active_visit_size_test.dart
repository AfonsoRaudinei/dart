import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/screens/map/controllers/map_sheet_controller.dart';

void main() {
  group('resolveCheckInSheetSizes', () {
    test('visita ativa usa detent compacto (padrão SoloForte)', () {
      final sizes = resolveCheckInSheetSizes(isActiveVisit: true);
      expect(sizes.initial, 0.34);
      expect(sizes.max, lessThan(0.5));
      expect(sizes.snaps, [0.34]);
    });

    test('iniciar visita mantém altura para formulário', () {
      final sizes = resolveCheckInSheetSizes(isActiveVisit: false);
      expect(sizes.initial, 0.6);
      expect(sizes.max, 0.92);
      expect(sizes.snaps, [0.6, 0.92]);
    });

    test('constante de reabertura após chegada está definida', () {
      expect(kVisitStartedSheetResult, 'visit_started');
    });
  });
}
