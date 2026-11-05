import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/utils/whatsapp_share.dart';

void main() {
  group('buildWhatsAppShareUri', () {
    test('sem telefone usa wa.me com text apenas', () {
      final uri = buildWhatsAppShareUri(message: 'Olá mundo');
      expect(uri, 'https://wa.me/?text=Ol%C3%A1%20mundo');
    });

    test('telefone local recebe prefixo 55', () {
      final uri = buildWhatsAppShareUri(
        phoneDigitsBrazil: '11987654321',
        message: 'Link',
      );
      expect(uri, 'https://wa.me/5511987654321?text=Link');
    });

    test('telefone já com 55 não duplica', () {
      final uri = buildWhatsAppShareUri(
        phoneDigitsBrazil: '5511987654321',
        message: 'Link',
      );
      expect(uri, 'https://wa.me/5511987654321?text=Link');
    });

    test('ignora caracteres não numéricos no telefone', () {
      final uri = buildWhatsAppShareUri(
        phoneDigitsBrazil: '(11) 98765-4321',
        message: 'x',
      );
      expect(uri, 'https://wa.me/5511987654321?text=x');
    });
  });
}
