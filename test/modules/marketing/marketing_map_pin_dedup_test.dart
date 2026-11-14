import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_map_pin_dedup.dart';

MarketingCase _case({
  required String id,
  required PlanoMarketing visibilidade,
  String? sourceCaseId,
  DateTime? atualizadoEm,
}) {
  final t = atualizadoEm ?? DateTime.utc(2026, 6, 1);
  return MarketingCase(
    id: id,
    tipo: CaseTipo.resultado,
    visibilidade: visibilidade,
    lat: -15,
    lng: -47,
    localizacaoTexto: 'Local',
    produtorFazenda: 'Fazenda',
    produtoUtilizado: 'Produto',
    sourceCaseId: sourceCaseId,
    criadoEm: t,
    atualizadoEm: t,
  );
}

void main() {
  group('deduplicateHighestMetalPerGroup', () {
    test('consultor Prata + produtor Ouro mesmo grupo → só Ouro', () {
      const root = 'case-root';
      final consultor = _case(
        id: root,
        visibilidade: PlanoMarketing.prata,
      );
      final produtor = _case(
        id: 'case-produtor',
        visibilidade: PlanoMarketing.ouro,
        sourceCaseId: root,
        atualizadoEm: DateTime.utc(2026, 7, 1),
      );

      final out = deduplicateHighestMetalPerGroup([consultor, produtor]);

      expect(out, hasLength(1));
      expect(out.single.id, 'case-produtor');
      expect(out.single.visibilidade, PlanoMarketing.ouro);
    });

    test('empate de metal usa atualizado_em mais recente', () {
      const root = 'case-root';
      final older = _case(
        id: 'a',
        visibilidade: PlanoMarketing.ouro,
        sourceCaseId: root,
        atualizadoEm: DateTime.utc(2026, 1, 1),
      );
      final newer = _case(
        id: root,
        visibilidade: PlanoMarketing.ouro,
        atualizadoEm: DateTime.utc(2026, 8, 1),
      );

      final out = deduplicateHighestMetalPerGroup([older, newer]);
      expect(out.single.id, 'case-root');
    });

    test('grupos distintos permanecem', () {
      final a = _case(id: 'g1', visibilidade: PlanoMarketing.bronze);
      final b = _case(id: 'g2', visibilidade: PlanoMarketing.prata);
      expect(deduplicateHighestMetalPerGroup([a, b]), hasLength(2));
    });

    test('R consultor + clone A + republicação B (source=R) → um pin', () {
      const r = 'case-R';
      final consultor = _case(id: r, visibilidade: PlanoMarketing.prata);
      final cloneA = _case(
        id: 'A',
        visibilidade: PlanoMarketing.prata,
        sourceCaseId: r,
      );
      final republicacaoB = _case(
        id: 'B',
        visibilidade: PlanoMarketing.ouro,
        sourceCaseId: r,
        atualizadoEm: DateTime.utc(2026, 9, 1),
      );

      final out = deduplicateHighestMetalPerGroup([
        consultor,
        cloneA,
        republicacaoB,
      ]);

      expect(out, hasLength(1));
      expect(out.single.id, 'B');
      expect(out.single.visibilidade, PlanoMarketing.ouro);
    });
  });
}