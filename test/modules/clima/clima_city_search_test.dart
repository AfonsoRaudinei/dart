import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/clima/data/datasources/ibge_localidades_datasource.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';

Future<ProviderContainer> _containerWithPrefs([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = PreferencesService(await SharedPreferences.getInstance());
  return ProviderContainer(
    overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
  );
}

void main() {
  group('IbgeLocalidadesDatasource', () {
    late IbgeLocalidadesDatasource datasource;

    setUp(() {
      datasource = IbgeLocalidadesDatasource();
    });

    test('filterMunicipios filtra por termo case-insensitive', () {
      const municipios = [
        IbgeMunicipio(id: 1, nome: 'Palmas', uf: 'TO'),
        IbgeMunicipio(id: 2, nome: 'Porto Nacional', uf: 'TO'),
        IbgeMunicipio(id: 3, nome: 'Araguaína', uf: 'TO'),
      ];

      final result = datasource.filterMunicipios(municipios, 'porto');
      expect(result, hasLength(1));
      expect(result.first.nome, 'Porto Nacional');
    });

    test('filterMunicipios retorna todos quando busca vazia', () {
      const municipios = [
        IbgeMunicipio(id: 1, nome: 'Palmas', uf: 'TO'),
      ];

      expect(datasource.filterMunicipios(municipios, ''), municipios);
    });
  });

  group('ClimaSelectedCityController', () {
    test('persiste e restaura cidade selecionada via prefs', () async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      final prefs = container.read(preferencesServiceProvider);

      expect(container.read(climaSelectedCityProvider), isNull);

      const city = (nome: 'Palmas, TO', lat: -10.184, lon: -48.3336);
      await container.read(climaSelectedCityProvider.notifier).select(city);

      expect(container.read(climaSelectedCityProvider), city);
      expect(
        prefs.getString(kClimaSelectedCityPrefsKey),
        'Palmas, TO|-10.184|-48.3336',
      );

      // Novo container = cold start: build() lê SharedPreferences.
      final restored = await _containerWithPrefs({
        kClimaSelectedCityPrefsKey: 'Palmas, TO|-10.184|-48.3336',
      });
      addTearDown(restored.dispose);

      final restoredCity = restored.read(climaSelectedCityProvider);
      expect(restoredCity?.nome, 'Palmas, TO');
      expect(restoredCity?.lat, closeTo(-10.184, 0.0001));
      expect(restoredCity?.lon, closeTo(-48.3336, 0.0001));

      await container.read(climaSelectedCityProvider.notifier).clear();
      expect(container.read(climaSelectedCityProvider), isNull);
      expect(prefs.getString(kClimaSelectedCityPrefsKey), isNull);
    });

    test('prefs inválidas ou incompletas → state null', () async {
      final container = await _containerWithPrefs({
        kClimaSelectedCityPrefsKey: 'cidade-sem-coords',
      });
      addTearDown(container.dispose);

      expect(container.read(climaSelectedCityProvider), isNull);
    });
  });
}
