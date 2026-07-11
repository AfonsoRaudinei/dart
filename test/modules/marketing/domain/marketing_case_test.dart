import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/avaliacao_item.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
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
      'data_case': DateTime.utc(2026, 7, 11).toIso8601String(),
      'criado_em': now.toIso8601String(),
      'atualizado_em': now.toIso8601String(),
      'roi_investimento': 1000,
      'roi_retorno': 2500,
      'roi_calculado': 150,
      'prod_sem_produto': 60,
      'prod_com_produto': 64,
      'unidade_produtividade': 'sc/ha',
      'custo_produto_por_ha': 90,
      'valor_grao': 110,
      'client_id': 'client-1',
      'parametros_json': jsonEncode([
        const ParametroComparativo(
          id: 'param-1',
          titulo: 'Número de Grãos',
          testemunha: 10,
          teste: 12,
          unidade: 'grãos/vagem',
        ).toJson(),
      ]),
      'avaliacoes_json': jsonEncode([
        const AvaliacaoItem(
          id: 'av-1',
          titulo: 'Avaliação 1',
          nomeLadoA: 'Testemunha',
          nomeLadoB: 'Produto A',
          parametros: [
            ParametroComparativo(
              id: 'param-av-1',
              titulo: 'Número de Grãos',
              testemunha: 10,
              teste: 12,
            ),
          ],
        ).toJson(),
      ]),
      'conclusao_tecnica': 'Produto A performou melhor.',
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
      expect(restored.prodSemProduto, 60);
      expect(restored.prodComProduto, 64);
      expect(restored.unidadeProdutividade, 'sc/ha');
      expect(restored.custoProdutoPorHa, 90);
      expect(restored.valorGrao, 110);
      expect(restored.clientId, 'client-1');
      expect(restored.dataCase, DateTime.utc(2026, 7, 11));
      expect(restored.parametros, hasLength(1));
      expect(restored.parametros.first.deltaPercent, 20);
      expect(restored.avaliacoesLivres, hasLength(1));
      expect(restored.avaliacoesLivres.first.mediaGanhoPercent, 20);
      expect(restored.conclusaoTecnica, 'Produto A performou melhor.');
      expect(restored.toJson(), isNot(contains('roi_liquido_rs_ha')));
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
