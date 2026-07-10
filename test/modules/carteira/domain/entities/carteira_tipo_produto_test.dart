import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_tipo_produto.dart';

void main() {
  group('CarteiraTipoProduto', () {
    test('codigoFromLabel gera slug estável', () {
      expect(
        CarteiraTipoProduto.codigoFromLabel('Litros/ha'),
        'litros_ha',
      );
      expect(
        CarteiraTipoProduto.codigoFromLabel('  Sc / ha  '),
        'sc_ha',
      );
    });
  });
}
