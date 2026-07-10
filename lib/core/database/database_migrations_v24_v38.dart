import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migrações SQLite — DatabaseMigrationsV24V38 (Fase 3).
class DatabaseMigrationsV24V38 {
  DatabaseMigrationsV24V38._();

  static Future<void> migrateToV24(Database db) async {
    // Config global do usuário (valor do grão)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_config (
        user_id    TEXT PRIMARY KEY,
        valor_grao REAL NOT NULL DEFAULT 0.0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Safras
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_safras (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL DEFAULT '',
        nome        TEXT NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim    TEXT NOT NULL,
        ativa       INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_carteira_safras_user
        ON carteira_safras(user_id, ativa)
    ''');

    // Metas por categoria × safra
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_metas (
        id           TEXT PRIMARY KEY,
        user_id      TEXT NOT NULL DEFAULT '',
        safra_id     TEXT NOT NULL,
        categoria_id TEXT NOT NULL,
        quantidade   REAL NOT NULL DEFAULT 0.0,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        UNIQUE(user_id, safra_id, categoria_id)
      )
    ''');

    // Lançamentos de realizado
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_lancamentos (
        id               TEXT PRIMARY KEY,
        user_id          TEXT NOT NULL DEFAULT '',
        safra_id         TEXT NOT NULL,
        categoria_id     TEXT NOT NULL,
        cliente_id       TEXT NOT NULL,
        quantidade       REAL NOT NULL,
        observacao       TEXT,
        data_lancamento  TEXT NOT NULL,
        created_at       TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_carteira_lancamentos_safra_cat
        ON carteira_lancamentos(user_id, safra_id, categoria_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_carteira_lancamentos_cliente
        ON carteira_lancamentos(user_id, cliente_id, safra_id)
    ''');

    // Adicionar unidade em carteira_categorias (idempotente)
    try {
      await db.execute(
        'ALTER TABLE carteira_categorias '
        'ADD COLUMN unidade TEXT NOT NULL DEFAULT "realPorHa"',
      );
    } catch (_) {
      AppLogger.debug('V24: coluna unidade já existente', tag: 'DB.Migration');
    }

    // Adicionar valor_referencia em carteira_categorias (idempotente)
    try {
      await db.execute(
        'ALTER TABLE carteira_categorias '
        'ADD COLUMN valor_referencia REAL',
      );
    } catch (_) {
      AppLogger.debug(
        'V24: coluna valor_referencia já existente',
        tag: 'DB.Migration',
      );
    }

    // Migrar dados existentes: valor_real → valor_referencia
    await db.execute('''
      UPDATE carteira_categorias
      SET valor_referencia = valor_real
      WHERE valor_referencia IS NULL AND valor_real IS NOT NULL
    ''');

    AppLogger.debug(
      'V24: carteira_config, carteira_safras, carteira_metas, '
      'carteira_lancamentos criadas. carteira_categorias atualizada.',
      tag: 'DB',
    );
  }

  /// V25 — Carteira: tipo de fechamento em lançamentos.
  ///
  /// Adiciona colunas opcionais em `carteira_lancamentos`:
  /// - tipo_fechamento
  /// - nome_concorrente
  /// - motivo_fechamento
  ///
  /// Idempotente: cada ALTER TABLE é envolvido em try/catch individual.
  static Future<void> migrateToV25(Database db) async {
    const statements = <String>[
      'ALTER TABLE carteira_lancamentos ADD COLUMN tipo_fechamento TEXT',
      'ALTER TABLE carteira_lancamentos ADD COLUMN nome_concorrente TEXT',
      'ALTER TABLE carteira_lancamentos ADD COLUMN motivo_fechamento TEXT',
    ];

    for (final sql in statements) {
      try {
        await db.execute(sql);
        AppLogger.debug('V25: executado "$sql"', tag: 'DB.Migration');
      } catch (_) {
        AppLogger.debug(
          'V25: coluna já existe ou tabela ausente — ignorado',
          tag: 'DB.Migration',
        );
      }
    }
  }

  /// V26 — Carteira: data de fechamento opcional em lançamentos.
  ///
  /// Adiciona coluna opcional em `carteira_lancamentos`:
  /// - data_fechamento
  ///
  /// Idempotente: ALTER TABLE envolvido em try/catch.
  static Future<void> migrateToV26(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE carteira_lancamentos ADD COLUMN data_fechamento TEXT',
      );
      AppLogger.debug(
        'V26: executado "ALTER TABLE carteira_lancamentos ADD COLUMN data_fechamento TEXT"',
        tag: 'DB.Migration',
      );
    } catch (_) {
      AppLogger.debug(
        'V26: coluna já existe ou tabela ausente — ignorado',
        tag: 'DB.Migration',
      );
    }
  }

  /// V27 — NDVI: recria ndvi_cache com novo schema.
  ///
  /// A tabela antiga (V19) usava area_id, date, image_path, available_dates.
  /// O novo schema usa field_id, image_date, ndvi_min, ndvi_max, ndvi_mean,
  /// sync_status — alinhado com o contrato NdviImage.
  ///
  /// Estratégia: DROP + CREATE (dados são cache efêmero, regeneráveis).
  /// Idempotente: CREATE TABLE IF NOT EXISTS garante segurança em re-execução.
  static Future<void> migrateToV27(Database db) async {
    try {
      await DatabaseSchemaUtils.renameTableIfExists(db, 'ndvi_cache', 'ndvi_cache_v19_legacy');
      AppLogger.debug(
        'V27: ndvi_cache antiga preservada como ndvi_cache_v19_legacy',
        tag: 'DB.Migration',
      );
    } catch (_) {
      AppLogger.debug('V27: backup ndvi_cache — ignorado', tag: 'DB.Migration');
    }
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ndvi_cache (
          id           TEXT PRIMARY KEY,
          user_id      TEXT NOT NULL DEFAULT '',
          field_id     TEXT NOT NULL,
          image_date   TEXT NOT NULL,
          ndvi_min     REAL NOT NULL DEFAULT 0.0,
          ndvi_max     REAL NOT NULL DEFAULT 0.0,
          ndvi_mean    REAL NOT NULL DEFAULT 0.0,
          image_url    TEXT,
          local_path   TEXT,
          source       TEXT NOT NULL,
          fetched_at   TEXT NOT NULL,
          sync_status  INTEGER NOT NULL DEFAULT 0,
          UNIQUE(field_id, image_date)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ndvi_cache_field ON ndvi_cache(field_id)',
      );
      if (await DatabaseSchemaUtils.tableExists(db, 'ndvi_cache_v19_legacy')) {
        await db.execute('''
          INSERT OR IGNORE INTO ndvi_cache (
            id,
            user_id,
            field_id,
            image_date,
            ndvi_min,
            ndvi_max,
            ndvi_mean,
            local_path,
            source,
            fetched_at,
            sync_status
          )
            SELECT
              id,
              user_id,
              area_id,
              date,
              0.0,
              0.0,
              0.0,
              image_path,
              source,
              cached_at,
              0
            FROM ndvi_cache_v19_legacy
        ''');
      }
      AppLogger.debug(
        'V27: ndvi_cache recriada com novo schema',
        tag: 'DB.Migration',
      );
    } catch (_) {
      AppLogger.debug(
        'V27: criação ndvi_cache — ignorado',
        tag: 'DB.Migration',
      );
    }
  }

  /// V28 — Occurrences: vínculo opcional com cliente (ADR-014/ADR-015).
  ///
  /// Adiciona coluna nullable `client_id` em `occurrences`.
  /// Idempotente: ALTER TABLE envolvido em try/catch.
  static Future<void> migrateToV28(Database db) async {
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN client_id TEXT');
      AppLogger.debug(
        'V28: client_id adicionado em occurrences',
        tag: 'DB.Migration',
      );
    } catch (_) {
      AppLogger.debug(
        'V28: client_id já existe em occurrences — ignorado',
        tag: 'DB.Migration',
      );
    }
  }

  /// V29 — Carteira: adiciona closed_percent em carteira_lancamentos.
  static Future<void> migrateToV29(Database db) async {
    try {
      await db.execute('''
        ALTER TABLE carteira_lancamentos
        ADD COLUMN closed_percent REAL NOT NULL DEFAULT 0.0
      ''');
      AppLogger.debug(
        'V29: closed_percent adicionado em carteira_lancamentos',
        tag: 'DB.Migration',
      );
    } catch (_) {
      AppLogger.debug(
        'V29: closed_percent já existe em carteira_lancamentos — ignorado',
        tag: 'DB.Migration',
      );
    }
  }

  static Future<void> migrateToV30(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile_cache (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        full_name TEXT,
        phone TEXT,
        role TEXT,
        photo_url TEXT,
        crea_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile_edits (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        field_changed TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT NOT NULL,
        changed_at TEXT NOT NULL
      )
    ''');

    AppLogger.debug(
      'V30: user_profile_cache e user_profile_edits criadas',
      tag: 'DB.Migration',
    );
  }

  // ADR-034: Limpeza do legado reports/ (visit_reports)
  static Future<void> migrateToV31(Database db) async {
    debugPrint('[DB] Migrando para V31: arquivar tabela visit_reports');
    await DatabaseSchemaUtils.renameTableIfExists(db, 'visit_reports', 'visit_reports_legacy_v31');
  }

  static Future<void> migrateToV32(Database db) async {
    await db.execute('''
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
        monitoramentos TEXT NOT NULL DEFAULT '[]',
        user_id TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Mantém a fazenda escolhida no check-in mesmo quando não há talhão.
  static Future<void> migrateToV33(Database db) async {
    try {
      await db.execute('ALTER TABLE visit_sessions ADD COLUMN farm_id TEXT');
      AppLogger.debug(
        'V33: farm_id adicionado em visit_sessions',
        tag: 'DB.Migration',
      );
    } catch (e) {
      AppLogger.debug(
        'V33: farm_id já existe em visit_sessions — $e',
        tag: 'DB.Migration',
      );
    }
  }

  static Future<void> migrateToV34(Database db) async {
    final columns = <String, String>{
      'report_brand_name': 'TEXT',
      'report_logo_url': 'TEXT',
    };
    for (final entry in columns.entries) {
      try {
        await db.execute(
          'ALTER TABLE user_profile_cache ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V34: coluna ${entry.key} adicionada em user_profile_cache',
          tag: 'DB.Migration',
        );
      } catch (e) {
        AppLogger.debug(
          'V34: ${entry.key} já existe em user_profile_cache — $e',
          tag: 'DB.Migration',
        );
      }
    }
  }

  static Future<void> migrateToV35(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quick_photos (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        visit_session_id TEXT,
        local_path TEXT NOT NULL,
        storage_path TEXT,
        public_url TEXT,
        lat REAL,
        lng REAL,
        photo_type TEXT NOT NULL DEFAULT 'normal',
        created_at TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (visit_session_id) REFERENCES visit_sessions (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quick_photos_visit_session '
      'ON quick_photos(visit_session_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quick_photos_sync '
      'ON quick_photos(sync_status)',
    );
    AppLogger.debug('V35: tabela quick_photos criada', tag: 'DB.Migration');
  }

  static Future<void> migrateToV36(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS producer_client_links (
        id TEXT PRIMARY KEY,
        consultor_user_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        producer_user_id TEXT,
        status TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        used_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_producer_links_producer '
      'ON producer_client_links(producer_user_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_producer_links_client '
      'ON producer_client_links(client_id)',
    );
  }

  static Future<void> migrateToV37(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS relatorios_v2 (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        deleted_at TEXT,
        visit_session_id TEXT,
        occurrence_ids TEXT,
        user_id TEXT NOT NULL DEFAULT ''
      )
    ''');

    if (!await DatabaseSchemaUtils.columnExists(db, 'relatorios_v2', 'client_id')) {
      await db.execute('ALTER TABLE relatorios_v2 ADD COLUMN client_id TEXT');
    }

    if (!await DatabaseSchemaUtils.columnExists(db, 'relatorios_v2', 'user_id')) {
      await db.execute(
        "ALTER TABLE relatorios_v2 ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
      );
    }

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_relatorios_v2_client_id '
      'ON relatorios_v2(client_id)',
    );
  }

  static Future<void> migrateToV38(Database db) async {
    const columns = <String, String>{
      'remote_id': 'TEXT',
      'cached_by_user_id': 'TEXT',
      'external_source': 'TEXT',
      'external_analysis_id': 'TEXT',
      'analysis_payload_json': 'TEXT',
      'deleted_at': 'TEXT',
    };
    for (final entry in columns.entries) {
      if (!await DatabaseSchemaUtils.columnExists(db, 'occurrences', entry.key)) {
        await db.execute(
          'ALTER TABLE occurrences ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occurrences_remote_id '
      'ON occurrences(remote_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occurrences_cached_by '
      'ON occurrences(cached_by_user_id, client_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occurrences_external_analysis '
      'ON occurrences(external_source, external_analysis_id)',
    );
  }

  /// V39 — Carteira: tipos de produto dinâmicos por usuário.
  static Future<void> migrateToV39(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_tipos_produto (
        id                 TEXT PRIMARY KEY,
        user_id            TEXT NOT NULL,
        codigo             TEXT NOT NULL,
        label              TEXT NOT NULL,
        converte_sacas_ha  INTEGER NOT NULL DEFAULT 0,
        sistema            INTEGER NOT NULL DEFAULT 0,
        ativo              INTEGER NOT NULL DEFAULT 1,
        ordem              INTEGER NOT NULL DEFAULT 0,
        created_at         TEXT NOT NULL,
        updated_at         TEXT NOT NULL,
        UNIQUE(user_id, codigo)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_carteira_tipos_produto_user
        ON carteira_tipos_produto(user_id, ativo)
    ''');
  }

  /// V40 — Agenda: persiste horário, prioridade e geo do evento.
  static Future<void> migrateToV40(Database db) async {
    const columns = <String, String>{
      'start_time': 'TEXT',
      'end_time': 'TEXT',
      'priority': "TEXT NOT NULL DEFAULT 'normal'",
      'latitude': 'REAL',
      'longitude': 'REAL',
    };

    for (final entry in columns.entries) {
      if (!await DatabaseSchemaUtils.columnExists(
        db,
        'agenda_events',
        entry.key,
      )) {
        await db.execute(
          'ALTER TABLE agenda_events ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }
}
