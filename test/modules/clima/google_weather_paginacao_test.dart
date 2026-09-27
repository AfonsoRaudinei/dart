import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/data/datasources/google_weather_remote_datasource.dart';

Map<String, dynamic> _dia(int n) => {'displayDate': {'day': n}};

void main() {
  group('coletarPaginasGoogleWeather', () {
    test('junta páginas de 5 até completar os 7 dias pedidos', () async {
      final tokensUsados = <String?>[];

      final itens = await coletarPaginasGoogleWeather(
        limite: 7,
        buscarPagina: (pageToken) async {
          tokensUsados.add(pageToken);
          if (pageToken == null) {
            return GoogleWeatherPagina(
              itens: [for (var i = 1; i <= 5; i++) _dia(i)],
              nextPageToken: 'pagina-2',
            );
          }
          return GoogleWeatherPagina(
            itens: [for (var i = 6; i <= 10; i++) _dia(i)],
            nextPageToken: 'pagina-3',
          );
        },
      );

      expect(itens, hasLength(7));
      expect(tokensUsados, [null, 'pagina-2']);
      expect((itens.last['displayDate'] as Map)['day'], 7);
    });

    test('uma página só já completa não pede a seguinte', () async {
      var chamadas = 0;

      final itens = await coletarPaginasGoogleWeather(
        limite: 7,
        buscarPagina: (_) async {
          chamadas++;
          return GoogleWeatherPagina(
            itens: [for (var i = 1; i <= 7; i++) _dia(i)],
            nextPageToken: 'nao-deve-usar',
          );
        },
      );

      expect(itens, hasLength(7));
      expect(chamadas, 1);
    });

    test('sem nextPageToken devolve o que veio, sem completar', () async {
      final itens = await coletarPaginasGoogleWeather(
        limite: 7,
        buscarPagina: (_) async => GoogleWeatherPagina(
          itens: [for (var i = 1; i <= 5; i++) _dia(i)],
          nextPageToken: '',
        ),
      );

      expect(itens, hasLength(5));
    });

    test('página vazia encerra a coleta', () async {
      var chamadas = 0;

      final itens = await coletarPaginasGoogleWeather(
        limite: 7,
        buscarPagina: (_) async {
          chamadas++;
          return const GoogleWeatherPagina(
            itens: [],
            nextPageToken: 'tem-token-mas-nao-tem-item',
          );
        },
      );

      expect(itens, isEmpty);
      expect(chamadas, 1);
    });

    test('teto de páginas trava token em loop', () async {
      var chamadas = 0;

      final itens = await coletarPaginasGoogleWeather(
        limite: 100,
        maxPaginas: 3,
        buscarPagina: (_) async {
          chamadas++;
          return GoogleWeatherPagina(
            itens: [_dia(chamadas)],
            nextPageToken: 'sempre-tem-proxima',
          );
        },
      );

      expect(chamadas, 3);
      expect(itens, hasLength(3));
    });
  });
}
