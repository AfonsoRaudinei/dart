import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/avaliacao_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/avaliacao_lado.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/avaliacao_layout.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_media.dart';

MarketingCase _base({
  CaseTipo tipo = CaseTipo.resultado,
  String? fotoPrincipalUrl,
  String? fotoAntesUrl,
  String? fotoDepoisUrl,
  List<AvaliacaoBloco> avaliacoes = const [],
}) {
  final now = DateTime.utc(2026, 7, 27);
  return MarketingCase(
    id: 'c1',
    tipo: tipo,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Brejinho',
    produtorFazenda: 'Fazenda',
    produtoUtilizado: 'Coach',
    fotoPrincipalUrl: fotoPrincipalUrl,
    fotoAntesUrl: fotoAntesUrl,
    fotoDepoisUrl: fotoDepoisUrl,
    avaliacoes: avaliacoes,
    criadoEm: now,
    atualizadoEm: now,
  );
}

void main() {
  group('MarketingCaseMedia.mediaRefs', () {
    test('resultado com uma foto', () {
      final refs = MarketingCaseMedia.mediaRefs(
        _base(fotoPrincipalUrl: 'https://a/p.jpg'),
      );
      expect(refs, ['https://a/p.jpg']);
    });

    test('antes/depois: depois antes principal; ordem depois→antes', () {
      final refs = MarketingCaseMedia.mediaRefs(
        _base(
          tipo: CaseTipo.antesDepois,
          fotoAntesUrl: 'https://a/antes.jpg',
          fotoDepoisUrl: 'https://a/depois.jpg',
        ),
      );
      expect(refs, ['https://a/depois.jpg', 'https://a/antes.jpg']);
    });

    test('deduplica e inclui lados de avaliação', () {
      final refs = MarketingCaseMedia.mediaRefs(
        _base(
          tipo: CaseTipo.avaliacao,
          fotoPrincipalUrl: 'https://a/p.jpg',
          avaliacoes: [
            AvaliacaoBloco(
              id: 'b1',
              caseId: 'c1',
              ordem: 0,
              layout: AvaliacaoLayout.duasFotos,
              colapsado: false,
              ladoA: const AvaliacaoLado(
                label: 'A',
                fotoUrl: 'https://a/p.jpg',
              ),
              ladoB: const AvaliacaoLado(
                label: 'B',
                fotoUrl: 'https://a/b.jpg',
              ),
            ),
          ],
        ),
      );
      expect(refs, ['https://a/p.jpg', 'https://a/b.jpg']);
    });

    test('label Antes/Depois', () {
      final c = _base(
        tipo: CaseTipo.antesDepois,
        fotoAntesUrl: 'https://a/antes.jpg',
        fotoDepoisUrl: 'https://a/depois.jpg',
      );
      expect(MarketingCaseMedia.labelFor(c, 0), 'Depois');
      expect(MarketingCaseMedia.labelFor(c, 1), 'Antes');
    });
  });
}
