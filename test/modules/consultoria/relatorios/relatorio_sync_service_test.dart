import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/data/relatorio_sync_service.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_tecnico.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';

import '../helpers/fake_relatorio_repository.dart';

const _kAuthUser = '11111111-1111-4111-8111-111111111111';
const _kClientId = '22222222-2222-4222-8222-222222222222';
const _kVisitUuid = '33333333-3333-4333-8333-333333333333';
const _kOccurrenceId = '44444444-4444-4444-8444-444444444444';

void main() {
  final createdAt = DateTime.utc(2026, 6, 12, 10);
  final updatedAt = DateTime.utc(2026, 6, 12, 11);

  RelatorioTecnico localRelatorio({
    String id = 'rel-1',
    String agronomistId = _kAuthUser,
    String? title = 'Diagnóstico da safra',
    String farmName = 'Fazenda Boa Vista',
    String? customNotes = 'Notas de campo',
    String visitSessionId = _kVisitUuid,
    RelatorioSyncStatus syncStatus = RelatorioSyncStatus.pending_sync,
    DateTime? deletedAt,
    DateTime? localUpdatedAt,
    List<OcorrenciaSnapshot> ocorrencias = const [],
    List<TalhaoVisitado> talhoes = const [],
    List<String> fotos = const [],
    List<MonitoramentoSnapshot> monitoramentos = const [],
  }) {
    return RelatorioTecnico(
      id: id,
      visitSessionId: visitSessionId,
      clientId: _kClientId,
      agronomistId: agronomistId,
      farmName: farmName,
      periodStart: createdAt,
      periodEnd: createdAt.add(const Duration(hours: 2)),
      status: RelatorioStatus.publicado,
      syncStatus: syncStatus,
      createdAt: createdAt,
      updatedAt: localUpdatedAt ?? updatedAt,
      deletedAt: deletedAt,
      title: title,
      customNotes: customNotes,
      ocorrencias: ocorrencias,
      talhoes: talhoes,
      fotos: fotos,
      monitoramentos: monitoramentos,
    );
  }

  group('toRemoteRow', () {
    test('mapeia colunas existentes de relatorios_v2', () {
      final payload = RelatorioSyncService.toRemoteRow(
        localRelatorio(
          ocorrencias: [
            OcorrenciaSnapshot(
              id: _kOccurrenceId,
              tipo: 'Praga',
              descricao: 'Lagarta',
              registradaEm: createdAt,
            ),
          ],
        ),
      );

      expect(payload.keys, unorderedEquals([
        'id',
        'client_id',
        'titulo',
        'descricao',
        'created_by',
        'visit_session_id',
        'occurrence_ids',
        'created_at',
        'updated_at',
        'deleted_at',
        'sync_status',
      ]));
      expect(payload.containsKey('farm_name'), isFalse);
      expect(payload.containsKey('fotos'), isFalse);
      expect(payload['id'], 'rel-1');
      expect(payload['client_id'], _kClientId);
      expect(payload['titulo'], 'Diagnóstico da safra');
      expect(payload['descricao'], 'Notas de campo');
      expect(payload['created_by'], _kAuthUser);
      expect(payload['visit_session_id'], _kVisitUuid);
      expect(payload['occurrence_ids'], '["$_kOccurrenceId"]');
      expect(payload['sync_status'], 'synced');
      expect(payload['deleted_at'], isNull);
    });

    test('titulo cai para farmName e depois para Relatório', () {
      expect(
        RelatorioSyncService.toRemoteRow(
          localRelatorio(title: null, farmName: 'Fazenda X'),
        )['titulo'],
        'Fazenda X',
      );
      expect(
        RelatorioSyncService.toRemoteRow(
          localRelatorio(title: '  ', farmName: '  '),
        )['titulo'],
        'Relatório',
      );
    });

    test('visit_session_id só vai se for UUID válido', () {
      expect(
        RelatorioSyncService.toRemoteRow(
          localRelatorio(visitSessionId: 'sess-test-1'),
        )['visit_session_id'],
        isNull,
      );
      expect(RelatorioSyncService.uuidOrNull(_kVisitUuid), _kVisitUuid);
      expect(RelatorioSyncService.uuidOrNull(''), isNull);
    });

    test('soft delete envia deleted_at e nunca omite o id', () {
      final deletedAt = DateTime.utc(2026, 6, 13, 8);
      final payload = RelatorioSyncService.toRemoteRow(
        localRelatorio(
          syncStatus: RelatorioSyncStatus.deleted_local,
          deletedAt: deletedAt,
        ),
      );
      expect(payload['deleted_at'], deletedAt.toIso8601String());
      expect(payload['id'], 'rel-1');
    });
  });

  group('fromRemoteRow', () {
    test('pull é lossy: period = created_at e snapshots vazios', () {
      final pulled = RelatorioSyncService.fromRemoteRow({
        'id': 'rel-remote-1',
        'client_id': _kClientId,
        'titulo': 'Laudo da visita',
        'descricao': 'Resumo remoto',
        'created_by': _kAuthUser,
        'created_at': '2026-06-12T10:00:00.000Z',
        'updated_at': '2026-06-12T11:00:00.000Z',
        'deleted_at': null,
        'visit_session_id': _kVisitUuid,
        'occurrence_ids': '["$_kOccurrenceId"]',
        'sync_status': 'synced',
      });

      expect(pulled.agronomistId, _kAuthUser);
      expect(pulled.title, 'Laudo da visita');
      expect(pulled.farmName, 'Laudo da visita');
      expect(pulled.customNotes, 'Resumo remoto');
      expect(pulled.periodStart, createdAt);
      expect(pulled.periodEnd, createdAt);
      expect(pulled.status, RelatorioStatus.publicado);
      expect(pulled.syncStatus, RelatorioSyncStatus.synced);
      expect(pulled.visitSessionId, _kVisitUuid);
      expect(pulled.deletedAt, isNull);
      expect(pulled.ocorrencias, isEmpty);
      expect(pulled.talhoes, isEmpty);
      expect(pulled.fotos, isEmpty);
      expect(pulled.monitoramentos, isEmpty);
      expect(pulled.publicacoesRefs, isEmpty);
    });

    test('deleted_at remoto vira soft-delete local', () {
      final pulled = RelatorioSyncService.fromRemoteRow({
        'id': 'rel-remote-2',
        'client_id': _kClientId,
        'titulo': 'Excluído',
        'descricao': '',
        'created_by': _kAuthUser,
        'created_at': '2026-06-12T10:00:00.000Z',
        'updated_at': '2026-06-13T08:00:00.000Z',
        'deleted_at': '2026-06-13T08:00:00.000Z',
        'visit_session_id': null,
      });

      expect(pulled.deletedAt, DateTime.utc(2026, 6, 13, 8));
      expect(pulled.visitSessionId, '');
      expect(pulled.status, RelatorioStatus.publicado);
    });
  });

  group('shouldPush', () {
    test('só pending_sync e deleted_local do próprio auth.uid', () {
      expect(
        RelatorioSyncService.shouldPush(
          localRelatorio(),
          _kAuthUser,
        ),
        isTrue,
      );
      expect(
        RelatorioSyncService.shouldPush(
          localRelatorio(syncStatus: RelatorioSyncStatus.deleted_local),
          _kAuthUser,
        ),
        isTrue,
      );
      expect(
        RelatorioSyncService.shouldPush(
          localRelatorio(syncStatus: RelatorioSyncStatus.local_only),
          _kAuthUser,
        ),
        isFalse,
      );
      expect(
        RelatorioSyncService.shouldPush(
          localRelatorio(agronomistId: 'outro-user'),
          _kAuthUser,
        ),
        isFalse,
      );
    });
  });

  group('shouldReplace / keep snapshots', () {
    final older = DateTime.utc(2026, 6, 12, 10);
    final newer = DateTime.utc(2026, 6, 12, 12);
    final snapshot = OcorrenciaSnapshot(
      id: _kOccurrenceId,
      tipo: 'Praga',
      descricao: 'Lagarta',
      registradaEm: createdAt,
    );

    test('não substitui quando remoto não é mais novo', () {
      final local = localRelatorio(localUpdatedAt: newer);
      final pulled = RelatorioSyncService.fromRemoteRow({
        'id': 'rel-1',
        'client_id': _kClientId,
        'titulo': 'Novo título',
        'descricao': 'Nova nota',
        'created_by': _kAuthUser,
        'created_at': '2026-06-12T10:00:00.000Z',
        'updated_at': older.toIso8601String(),
      });

      expect(RelatorioSyncService.shouldReplace(local, pulled), isFalse);
      expect(
        identical(
          RelatorioSyncService.mergePulled(local: local, pulled: pulled),
          local,
        ),
        isTrue,
      );
    });

    test('remoto mais novo com snapshots locais preserva listas e atualiza metadados', () {
      final local = localRelatorio(
        localUpdatedAt: older,
        title: 'Título local',
        customNotes: 'Nota local',
        ocorrencias: [snapshot],
        fotos: const ['file:///foto.jpg'],
      );
      final pulled = RelatorioSyncService.fromRemoteRow({
        'id': 'rel-1',
        'client_id': _kClientId,
        'titulo': 'Título remoto',
        'descricao': 'Nota remota',
        'created_by': _kAuthUser,
        'created_at': '2026-06-12T10:00:00.000Z',
        'updated_at': newer.toIso8601String(),
        'deleted_at': '2026-06-13T08:00:00.000Z',
      });

      expect(RelatorioSyncService.shouldKeepLocalSnapshots(local), isTrue);
      expect(RelatorioSyncService.shouldReplace(local, pulled), isFalse);

      final merged = RelatorioSyncService.mergePulled(
        local: local,
        pulled: pulled,
      );
      expect(merged.title, 'Título remoto');
      expect(merged.customNotes, 'Nota remota');
      expect(merged.deletedAt, DateTime.utc(2026, 6, 13, 8));
      expect(merged.status, RelatorioStatus.publicado);
      expect(merged.syncStatus, RelatorioSyncStatus.synced);
      expect(merged.ocorrencias, hasLength(1));
      expect(merged.fotos, ['file:///foto.jpg']);
      expect(merged.farmName, 'Fazenda Boa Vista');
    });

    test('remoto mais novo sem snapshots locais substitui (lossy)', () {
      final local = localRelatorio(localUpdatedAt: older);
      final pulled = RelatorioSyncService.fromRemoteRow({
        'id': 'rel-1',
        'client_id': _kClientId,
        'titulo': 'Só nuvem',
        'descricao': '',
        'created_by': _kAuthUser,
        'created_at': '2026-06-12T10:00:00.000Z',
        'updated_at': newer.toIso8601String(),
      });

      expect(RelatorioSyncService.shouldKeepLocalSnapshots(local), isFalse);
      expect(RelatorioSyncService.shouldReplace(local, pulled), isTrue);
      expect(
        RelatorioSyncService.mergePulled(local: local, pulled: pulled).title,
        'Só nuvem',
      );
    });
  });

  group('syncNow sem JWT', () {
    test('cliente nulo é no-op e preserva pendências', () async {
      final repository = FakeRelatorioRepository();
      repository.seed([localRelatorio()]);

      final service = RelatorioSyncService(
        repository: repository,
        supabase: null,
      );

      await service.syncNow();

      expect(repository.get('rel-1')?.syncStatus, RelatorioSyncStatus.pending_sync);
    });

    test('callback de userId vazio é no-op', () async {
      final repository = FakeRelatorioRepository();
      repository.seed([
        localRelatorio(syncStatus: RelatorioSyncStatus.deleted_local),
      ]);

      final service = RelatorioSyncService(
        repository: repository,
        supabase: null,
        currentUserId: () => null,
      );

      await service.syncNow();

      expect(
        repository.get('rel-1')?.syncStatus,
        RelatorioSyncStatus.deleted_local,
      );
    });
  });
}
