import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RelatorioHtmlRenderer.sanitizePhotoSrc', () {
    test('rejeita payload XSS em URL', () {
      expect(
        RelatorioHtmlRenderer.sanitizePhotoSrc(
          'https://cdn.test/x"><script>alert(1)</script>',
        ),
        '',
      );
    });

    test('rejeita scheme javascript', () {
      expect(
        RelatorioHtmlRenderer.sanitizePhotoSrc('javascript:alert(1)'),
        '',
      );
    });

    test('aceita https valido', () {
      expect(
        RelatorioHtmlRenderer.sanitizePhotoSrc(
          'https://storage.supabase.co/object/public/photo.jpg',
        ),
        'https://storage.supabase.co/object/public/photo.jpg',
      );
    });

    test('aceita data URI de imagem', () {
      const dataUri = 'data:image/jpeg;base64,abc123';
      expect(RelatorioHtmlRenderer.sanitizePhotoSrc(dataUri), dataUri);
    });
  });

  test('marketing antes/depois nao inclui onerror nem URL maliciosa', () async {
    const remoteUrl = 'https://cdn.test/depois.jpg';
    final html = await MarketingHtmlRenderer.render({
      'tipo': 'antes_depois',
      'produtor_fazenda': 'Cliente',
      'produto_utilizado': 'Produto',
      'localizacao_texto': 'Palmas',
      'visibilidade': 'publico',
      'foto_antes_url': '"><img src=x onerror=alert(1)>',
      'foto_depois_url': remoteUrl,
      'descricao': 'Teste',
      'nome_vendedor': 'Vendedor',
      'criado_em': '2026-06-03T12:00:00.000Z',
      'status': 'publicado',
    }, fetchRemoteBytes: (_) async => null);

    expect(html, isNot(contains('onerror=')));
    expect(html, contains('Sem foto'));
    expect(html, contains('photo-label antes'));
    expect(html, contains(remoteUrl));
  });
}
