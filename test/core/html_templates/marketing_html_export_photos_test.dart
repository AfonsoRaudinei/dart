import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const remoteUrl = 'https://cdn.test/marketing/resultado.jpg';
  final fakeBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

  Future<Uint8List?> mockFetcher(String url) async {
    if (url == remoteUrl) return fakeBytes;
    return null;
  }

  group('RelatorioHtmlRenderer.resolvePhotoSrcForExport', () {
    test('inline base64 quando fetch remoto retorna bytes', () async {
      final src = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
        remoteUrl,
        fetchRemoteBytes: mockFetcher,
      );

      expect(src, startsWith('data:image/jpeg;base64,'));
      expect(src, isNot(contains('https://cdn.test')));
    });

    test('fallback para URL https sanitizada quando fetch falha', () async {
      final src = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
        remoteUrl,
        fetchRemoteBytes: (_) async => null,
      );

      expect(src, remoteUrl);
    });
  });

  group('MarketingHtmlRenderer export photos', () {
    test('resultado exporta foto principal inline', () async {
      final html = await MarketingHtmlRenderer.render(
        {
          'tipo': 'resultado',
          'produtor_fazenda': 'Cliente',
          'produto_utilizado': 'Produto',
          'localizacao_texto': 'Palmas',
          'visibilidade': 'ouro',
          'foto_principal_url': remoteUrl,
          'descricao': 'Teste',
          'nome_vendedor': 'Vendedor',
          'criado_em': '2026-06-03T12:00:00.000Z',
          'status': 'published',
        },
        fetchRemoteBytes: mockFetcher,
      );

      expect(html, contains('data:image/jpeg;base64,'));
      expect(html, isNot(contains(remoteUrl)));
    });

    test('avaliacao exporta fotos dos lados inline', () async {
      final html = await MarketingHtmlRenderer.render(
        {
          'tipo': 'avaliacao',
          'produtor_fazenda': 'Cliente',
          'produto_utilizado': 'Produto',
          'localizacao_texto': 'Palmas',
          'visibilidade': 'ouro',
          'nome_talhao': 'Talhão 1',
          'avaliacoes': [
            {
              'layout': 'duas_fotos',
              'lado_a_label': 'Lado A',
              'lado_a_foto_url': remoteUrl,
              'lado_b_label': 'Lado B',
              'lado_b_foto_url': remoteUrl,
            },
          ],
          'descricao': 'Teste',
          'nome_vendedor': 'Vendedor',
          'criado_em': '2026-06-03T12:00:00.000Z',
          'status': 'published',
        },
        fetchRemoteBytes: mockFetcher,
      );

      expect(html, contains('data:image/jpeg;base64,'));
      expect(html, isNot(contains(remoteUrl)));
    });

    test('antes/depois mantém segurança contra URL maliciosa', () async {
      final html = await MarketingHtmlRenderer.render(
        {
          'tipo': 'antes_depois',
          'produtor_fazenda': 'Cliente',
          'produto_utilizado': 'Produto',
          'localizacao_texto': 'Palmas',
          'visibilidade': 'ouro',
          'foto_antes_url': '"><img src=x onerror=alert(1)>',
          'foto_depois_url': remoteUrl,
          'descricao': 'Teste',
          'nome_vendedor': 'Vendedor',
          'criado_em': '2026-06-03T12:00:00.000Z',
          'status': 'published',
        },
        fetchRemoteBytes: mockFetcher,
      );

      expect(html, isNot(contains('onerror=')));
      expect(html, contains('Sem foto'));
      expect(html, contains('data:image/jpeg;base64,'));
    });
  });
}
