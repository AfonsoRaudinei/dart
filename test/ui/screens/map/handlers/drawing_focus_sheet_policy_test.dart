import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/screens/map/handlers/drawing_focus_sheet_policy.dart';

void main() {
  group('shouldOpenDrawSheetOnDrawingFocus', () {
    const cases = <({
      bool edit,
      bool union,
      bool completo,
      bool expected,
      String label,
    })>[
      (
        edit: false,
        union: false,
        completo: false,
        expected: false,
        label: 'cliente Abrir no mapa (compacto)',
      ),
      (
        edit: true,
        union: false,
        completo: false,
        expected: false,
        label: 'editar geometria',
      ),
      (
        edit: false,
        union: true,
        completo: false,
        expected: true,
        label: 'união abre Ferramentas de Desenho',
      ),
      (
        edit: false,
        union: false,
        completo: true,
        expected: true,
        label: 'ferramentas=completo abre sheet',
      ),
      (
        edit: false,
        union: true,
        completo: true,
        expected: true,
        label: 'união + completo abre sheet',
      ),
      (
        edit: true,
        union: true,
        completo: true,
        expected: false,
        label: 'edit vence union e completo',
      ),
    ];

    for (final c in cases) {
      test(c.label, () {
        expect(
          shouldOpenDrawSheetOnDrawingFocus(
            edit: c.edit,
            union: c.union,
            ferramentasCompleto: c.completo,
          ),
          c.expected,
        );
      });
    }
  });
}
