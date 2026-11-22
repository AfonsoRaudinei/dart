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

  test('menuHeaderPhoto alterna plantio (dia par) e colheita (dia ímpar)', () {
    expect(
      menuHeaderPhoto(DateTime(2026, 11, 22)),
      'assets/images/menu/header_plantio.jpg',
    );
    expect(
      menuHeaderPhoto(DateTime(2026, 11, 23)),
      'assets/images/menu/header_colheita.jpg',
    );
  });
}
