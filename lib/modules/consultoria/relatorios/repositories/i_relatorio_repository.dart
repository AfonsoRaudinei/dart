import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';

/// Contrato de persistência do Relatório Técnico — ADR-009
///
/// Separa a intenção de domínio da implementação concreta (SQLite, Supabase).
/// Toda camada que precise de dados de relatórios deve depender DESTA interface,
/// nunca da classe concreta.
///
/// Regras offline-first (ADR-009):
///   - [save] persiste com [RelatorioSyncStatus.local_only]
///   - [softDelete] jamais remove fisicamente — preenche [deletedAt]
///   - [markAsPendingSync] prepara para sincronização com o servidor
abstract class IRelatorioRepository {
  // ── CRIAÇÃO / ESCRITA ────────────────────────────────────────────────

  /// Persiste um novo [RelatorioTecnico] localmente.
  ///
  /// Pré-condição: [relatorio.syncStatus] deve ser
  /// [RelatorioSyncStatus.local_only] na criação inicial.
  Future<void> save(RelatorioTecnico relatorio);

  /// Atualiza os dados de um [RelatorioTecnico] existente.
  ///
  /// A implementação deve atualizar o campo [updatedAt] automaticamente.
  Future<void> update(RelatorioTecnico relatorio);

  // ── LEITURA ──────────────────────────────────────────────────────────

  /// Retorna o relatório pelo [id], ou [null] se não encontrado.
  Future<RelatorioTecnico?> getById(String id);

  /// Retorna todos os relatórios não deletados.
  Future<List<RelatorioTecnico>> getAll();

  /// Retorna relatórios associados a um cliente específico.
  Future<List<RelatorioTecnico>> getByClientId(String clientId);

  /// Retorna relatórios do agrônomo especificado.
  Future<List<RelatorioTecnico>> getByAgronomistId(String agronomistId);

  /// Retorna relatórios filtrados por [status].
  Future<List<RelatorioTecnico>> getByStatus(RelatorioStatus status);

  /// Retorna relatórios com [syncStatus] == [RelatorioSyncStatus.pending_sync].
  Future<List<RelatorioTecnico>> getPendingSync();

  // ── EXCLUSÃO LÓGICA (SOFT DELETE) ────────────────────────────────────

  /// Marca o relatório como excluído logicamente.
  ///
  /// Ações esperadas:
  ///   - Preenche [deletedAt] com o timestamp atual (UTC)
  ///   - Define [syncStatus] = [RelatorioSyncStatus.deleted_local]
  ///
  /// PROIBIDO: deletar o registro físico do banco — ADR-009.
  Future<void> softDelete(String id);

  // ── SINCRONIZAÇÃO ────────────────────────────────────────────────────

  /// Marca o relatório como sincronizado com o servidor.
  /// Define [syncStatus] = [RelatorioSyncStatus.synced].
  Future<void> markAsSynced(String id);

  /// Enfileira o relatório para sincronização com o servidor.
  /// Define [syncStatus] = [RelatorioSyncStatus.pending_sync].
  Future<void> markAsPendingSync(String id);
}
