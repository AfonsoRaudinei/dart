import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/marketing_case_repository_impl.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

const _forbiddenRemoteKeys = <String>{
  'avaliacoes',
  'title',
  'description',
  'product',
  'culture',
  'latitude',
  'longitude',
  'photo_url',
  'visibility',
  'created_at',
  'updated_at',
  'deleted_at',
  'roi_data',
};

MarketingCase _filledCase({String? clientId, DateTime? deletadoEm}) {
  final now = DateTime.utc(2026, 3, 15, 12);
  return MarketingCase(
    id: 'mkt-remote-row-1',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -15.78,
    lng: -47.93,
    localizacaoTexto: 'Brasília, DF',
    produtorFazenda: 'Fazenda Teste',
    produtoUtilizado: 'Produto Y',
    dataCase: DateTime.utc(2026, 3, 15),
    prodSemProduto: 40.0,
    prodComProduto: 55.0,
    clientId: clientId ?? 'client-abc',
    avaliacoesJson: '[{"id":"av-1"}]',
    conclusaoTecnica: 'Ganho consistente',
    roi: const RoiBloco(
      investimento: 100,
      retorno: 250,
      roiCalculado: 150,
    ),
    criadoEm: now,
    atualizadoEm: now,
    deletadoEm: deletadoEm,
  );
}

void main() {
  test('toRemoteRow envia só colunas do live, sem aliases EN nem nested avaliacoes', () {
    final row = MarketingCaseRepositoryImpl.toRemoteRow(
      _filledCase(),
      userId: 'user-1',
      syncStatus: 'synced',
    );

    expect(row['tipo'], 'resultado');
    expect(row['lat'], -15.78);
    expect(row['user_id'], 'user-1');
    expect(row['data_case'], isNotNull);
    expect(row['prod_sem_produto'], 40.0);
    expect(row['conclusao_tecnica'], 'Ganho consistente');
    expect(row['client_id'], 'client-abc');
    expect(row['roi_investimento'], 100);
    expect(row['avaliacoes_json'], '[{"id":"av-1"}]');

    for (final key in _forbiddenRemoteKeys) {
      expect(row.containsKey(key), isFalse, reason: 'chave proibida: $key');
    }

    expect(
      row.keys.every(MarketingCaseRepositoryImpl.remoteColumns.contains),
      isTrue,
    );

    expect(row.containsKey('deletado_em'), isTrue);
    expect(row['deletado_em'], isNull);
  });

  test('toRemoteRow omite client_id vazio ou só whitespace', () {
    final empty = MarketingCaseRepositoryImpl.toRemoteRow(
      _filledCase(clientId: ''),
      userId: 'user-1',
      syncStatus: 'synced',
    );
    expect(empty.containsKey('client_id'), isFalse);

    final whitespace = MarketingCaseRepositoryImpl.toRemoteRow(
      _filledCase(clientId: '   '),
      userId: 'user-1',
      syncStatus: 'synced',
    );
    expect(whitespace.containsKey('client_id'), isFalse);
  });
}
