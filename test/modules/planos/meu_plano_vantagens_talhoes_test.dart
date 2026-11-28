import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/data/services/loja_compra_gateway.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/presentation/meu_plano_vantagens.dart';

void main() {
  const vitrineVazia = LojaVitrine(disponivel: false, produtos: []);

  group('vantagemTalhoesSincronizados', () {
    test('grátis — somente no aparelho', () {
      expect(
        MeuPlanoMenu.gratis.vantagemTalhoesSincronizados,
        contains('sincronização na nuvem é exclusiva dos planos pagos'),
      );
    });

    test('bronze e prata — número vem do PlanoTipo', () {
      final bronze = PlanoTipo.bronze.limiteTalhoesSincronizados!;
      final prata = PlanoTipo.prata.limiteTalhoesSincronizados!;
      expect(
        MeuPlanoMenu.bronze.vantagemTalhoesSincronizados,
        'Sincronize e salve na nuvem até $bronze talhões desenhados.',
      );
      expect(
        MeuPlanoMenu.prata.vantagemTalhoesSincronizados,
        'Sincronize e salve na nuvem até $prata talhões desenhados.',
      );
    });

    test('ouro — sem limite, sem número', () {
      expect(PlanoTipo.ouro.limiteTalhoesSincronizados, isNull);
      expect(
        MeuPlanoMenu.ouro.vantagemTalhoesSincronizados,
        'Sincronização de talhões desenhados na nuvem sem limite.',
      );
      expect(
        MeuPlanoMenu.ouro.vantagemTalhoesSincronizados,
        isNot(contains(RegExp(r'\d'))),
      );
    });
  });

  group('vantagensMenuPlano inclui bullet de talhões', () {
    test('cada tier mantém bullets legados e acrescenta o de sync', () {
      for (final menu in MeuPlanoMenu.values) {
        final frases = vantagensMenuPlano(menu, vitrineVazia);
        expect(frases, contains(menu.vantagemTalhoesSincronizados));
        expect(frases.length, greaterThan(menu.vantagensBase.length));
        expect(frases, containsAll(menu.vantagensBase));
      }
    });
  });
}