import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_campo_nivel.dart';

void main() {
  Occurrence occ(String metricasJson) => Occurrence(
        id: '1',
        type: 'Média',
        description: '',
        createdAt: DateTime.utc(2026, 1, 1),
        metricasJson: metricasJson,
      );

  test('max incidência/severidade usa o maior valor', () {
    expect(
      maxIncidenciaSeveridadeSlider(
        occ('{"doenca":{"incidencia":1,"severidade":3}}'),
      ),
      3,
    );
    expect(
      maxIncidenciaSeveridadeSlider(
        occ('{"daninhas":{"severidade":2}}'),
      ),
      2,
    );
  });

  test('nível lista mapeia slider 1–3 para Baixo/Médio/Alto', () {
    expect(
      resolveCampoNivelLista(occ('{"doenca":{"incidencia":1}}'))
          ?.displayLabel,
      'Baixo',
    );
    expect(
      resolveCampoNivelLista(occ('{"doenca":{"severidade":2}}'))
          ?.displayLabel,
      'Médio',
    );
    expect(
      resolveCampoNivelLista(occ('{"doenca":{"severidade":3}}'))
          ?.displayLabel,
      'Alto',
    );
  });

  test('acima do limite só quando slider > 2 (Alto)', () {
    expect(
      occurrenceCampoNivelAcimaDoLimite(
        occ('{"doenca":{"severidade":2}}'),
      ),
      isFalse,
    );
    expect(
      occurrenceCampoNivelAcimaDoLimite(
        occ('{"doenca":{"severidade":3}}'),
      ),
      isTrue,
    );
  });

  test('ignora outras métricas no nível de campo', () {
    expect(
      resolveCampoNivelLista(
        occ('{"insetos":{"desfolha":3}}'),
      ),
      isNull,
    );
  });
}
