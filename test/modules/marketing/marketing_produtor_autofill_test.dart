import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/novo_case_form_helpers.dart';

void main() {
  group('marketingEffectiveProdutorFazenda', () {
    test('usa texto manual quando preenchido', () {
      expect(
        marketingEffectiveProdutorFazenda(
          manualProdutor: 'Fazenda Norte',
          selectedClientName: 'Ademir Rossato',
        ),
        'Fazenda Norte',
      );
    });

    test('fallback para nome do cliente quando manual vazio', () {
      expect(
        marketingEffectiveProdutorFazenda(
          manualProdutor: '  ',
          selectedClientName: 'Ademir Rossato',
        ),
        'Ademir Rossato',
      );
    });

    test('vazio sem cliente selecionado', () {
      expect(
        marketingEffectiveProdutorFazenda(
          manualProdutor: '',
          selectedClientName: null,
        ),
        '',
      );
    });
  });

  group('marketingVisitInitialProdutorFieldText', () {
    test('não repete só o nome do cliente', () {
      expect(
        marketingVisitInitialProdutorFieldText(
          producerFarmLabel: 'Ademir Rossato',
          clientName: 'Ademir Rossato',
        ),
        '',
      );
    });

    test('mantém label cliente / fazenda', () {
      expect(
        marketingVisitInitialProdutorFieldText(
          producerFarmLabel: 'José / Fazenda Boa Vista',
          clientName: 'José',
        ),
        'José / Fazenda Boa Vista',
      );
    });
  });

  group('marketingProdutorFieldRequired', () {
    test('obrigatório sem clientId', () {
      expect(marketingProdutorFieldRequired(clientId: null), isTrue);
    });

    test('opcional com clientId', () {
      expect(marketingProdutorFieldRequired(clientId: 'c1'), isFalse);
    });
  });

}