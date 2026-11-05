import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_clima_manual.dart';

void main() {
  group('RelatorioClimaManual', () {
    test('hasContent false when null or empty', () {
      expect(RelatorioClimaManual.hasContent(null), isFalse);
      expect(
        RelatorioClimaManual.hasContent(const RelatorioClimaManual()),
        isFalse,
      );
    });

    test('hasContent true with dia resumo or pulverizacao', () {
      expect(
        RelatorioClimaManual.hasContent(
          const RelatorioClimaManual(
            dias: [RelatorioClimaDiaManual(resumo: 'Chuva isolada')],
          ),
        ),
        isTrue,
      );
      expect(
        RelatorioClimaManual.hasContent(
          const RelatorioClimaManual(pulverizacaoNota: 'Janela amanhã cedo'),
        ),
        isTrue,
      );
    });

    test('json roundtrip', () {
      const original = RelatorioClimaManual(
        dias: [
          RelatorioClimaDiaManual(
            data: '2026-11-06T12:00:00.000Z',
            resumo: 'Parcialmente nublado',
          ),
          RelatorioClimaDiaManual(resumo: 'Seco'),
        ],
        pulverizacaoNota: 'Evitar vento forte',
      );
      final decoded = RelatorioClimaManual.fromJson(original.toJson());
      expect(decoded.pulverizacaoNota, original.pulverizacaoNota);
      expect(decoded.dias, hasLength(2));
      expect(decoded.dias.first.resumo, 'Parcialmente nublado');
      expect(decoded.dias.first.data, original.dias.first.data);
    });
  });
}
