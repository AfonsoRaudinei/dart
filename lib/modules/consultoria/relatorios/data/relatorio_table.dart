/// Constantes de schema da tabela `relatorios` — ADR-009
///
/// Centraliza nome de tabela e colunas para evitar magic strings espalhadas
/// pela implementação do repositório.
///
/// O DDL de criação ([createDdl]) serve como referência documentada;
/// a migração real fica em `DatabaseHelper._migrateToV11`.
class RelatorioTable {
  RelatorioTable._();

  // ── Identificação ────────────────────────────────────────────────────

  static const String tableName = 'relatorios';

  // ── Colunas ──────────────────────────────────────────────────────────

  static const String colId = 'id';
  static const String colVisitSessionId = 'visit_session_id';
  static const String colClientId = 'client_id';
  static const String colAgronomistId = 'agronomist_id';
  static const String colFarmName = 'farm_name';
  static const String colPeriodStart = 'period_start';
  static const String colPeriodEnd = 'period_end';
  static const String colStatus = 'status';
  static const String colSyncStatus = 'sync_status';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colDeletedAt = 'deleted_at';
  static const String colTitle = 'title';
  static const String colCustomNotes = 'custom_notes';
  static const String colPublicacoesRefs = 'publicacoes_refs';
  static const String colOcorrencias = 'ocorrencias';
  static const String colTalhoes = 'talhoes';
  static const String colFotos = 'fotos';
  static const String colMonitoramentos = 'monitoramentos';

  // ── DDL (referência — migração em DatabaseHelper._migrateToV11) ──────

  /// SQL de criação da tabela — sincronizado com a migração v11.
  static const String createDdl = '''
    CREATE TABLE IF NOT EXISTS relatorios (
      id TEXT PRIMARY KEY,
      visit_session_id TEXT NOT NULL,
      client_id TEXT NOT NULL,
      agronomist_id TEXT NOT NULL,
      farm_name TEXT NOT NULL,
      period_start TEXT NOT NULL,
      period_end TEXT NOT NULL,
      status TEXT NOT NULL,
      sync_status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      title TEXT,
      custom_notes TEXT,
      publicacoes_refs TEXT NOT NULL DEFAULT '[]',
      ocorrencias TEXT NOT NULL DEFAULT '[]',
      talhoes TEXT NOT NULL DEFAULT '[]',
      fotos TEXT NOT NULL DEFAULT '[]',
      monitoramentos TEXT NOT NULL DEFAULT '[]'
    )
  ''';
}
