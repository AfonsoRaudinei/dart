import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
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

  group('marketingProdutorShouldAutofillFromClient', () {
    test('permite autofill com campo vazio', () {
      expect(
        marketingProdutorShouldAutofillFromClient(
          currentProdutor: '',
          lastAutoFilledClientName: null,
          produtorEditedByUser: false,
        ),
        isTrue,
      );
    });

    test('bloqueia autofill após edição manual', () {
      expect(
        marketingProdutorShouldAutofillFromClient(
          currentProdutor: 'Texto digitado',
          lastAutoFilledClientName: null,
          produtorEditedByUser: true,
        ),
        isFalse,
      );
    });

    test('autofill usa último nome preenchido pelo cliente', () {
      expect(
        marketingProdutorShouldAutofillFromClient(
          currentProdutor: 'Cliente A',
          lastAutoFilledClientName: 'Cliente A',
          produtorEditedByUser: false,
        ),
        isTrue,
      );
    });
  });

  test('marketingClientProdutorAutofillValue usa nome trimado', () {
    const client = ClientSummary(
      id: 'c1',
      name: '  Fazenda Sol  ',
      active: true,
    );
    expect(marketingClientProdutorAutofillValue(client), 'Fazenda Sol');
  });
}