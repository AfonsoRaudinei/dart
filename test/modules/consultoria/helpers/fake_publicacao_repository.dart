import 'package:soloforte_app/modules/consultoria/publicacoes/models/publicacao_tecnica.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/models/publicacao_tema.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/repositories/i_publicacao_repository.dart';

/// Implementação em memória de [IPublicacaoRepository] para testes.
///
/// Segue o padrão estabelecido pelo [FakeAgendaRepository]:
/// - Estado em `Map<String, PublicacaoTecnica>` — sem SQLite
/// - Flag [throwOnNextWrite] para simular falha de escrita
/// - Helpers de inspeção e pré-população para setup de testes
///
/// Não depende de nenhum plugin nativo — funciona em testes de unidade puros.
class FakePublicacaoRepository implements IPublicacaoRepository {
  final Map<String, PublicacaoTecnica> _store = {};

  /// Se `true`, o próximo método de escrita lança [Exception] e reseta para `false`.
  bool throwOnNextWrite = false;

  // ── Helpers públicos (para uso nos testes) ────────────────────────────

  /// Pré-popula o repositório com uma lista de publicações.
  void seed(List<PublicacaoTecnica> publicacoes) {
    for (final p in publicacoes) {
      _store[p.id] = p;
    }
  }

  /// Acesso direto por ID — inclui registros soft-deleted.
  PublicacaoTecnica? get(String id) => _store[id];

  /// Contagem total, incluindo soft-deleted.
  int get count => _store.length;

  /// Remove todos os registros (útil em tearDown se necessário).
  void clear() => _store.clear();

  // ── IPublicacaoRepository — Escrita ──────────────────────────────────

  @override
  Future<void> save(PublicacaoTecnica publicacao) async {
    _checkThrow();
    _store[publicacao.id] = publicacao;
  }

  @override
  Future<void> update(PublicacaoTecnica publicacao) async {
    _checkThrow();
    // Replica a lógica do PublicacaoRepositoryImpl: bumpa updatedAt na escrita
    _store[publicacao.id] = publicacao.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ── IPublicacaoRepository — Leitura ──────────────────────────────────

  @override
  Future<PublicacaoTecnica?> getById(String id) async => _store[id];

  @override
  Future<List<PublicacaoTecnica>> getAll() async {
    // Exclui soft-deleted (deletedAt != null) — igual à impl real
    return _store.values.where((p) => p.deletedAt == null).toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getByAuthorId(String authorId) async {
    return _store.values
        .where((p) => p.authorId == authorId && p.deletedAt == null)
        .toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getByTema(PublicacaoTema tema) async {
    return _store.values
        .where((p) => p.tema == tema && p.deletedAt == null)
        .toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getPublicas() async {
    return _store.values
        .where(
          (p) =>
              p.visibility == PublicacaoVisibility.publica &&
              p.deletedAt == null,
        )
        .toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getPendingSync() async {
    // local_only + pending_sync + deleted_local — igual à impl real
    const pendingStatuses = {
      PublicacaoSyncStatus.local_only,
      PublicacaoSyncStatus.pending_sync,
      PublicacaoSyncStatus.deleted_local,
    };
    return _store.values
        .where((p) => pendingStatuses.contains(p.syncStatus))
        .toList();
  }

  // ── IPublicacaoRepository — Soft Delete ──────────────────────────────

  @override
  Future<void> softDelete(String id) async {
    _checkThrow();
    final p = _store[id];
    if (p == null) return;
    // Preenche deletedAt, muda syncStatus para deleted_local — não remove do Map
    _store[id] = p.copyWith(
      deletedAt: DateTime.now().toUtc(),
      syncStatus: PublicacaoSyncStatus.deleted_local,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ── IPublicacaoRepository — Sincronização ────────────────────────────

  @override
  Future<void> markAsSynced(String id) async {
    _checkThrow();
    final p = _store[id];
    if (p == null) return;
    _store[id] = p.copyWith(
      syncStatus: PublicacaoSyncStatus.synced,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> markAsPendingSync(String id) async {
    _checkThrow();
    final p = _store[id];
    if (p == null) return;
    _store[id] = p.copyWith(
      syncStatus: PublicacaoSyncStatus.pending_sync,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ── Internals ─────────────────────────────────────────────────────────

  void _checkThrow() {
    if (throwOnNextWrite) {
      throwOnNextWrite = false;
      throw Exception('FakePublicacaoRepository: Simulated write error');
    }
  }
}
