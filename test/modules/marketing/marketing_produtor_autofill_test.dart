import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/novo_case_form_helpers.dart';

void main() {
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
