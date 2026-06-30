import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_tecnico.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/repositories/i_relatorio_repository.dart';

/// Implementação em memória de [IRelatorioRepository] para testes.
///
/// Segue o padrão estabelecido pelo [FakeAgendaRepository]:
/// - Estado em `Map<String, RelatorioTecnico>` — sem SQLite
/// - Flag [throwOnNextWrite] para simular falha de escrita
/// - Helpers de inspeção e pré-população para setup de testes
///
/// Não depende de nenhum plugin nativo — funciona em testes de unidade puros.
class FakeRelatorioRepository implements IRelatorioRepository {
  final Map<String, RelatorioTecnico> _store = {};

  /// Se `true`, o próximo método de escrita lança [Exception] e reseta para `false`.
  bool throwOnNextWrite = false;

  // ── Helpers públicos (para uso nos testes) ────────────────────────────

  /// Pré-popula o repositório com uma lista de relatórios.
  void seed(List<RelatorioTecnico> relatorios) {
    for (final r in relatorios) {
      _store[r.id] = r;
    }
  }

  /// Acesso direto por ID — inclui registros soft-deleted.
  RelatorioTecnico? get(String id) => _store[id];

  /// Contagem total, incluindo soft-deleted.
  int get count => _store.length;

  /// Remove todos os registros (útil em tearDown se necessário).
  void clear() => _store.clear();

  // ── IRelatorioRepository — Escrita ────────────────────────────────────

  @override
  Future<void> save(RelatorioTecnico relatorio) async {
    _checkThrow();
    _store[relatorio.id] = relatorio;
  }

  @override
  Future<void> update(RelatorioTecnico relatorio) async {
    _checkThrow();
    // Replica a lógica do RelatorioRepositoryImpl: bumpa updatedAt na escrita
    _store[relatorio.id] = relatorio.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ── IRelatorioRepository — Leitura ────────────────────────────────────

  @override
  Future<RelatorioTecnico?> getById(String id) async => _store[id];

  @override
  Future<List<RelatorioTecnico>> getAll() async {
    // Exclui soft-deleted (deletedAt != null) — igual à impl real
    return _store.values.where((r) => r.deletedAt == null).toList();
  }

  @override
  Future<List<RelatorioTecnico>> getByClientId(String clientId) async {
    return _store.values
        .where((r) => r.clientId == clientId && r.deletedAt == null)
        .toList();
  }

  @override
  Future<List<RelatorioTecnico>> getByAgronomistId(String agronomistId) async {
    return _store.values
        .where((r) => r.agronomistId == agronomistId && r.deletedAt == null)
        .toList();
  }

  @override
  Future<List<RelatorioTecnico>> getByStatus(RelatorioStatus status) async {
    return _store.values
        .where((r) => r.status == status && r.deletedAt == null)
        .toList();
  }

  @override
  Future<List<RelatorioTecnico>> getPendingSync() async {
    // local_only + pending_sync + deleted_local — igual à impl real
    const pendingStatuses = {
      RelatorioSyncStatus.local_only,
      RelatorioSyncStatus.pending_sync,
      RelatorioSyncStatus.deleted_local,
    };
    return _store.values
        .where((r) => pendingStatuses.contains(r.syncStatus))
        .toList();
  }

  // ── IRelatorioRepository — Soft Delete ───────────────────────────────

  @override
  Future<void> softDelete(String id) async {
    _checkThrow();
    final r = _store[id];
    if (r == null) return;
    // Preenche deletedAt, muda syncStatus para deleted_local — não remove do Map
    _store[id] = r.copyWith(
      deletedAt: DateTime.now().toUtc(),
      syncStatus: RelatorioSyncStatus.deleted_local,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ── IRelatorioRepository — Sincronização ─────────────────────────────

  @override
  Future<void> markAsSynced(String id) async {
    _checkThrow();
    final r = _store[id];
    if (r == null) return;
    _store[id] = r.copyWith(
      syncStatus: RelatorioSyncStatus.synced,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> markAsPendingSync(String id) async {
    _checkThrow();
    final r = _store[id];
    if (r == null) return;
    _store[id] = r.copyWith(
      syncStatus: RelatorioSyncStatus.pending_sync,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ── Internals ─────────────────────────────────────────────────────────

  void _checkThrow() {
    if (throwOnNextWrite) {
      throwOnNextWrite = false;
      throw Exception('FakeRelatorioRepository: Simulated write error');
    }
  }
}
