import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/side_menu_greeting.dart';

void main() {
  group('greetingPeriod', () {
    test('manhã, tarde e noite', () {
      expect(greetingPeriod(DateTime(2026, 11, 22, 5)), 'Bom dia');
      expect(greetingPeriod(DateTime(2026, 11, 22, 11, 59)), 'Bom dia');
      expect(greetingPeriod(DateTime(2026, 11, 22, 12)), 'Boa tarde');
      expect(greetingPeriod(DateTime(2026, 11, 22, 17, 59)), 'Boa tarde');
      expect(greetingPeriod(DateTime(2026, 11, 22, 18)), 'Boa noite');
      expect(greetingPeriod(DateTime(2026, 11, 22, 0)), 'Bom dia');
    });
  });

  group('firstNameOf', () {
    test('converte caixa alta para nome de pessoa', () {
      expect(firstNameOf('RAUDINEI Afonso'), 'Raudinei');
      expect(firstNameOf('  maria  da Silva '), 'Maria');
    });
    test('vazio ou nulo', () {
      expect(firstNameOf(null), isNull);
      expect(firstNameOf('   '), isNull);
    });
  });

  test('greetingLine com e sem nome', () {
    final manha = DateTime(2026, 11, 22, 8);
    expect(greetingLine(manha, 'RAUDINEI Afonso'), 'Bom dia, Raudinei');
    expect(greetingLine(manha, null), 'Bom dia');
  });

  test('visitsContextLine conforme a quantidade', () {
    expect(visitsContextLine(0), 'Nenhuma visita pendente hoje');
    expect(visitsContextLine(1), 'Você tem 1 visita hoje');
    expect(visitsContextLine(3), 'Você tem 3 visitas hoje');
  });

  test('menuHeaderPhoto segue a safra: colheita fev–jun, plantio no resto', () {
    String foto(int mes) => menuHeaderPhoto(DateTime(2026, mes, 15));
    const plantio = 'assets/images/menu/header_plantio.jpg';
    const colheita = 'assets/images/menu/header_colheita.jpg';
    for (final mes in [1, 7, 8, 9, 10, 11, 12]) {
      expect(foto(mes), plantio, reason: 'mês $mes');
    }
    for (final mes in [2, 3, 4, 5, 6]) {
      expect(foto(mes), colheita, reason: 'mês $mes');
    }
  });
}
