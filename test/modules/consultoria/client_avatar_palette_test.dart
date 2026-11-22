import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_avatar_widget.dart';

void main() {
  test('cor é estável para o mesmo nome (ignora caixa e espaços)', () {
    expect(
      ClientAvatarWidget.colorFor('Ademir Rossato'),
      ClientAvatarWidget.colorFor('  ademir rossato '),
    );
  });

  test('sempre devolve uma cor da paleta curada', () {
    for (final n in ['A', 'Brejinho', 'Cláudio Gorgem', '', 'Zé']) {
      expect(
        ClientAvatarWidget.palette,
        contains(ClientAvatarWidget.colorFor(n)),
      );
    }
  });

  test('letra branca tem contraste AA (>= 4.5) em todos os tons', () {
    double lum(int c) {
      double ch(int v) {
        final x = v / 255;
        return x <= 0.03928 ? x / 12.92 : _pow((x + 0.055) / 1.055, 2.4);
      }

      return 0.2126 * ch((c >> 16) & 255) +
          0.7152 * ch((c >> 8) & 255) +
          0.0722 * ch(c & 255);
    }

    for (final color in ClientAvatarWidget.palette) {
      final l = lum(color.toARGB32());
      expect(1.05 / (l + 0.05), greaterThanOrEqualTo(4.5), reason: '$color');
    }
  });
}

double _pow(double b, double e) => _exp(e * _ln(b));
double _ln(double x) {
  // série de atanh para ln(x), x em (0.04, 1.2)
  final y = (x - 1) / (x + 1);
  var term = y, sum = 0.0;
  for (var i = 1; i < 200; i += 2) {
    sum += term / i;
    term *= y * y;
  }
  return 2 * sum;
}

double _exp(double x) {
  var term = 1.0, sum = 1.0;
  for (var i = 1; i < 60; i++) {
    term *= x / i;
    sum += term;
  }
  return sum;
}
