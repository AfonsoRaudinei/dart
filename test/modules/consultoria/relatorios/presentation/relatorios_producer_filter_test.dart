import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/relatorios_page.dart';

void main() {
  group('resolveRelatoriosProducerClientId', () {
    const ids = ['a', 'b'];

    test('prioriza seleção explícita', () {
      expect(
        resolveRelatoriosProducerClientId(
          selectedClientId: 'b',
          routeClientId: 'a',
          producerIds: ids,
        ),
        'b',
      );
    });

    test('usa rota quando não há seleção', () {
      expect(
        resolveRelatoriosProducerClientId(
          selectedClientId: null,
          routeClientId: 'a',
          producerIds: ids,
        ),
        'a',
      );
    });

    test('único produtor é auto-selecionado', () {
      expect(
        resolveRelatoriosProducerClientId(
          selectedClientId: null,
          routeClientId: null,
          producerIds: const ['solo'],
        ),
        'solo',
      );
    });

    test('vários produtores sem escolha retorna null', () {
      expect(
        resolveRelatoriosProducerClientId(
          selectedClientId: null,
          routeClientId: null,
          producerIds: ids,
        ),
        isNull,
      );
    });
  });
}
