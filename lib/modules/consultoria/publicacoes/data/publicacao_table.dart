/// Constantes de schema da tabela `publicacoes_tecnicas` — ADR-009
///
/// Centraliza nome de tabela e colunas para evitar magic strings espalhadas
/// pela implementação do repositório.
///
/// O DDL de criação ([createDdl]) serve como referência documentada;
/// a migração real fica em `DatabaseHelper._migrateToV12`.
class PublicacaoTable {
  PublicacaoTable._();

  // ── Identificação ────────────────────────────────────────────────────

  static const String tableName = 'publicacoes_tecnicas';

  // ── Colunas ──────────────────────────────────────────────────────────

  static const String colId = 'id';
  static const String colAuthorId = 'author_id';
  static const String colTema = 'tema';
  static const String colTitulo = 'titulo';
  static const String colConteudo = 'conteudo';
  static const String colVisibility = 'visibility';
  static const String colSyncStatus = 'sync_status';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colDeletedAt = 'deleted_at';
  static const String colFotoPaths = 'foto_paths';
  static const String colTalhaoRef = 'talhao_ref';
  static const String colFazendaRef = 'fazenda_ref';
  static const String colSafra = 'safra';

  // ── DDL (referência — migração em DatabaseHelper._migrateToV12) ──────

  /// SQL de criação da tabela — sincronizado com a migração v12.
  static const String createDdl = '''
    CREATE TABLE IF NOT EXISTS publicacoes_tecnicas (
      id          TEXT PRIMARY KEY,
      author_id   TEXT NOT NULL,
      tema        TEXT NOT NULL,
      titulo      TEXT NOT NULL,
      conteudo    TEXT NOT NULL,
      visibility  TEXT NOT NULL,
      sync_status TEXT NOT NULL,
      created_at  TEXT NOT NULL,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT,
      foto_paths  TEXT NOT NULL DEFAULT '[]',
      talhao_ref  TEXT,
      fazenda_ref TEXT,
      safra       TEXT
    )
  ''';
}
