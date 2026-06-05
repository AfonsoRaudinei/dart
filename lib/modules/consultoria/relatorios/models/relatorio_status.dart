// ignore_for_file: constant_identifier_names

/// Enums de status do Relatório Técnico — ADR-009
///
/// Define o ciclo de vida de um [RelatorioTecnico] e seu status
/// de sincronização offline-first.
library;

// ============================================================
// CICLO DE VIDA DO RELATÓRIO
// ============================================================

/// Status que define a etapa atual do relatório no fluxo de revisão.
///
/// - [pendente_revisao]: gerado automaticamente ao finalizar VisitSession.
///   Editável pelo agrônomo. NÃO visível ao produtor.
/// - [publicado]: agrônomo aprovou. Visível ao produtor e ao agrônomo.
/// - [arquivado]: encerrado. Mantido para histórico (somente leitura).
enum RelatorioStatus {
  pendente_revisao,
  publicado,
  arquivado;

  String toJson() => name;

  static RelatorioStatus fromJson(String json) => values.byName(json);
}

// ============================================================
// SINCRONIZAÇÃO OFFLINE-FIRST
// ============================================================

/// Status de sincronização offline-first do relatório.
///
/// Todo [RelatorioTecnico] é criado com [local_only] como valor inicial.
/// A transição para [synced] ocorre apenas após confirmação do backend.
///
/// - [local_only]: salvo apenas no dispositivo — nunca enviado ao servidor.
/// - [pending_sync]: aguardando envio para o servidor.
/// - [synced]: sincronizado com sucesso.
/// - [sync_error]: erro na última tentativa de sincronização.
/// - [deleted_local]: marcado para exclusão lógica (soft delete local).
enum RelatorioSyncStatus {
  local_only,
  pending_sync,
  synced,
  sync_error,
  deleted_local;

  String toJson() => name;

  static RelatorioSyncStatus fromJson(String json) => values.byName(json);
}
