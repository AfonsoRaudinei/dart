import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/data/datasources/ibge_localidades_datasource.dart';
import 'package:soloforte_app/ui/components/map/map_municipality_search_sheet.dart';

void main() {
  const goiatuba = IbgeMunicipio(id: 1, nome: 'Goiatuba', uf: 'GO');
  const itumbiara = IbgeMunicipio(id: 2, nome: 'Itumbiara', uf: 'GO');

  test('resolveMapMunicipalityForSearch prioriza seleção explícita', () {
    final result = resolveMapMunicipalityForSearch(
      filtered: [goiatuba, itumbiara],
      query: 'itum',
      selected: itumbiara,
    );
    expect(result, itumbiara);
  });

  test('resolveMapMunicipalityForSearch usa match exato do termo', () {
    final result = resolveMapMunicipalityForSearch(
      filtered: [goiatuba, itumbiara],
      query: 'Goiatuba',
      selected: null,
    );
    expect(result, goiatuba);
  });

  test('resolveMapMunicipalityForSearch usa único resultado filtrado', () {
    final result = resolveMapMunicipalityForSearch(
      filtered: [goiatuba],
      query: 'goia',
      selected: null,
    );
    expect(result, goiatuba);
  });

  test('resolveMapMunicipalityForSearch retorna null se ambíguo', () {
    final result = resolveMapMunicipalityForSearch(
      filtered: [goiatuba, itumbiara],
      query: 'a',
      selected: null,
    );
    expect(result, isNull);
  });
}
