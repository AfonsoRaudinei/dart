import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

void main() {
  group('MarketingCase', () {
    final now = DateTime.utc(2026, 3, 21, 15);

    Map<String, dynamic> baseJson() => {
      'id': 'case-1',
      'tipo': 'resultado',
      'visibilidade': 'ouro',
      'lat': -15.5,
      'lng': -47.2,
      'localizacao_texto': 'Fazenda Norte',
      'produtor_fazenda': 'Produtor A',
      'produto_utilizado': 'Produto X',
      'criado_em': now.toIso8601String(),
      'atualizado_em': now.toIso8601String(),
      'roi_investimento': 1000,
      'roi_retorno': 2500,
      'roi_calculado': 150,
    };

    test('fromJson/toJson preserva campos principais e ROI', () {
      final original = MarketingCase.fromJson(baseJson());
      final restored = MarketingCase.fromJson(original.toJson());

      expect(restored.id, 'case-1');
      expect(restored.tipo, CaseTipo.resultado);
      expect(restored.visibilidade, PlanoMarketing.ouro);
      expect(restored.ativo, isTrue);
      expect(restored.status, MarketingCaseStatus.published);
      expect(restored.syncStatus, 'local_only');
      expect(restored.roi?.investimento, 1000);
      expect(restored.roi?.retorno, 2500);
    });

    test('fromJson aplica defaults quando campos opcionais ausentes', () {
      final json = baseJson()
        ..remove('roi_investimento')
        ..remove('roi_retorno')
        ..remove('roi_calculado');

      final marketingCase = MarketingCase.fromJson(json);

      expect(marketingCase.roi, isNull);
      expect(marketingCase.avaliacoes, isEmpty);
    });
  });

  group('RoiBloco', () {
    test('fromJson usa zero quando campos ROI ausentes', () {
      final roi = RoiBloco.fromJson(const {});

      expect(roi.investimento, 0);
      expect(roi.retorno, 0);
      expect(roi.roiCalculado, 0);
    });

    test('toJson expõe chaves roi_*', () {
      const roi = RoiBloco(investimento: 10, retorno: 20, roiCalculado: 100);
      final json = roi.toJson();

      expect(json['roi_investimento'], 10);
      expect(json['roi_retorno'], 20);
      expect(json['roi_calculado'], 100);
    });
  });
}
