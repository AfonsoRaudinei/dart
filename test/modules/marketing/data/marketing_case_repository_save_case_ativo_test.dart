import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

/// Regressão do merge em
/// `marketing_case_repository_impl.saveCase` após upsert Supabase.
MarketingCase _rehydrateFromSaveResponse(
  MarketingCase upserted,
  Map<String, dynamic> response,
) {
  final responseWithDefaults = {'ativo': upserted.ativo, ...response};
  return MarketingCase.fromJson(responseWithDefaults);
}

MarketingCase _deletedPendingCase() {
  final now = DateTime.utc(2026, 8, 8, 15);
  return MarketingCase(
    id: 'mkt-deleted-pending',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -10.1,
    lng: -48.2,
    localizacaoTexto: 'Palmas, TO',
    produtorFazenda: 'Produtor Tombstone',
    produtoUtilizado: 'Produto X',
    status: MarketingCaseStatus.published,
    criadoEm: now,
    atualizadoEm: now,
    syncStatus: 'pending_sync',
    ativo: false,
    deletadoEm: now,
  );
}

void main() {
  test(
    'saveCase preserva ativo=false quando resposta Supabase omite ativo',
    () {
      final upserted = _deletedPendingCase();
      final responseWithoutAtivo = Map<String, dynamic>.from(upserted.toJson())
        ..remove('ativo');

      final savedCase = _rehydrateFromSaveResponse(
        upserted,
        responseWithoutAtivo,
      );

      expect(savedCase.ativo, isFalse);
      expect(savedCase.deletadoEm, isNotNull);
    },
  );

  test(
    'regressão: fallback fixo ativo=true reviveria case excluído pendente',
    () {
      final upserted = _deletedPendingCase();
      final responseWithoutAtivo = Map<String, dynamic>.from(upserted.toJson())
        ..remove('ativo');

      final wrongMerge = {'ativo': true, ...responseWithoutAtivo};
      final savedCase = MarketingCase.fromJson(wrongMerge);

      expect(savedCase.ativo, isTrue);
    },
  );
}
