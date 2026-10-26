import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/utils/municipio_uf.dart';

void main() {
  group('MunicipioUf.hasUf', () {
    test('reconhece UF após separador ou espaço', () {
      expect(MunicipioUf.hasUf('Palmas - TO'), isTrue);
      expect(MunicipioUf.hasUf('Palmas, to'), isTrue);
      expect(MunicipioUf.hasUf('Palmas TO'), isTrue);
      expect(MunicipioUf.hasUf('Jataizinho/PR'), isTrue);
    });

    test('rejeita cidade sem UF ou sigla inexistente', () {
      expect(MunicipioUf.hasUf('Palmas'), isFalse);
      expect(MunicipioUf.hasUf('Palmas - XX'), isFalse);
      expect(MunicipioUf.hasUf(''), isFalse);
    });
  });

  group('MunicipioUf.compose', () {
    test('anexa UF ao município', () {
      expect(MunicipioUf.compose('Palmas', 'TO'), 'Palmas - TO');
    });

    test('mantém município quando UF é nula, vazia ou já presente', () {
      expect(MunicipioUf.compose('Palmas', null), 'Palmas');
      expect(MunicipioUf.compose('Palmas', ''), 'Palmas');
      expect(MunicipioUf.compose('Palmas - TO', 'TO'), 'Palmas - TO');
    });
  });
}
