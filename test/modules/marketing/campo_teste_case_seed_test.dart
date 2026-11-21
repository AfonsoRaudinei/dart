import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/campo_teste_case_seed.dart';

void main() {
  test('resumo do campo de teste usa nome e hectares sem zero à direita', () {
    const seed = CampoTesteCaseSeed(
      drawingId: 'draw-1',
      nome: 'Teste',
      areaHa: 12.5,
      clienteId: 'cli-1',
      fazendaNome: 'Fazenda Norte',
      photoPath: '/tmp/foto.jpg',
    );

    expect(seed.areaHaText, '12.5');
    expect(seed.resumo, 'Teste · 12.5 ha');
  });

  test('área inteira não mostra casas decimais', () {
    const seed = CampoTesteCaseSeed(
      drawingId: 'draw-2',
      nome: '  ',
      areaHa: 10,
    );

    expect(seed.areaHaText, '10');
    expect(seed.resumo, 'Teste · 10 ha');
  });
}
