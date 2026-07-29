import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  // JPEG mínimo (SOI + EOI)
  const jpegBytes = <int>[0xFF, 0xD8, 0xFF, 0xD9];

  MockClient okClient() => MockClient((request) async {
    return http.Response.bytes(
      jpegBytes,
      200,
      headers: {'content-type': 'image/jpeg'},
    );
  });

  test('resultado: URL remota ok embute data URI base64', () async {
    final url = 'https://cdn.example/foto.jpg';
    final html = await MarketingHtmlRenderer.render(
      {
        ..._base('resultado'),
        'foto_principal_url': url,
      },
      httpClient: okClient(),
    );

    final expected = 'data:image/jpeg;base64,${base64Encode(jpegBytes)}';
    expect(html, contains(expected));
    expect(html, isNot(contains('src="$url"')));
  });

  test('resultado: falha de rede faz fallback para URL original', () async {
    final url = 'https://cdn.example/inexistente.jpg';
    final client = MockClient((request) async {
      throw const SocketException('offline');
    });

    final html = await MarketingHtmlRenderer.render(
      {
        ..._base('resultado'),
        'foto_principal_url': url,
      },
      httpClient: client,
    );

    expect(html, contains('src="$url"'));
    expect(html, isNot(contains('data:image/jpeg;base64,')));
  });

  test('antes_depois: URLs remotas embutidas como data URI', () async {
    final antes = 'https://cdn.example/antes.jpg';
    final depois = 'https://cdn.example/depois.jpg';
    final html = await MarketingHtmlRenderer.render(
      {
        ..._base('antes_depois'),
        'foto_antes_url': antes,
        'foto_depois_url': depois,
      },
      httpClient: okClient(),
    );

    final expected = 'data:image/jpeg;base64,${base64Encode(jpegBytes)}';
    expect(html, contains(expected));
    expect(html, isNot(contains('src="$antes"')));
    expect(html, isNot(contains('src="$depois"')));
  });
}

Map<String, dynamic> _base(String tipo) {
  return {
    'tipo': tipo,
    'produtor_fazenda': 'Cliente Teste - Fazenda Modelo',
    'produto_utilizado': 'Produto X',
    'localizacao_texto': 'Palmas, TO',
    'visibilidade': 'publico',
    'produtividade_valor': 72,
    'produtividade_unidade': 'sc/ha',
    'quantidade_produzida': 1800,
    'economia_gerada': 'R\$ 12.000',
    'roi_calculado': 2.5,
    'roi_investimento': 10000,
    'roi_retorno': 25000,
    'prod_sem_produto': 60,
    'prod_com_produto': 64,
    'unidade_produtividade': 'sc/ha',
    'custo_produto_por_ha': 90,
    'valor_grao': 110,
    'tamanho_ha': 12.5,
    'area_total': 900,
    'parametros_json': '[]',
    'ganho_produtividade': '+12%',
    'descricao': 'Resultado validado em campo.',
    'lat': -10.1,
    'lng': -48.2,
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'data_case': '2026-07-11T00:00:00.000Z',
    'criado_em': '2026-06-03T12:00:00.000Z',
    'status': 'publicado',
  };
}
