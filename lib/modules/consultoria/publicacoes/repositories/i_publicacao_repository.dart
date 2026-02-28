import '../models/publicacao_tecnica.dart';
import '../models/publicacao_tema.dart';

/// Contrato de persistência da Publicação Técnica — ADR-009
///
/// Separa a intenção de domínio da implementação concreta (SQLite, Supabase).
/// Toda camada que precise de dados de publicações deve depender DESTA interface,
/// nunca da classe concreta.
///
/// Regras offline-first (ADR-009):
///   - [save] persiste com [PublicacaoSyncStatus.local_only]
///   - [softDelete] jamais remove fisicamente — preenche [deletedAt]
///   - [markAsPendingSync] prepara para sincronização com o servidor
abstract class IPublicacaoRepository {
  // ── CRIAÇÃO / ESCRITA ────────────────────────────────────────────────

  /// Persiste uma nova [PublicacaoTecnica] localmente.
  ///
  /// Pré-condição: [publicacao.syncStatus] deve ser
  /// [PublicacaoSyncStatus.local_only] na criação inicial.
  Future<void> save(PublicacaoTecnica publicacao);

  /// Atualiza os dados de uma [PublicacaoTecnica] existente.
  ///
  /// A implementação deve atualizar o campo [updatedAt] automaticamente.
  Future<void> update(PublicacaoTecnica publicacao);

  // ── LEITURA ──────────────────────────────────────────────────────────

  /// Retorna a publicação pelo [id], ou [null] se não encontrada.
  Future<PublicacaoTecnica?> getById(String id);

  /// Retorna todas as publicações não deletadas.
  Future<List<PublicacaoTecnica>> getAll();

  /// Retorna publicações de um agrônomo específico.
  Future<List<PublicacaoTecnica>> getByAuthorId(String authorId);

  /// Retorna publicações filtradas por [tema].
  Future<List<PublicacaoTecnica>> getByTema(PublicacaoTema tema);

  /// Retorna publicações com [visibility] == [PublicacaoVisibility.publica].
  Future<List<PublicacaoTecnica>> getPublicas();

  /// Retorna publicações com [syncStatus] == [PublicacaoSyncStatus.pending_sync].
  Future<List<PublicacaoTecnica>> getPendingSync();

  // ── EXCLUSÃO LÓGICA (SOFT DELETE) ────────────────────────────────────

  /// Marca a publicação como excluída logicamente.
  ///
  /// Ações esperadas:
  ///   - Preenche [deletedAt] com o timestamp atual (UTC)
  ///   - Define [syncStatus] = [PublicacaoSyncStatus.deleted_local]
  ///
  /// PROIBIDO: deletar o registro físico do banco — ADR-009.
  Future<void> softDelete(String id);

  // ── SINCRONIZAÇÃO ────────────────────────────────────────────────────

  /// Marca a publicação como sincronizada com o servidor.
  /// Define [syncStatus] = [PublicacaoSyncStatus.synced].
  Future<void> markAsSynced(String id);

  /// Enfileira a publicação para sincronização com o servidor.
  /// Define [syncStatus] = [PublicacaoSyncStatus.pending_sync].
  Future<void> markAsPendingSync(String id);
}
