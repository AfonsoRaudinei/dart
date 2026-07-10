import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/clima/data/datasources/ibge_localidades_datasource.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';

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
    test('persiste e restaura cidade selecionada', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      final controller = ClimaSelectedCityController(prefs);

      expect(controller.state, isNull);

      const city = (nome: 'Palmas, TO', lat: -10.184, lon: -48.3336);
      await controller.select(city);

      expect(controller.state, city);
      expect(
        prefs.getString(kClimaSelectedCityPrefsKey),
        'Palmas, TO|-10.184|-48.3336',
      );

      final restored = ClimaSelectedCityController(prefs);
      expect(restored.state?.nome, 'Palmas, TO');
      expect(restored.state?.lat, closeTo(-10.184, 0.0001));

      await controller.clear();
      expect(controller.state, isNull);
      expect(prefs.getString(kClimaSelectedCityPrefsKey), isNull);
    });
  });
}
