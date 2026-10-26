import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/data/relatorio_combinado_repository.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_combinado.dart';

/// Repositório em memória para a aba Consolidados. Não abre SQLite.
class FakeRelatorioCombinadoRepository implements RelatorioCombinadoRepository {
  final List<RelatorioCombinado> rows = [];
  int _seq = 0;

  @override
  Future<List<RelatorioCombinado>> listByClient(String clientId) async {
    final items = rows
        .where((row) => row.clientId == clientId && row.deletedAt == null)
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<RelatorioCombinado> insert({
    required String clientId,
    required List<String> chapterKeys,
  }) async {
    final now = DateTime.now().toUtc();
    final saved = RelatorioCombinado(
      id: 'combo-${_seq++}',
      userId: 'test-user',
      clientId: clientId,
      title: relatorioCombinadoTitle(now, chapterKeys.length),
      chapterKeys: List<String>.of(chapterKeys),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatusContract.pendingSync,
    );
    rows.add(saved);
    return saved;
  }

  @override
  Future<RelatorioCombinado?> removeChapter(
    String id,
    String chapterKey,
  ) async {
    final index = rows.indexWhere(
      (row) => row.id == id && row.deletedAt == null,
    );
    if (index < 0) return null;
    final current = rows[index];
    if (!current.chapterKeys.contains(chapterKey)) return current;
    final nextKeys = current.chapterKeys
        .where((key) => key != chapterKey)
        .toList();
    if (nextKeys.isEmpty) {
      await softDelete(id);
      return null;
    }
    final updated = current.copyWith(
      chapterKeys: nextKeys,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatusContract.pendingSync,
    );
    rows[index] = updated;
    return updated;
  }

  @override
  Future<void> softDelete(String id) async {
    final index = rows.indexWhere((row) => row.id == id);
    if (index < 0) return;
    rows[index] = rows[index].copyWith(
      deletedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatusContract.pendingSync,
    );
  }
}
