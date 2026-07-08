import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migrações SQLite — DatabaseMigrationsV1V23 (Fase 3).
class DatabaseMigrationsV1V23 {
  DatabaseMigrationsV1V23._();


  static Future<void> migrateToV1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        nome TEXT NOT NULL,
        documento TEXT,
        telefone TEXT,
        email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farms (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        cliente_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        area_total REAL,
        municipio TEXT,
        uf TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fields (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        fazenda_id TEXT NOT NULL,
        codigo TEXT,
        nome TEXT NOT NULL,
        area_produtiva REAL,
        bordadura_geo TEXT,
        centro_geo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (fazenda_id) REFERENCES farms (id)
      )
    ''');
  }

  static Future<void> migrateToV2(Database db) async {
    // Adição de colunas de sync e índices para performance
    try {
      await db.execute(
        'ALTER TABLE clients ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
    } catch (e) {
      AppLogger.debug(
        'V2: sync_status em clients já existe — $e',
        tag: 'DB.Migration',
      );
    }
    try {
      await db.execute(
        'ALTER TABLE farms ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
    } catch (e) {
      AppLogger.debug(
        'V2: sync_status em farms já existe — $e',
        tag: 'DB.Migration',
      );
    }
    try {
      await db.execute(
        'ALTER TABLE fields ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
    } catch (e) {
      AppLogger.debug(
        'V2: sync_status em fields já existe — $e',
        tag: 'DB.Migration',
      );
    }

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clients_nome ON clients(nome)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clients_sync ON clients(sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_farms_sync ON farms(sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_fields_sync ON fields(sync_status)',
    );
  }

  static Future<void> migrateToV3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        producer_id TEXT NOT NULL,
        area_id TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        initial_lat REAL,
        initial_long REAL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 1
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_sessions_status ON visit_sessions(status)',
    );
  }

  static Future<void> migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS occurrences (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        visit_session_id TEXT,
        type TEXT NOT NULL,
        description TEXT,
        photo_path TEXT,
        lat REAL,
        long REAL,
        geometry TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'local',
        category TEXT,
        status TEXT DEFAULT 'draft',
        FOREIGN KEY (visit_session_id) REFERENCES visit_sessions (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occurrences_session ON occurrences(visit_session_id)',
    );
  }

  static Future<void> migrateToV5(Database db) async {
    // Tabela legada da agenda (será destruída na v10)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agenda_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        producer_id TEXT NOT NULL,
        area_id TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        description TEXT,
        visit_session_id TEXT,
        status TEXT NOT NULL,
        realized_at TEXT,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (visit_session_id) REFERENCES visit_sessions (id)
      )
    ''');
  }

  static Future<void> migrateToV6(Database db) async {
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN updated_at TEXT');
    } catch (e) {
      AppLogger.debug(
        'V6: updated_at em occurrences já existe — $e',
        tag: 'DB.Migration',
      );
    }
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN category TEXT');
    } catch (e) {
      AppLogger.debug(
        'V6: category em occurrences já existe — $e',
        tag: 'DB.Migration',
      );
    }
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN status TEXT');
    } catch (e) {
      AppLogger.debug(
        'V6: status em occurrences já existe — $e',
        tag: 'DB.Migration',
      );
    }
    await db.execute(
      "UPDATE occurrences SET status = 'draft' WHERE status IS NULL",
    );
  }

  static Future<void> migrateToV7(Database db) async {
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN geometry TEXT');
    } catch (e) {
      AppLogger.debug(
        'V7: geometry em occurrences já existe — $e',
        tag: 'DB.Migration',
      );
    }
  }

  static Future<void> migrateToV8(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS drawings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        origem TEXT NOT NULL,
        status TEXT NOT NULL,
        geojson TEXT NOT NULL,
        area_ha REAL,
        autor_id TEXT NOT NULL,
        autor_tipo TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        versao INTEGER,
        subtipo TEXT,
        raio_metros REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        versao_anterior_id TEXT,
        referencia_id TEXT,
        ativo INTEGER DEFAULT 1
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_drawings_sync ON drawings(sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_drawings_ativo ON drawings(ativo)',
    );
  }

  static Future<void> migrateToV9(Database db) async {
    try {
      await db.execute('ALTER TABLE drawings ADD COLUMN cliente_id TEXT');
    } catch (e) {
      AppLogger.debug(
        'V9: cliente_id em drawings já existe — $e',
        tag: 'DB.Migration',
      );
    }
    try {
      await db.execute('ALTER TABLE drawings ADD COLUMN fazenda_id TEXT');
    } catch (e) {
      AppLogger.debug(
        'V9: fazenda_id em drawings já existe — $e',
        tag: 'DB.Migration',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_drawings_cliente_id ON drawings(cliente_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_drawings_fazenda_id ON drawings(fazenda_id)',
    );
  }

  static Future<void> migrateToV10(Database db) async {
    // 🎯 RECONSTRUÇÃO DA AGENDA (Incompatibilidade com schema v5)
    await DatabaseSchemaUtils.renameTableIfExists(db, 'agenda_events', 'agenda_events_v5_legacy');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS agenda_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        tipo TEXT NOT NULL,
        cliente_id TEXT NOT NULL,
        fazenda_id TEXT,
        talhao_id TEXT,
        titulo TEXT NOT NULL,
        data_inicio_planejada TEXT NOT NULL,
        data_fim_planejada TEXT NOT NULL,
        status TEXT NOT NULL,
        visit_session_id TEXT,
        serie_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS agenda_visit_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        evento_id TEXT NOT NULL,
        start_at_real TEXT NOT NULL,
        end_at_real TEXT,
        duracao_min INTEGER,
        notas_finais TEXT,
        checklist_snapshot TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (evento_id) REFERENCES agenda_events (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_agenda_events_cliente ON agenda_events(cliente_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_agenda_events_status ON agenda_events(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_agenda_events_data ON agenda_events(data_inicio_planejada)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_agenda_sessions_evento ON agenda_visit_sessions(evento_id)',
    );

    if (await DatabaseSchemaUtils.tableExists(db, 'agenda_events_v5_legacy')) {
      await db.execute('''
        INSERT OR IGNORE INTO agenda_events (
          id,
          user_id,
          tipo,
          cliente_id,
          talhao_id,
          titulo,
          data_inicio_planejada,
          data_fim_planejada,
          status,
          visit_session_id,
          created_at,
          updated_at,
          sync_status
        )
          SELECT
            id,
            user_id,
            activity_type,
            producer_id,
            area_id,
            COALESCE(NULLIF(description, ''), activity_type),
            scheduled_date,
            scheduled_date,
            status,
            visit_session_id,
            created_at,
            COALESCE(realized_at, created_at),
            CAST(sync_status AS TEXT)
          FROM agenda_events_v5_legacy
      ''');
    }
  }

  // ── V11, V12, V13: reservadas para próximas features ──────────────────
  static Future<void> migrateToV11(Database db) async {
    // Reservada — sem alterações nesta versão
    AppLogger.debug('V11: reservada (no-op)', tag: 'DB.Migration');
  }

  static Future<void> migrateToV12(Database db) async {
    // Reservada — sem alterações nesta versão
    AppLogger.debug('V12: reservada (no-op)', tag: 'DB.Migration');
  }

  static Future<void> migrateToV13(Database db) async {
    // Reservada — sem alterações nesta versão
    AppLogger.debug('V13: reservada (no-op)', tag: 'DB.Migration');
  }

  /// V14 — Schema agronômico de ocorrências (ADR-014)
  ///
  /// Adiciona 11 colunas opcionais à tabela [occurrences].
  /// Usa try/catch por coluna: idempotente em caso de re-execução.
  static Future<void> migrateToV14(Database db) async {
    final columns = <String, String>{
      'cultivar': 'TEXT',
      'data_plantio': 'TEXT',
      'estadio_fenologico': 'TEXT',
      'tipo_ocorrencia': 'TEXT',
      'amostra_solo': 'INTEGER DEFAULT 0',
      'recomendacoes': 'TEXT',
      'metricas_json': 'TEXT',
      'nutrientes_json': 'TEXT',
      'categorias_json': 'TEXT',
      'notas_categorias_json': 'TEXT',
      'fotos_categorias_json': 'TEXT',
    };
    for (final entry in columns.entries) {
      try {
        await db.execute(
          'ALTER TABLE occurrences ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V14: coluna ${entry.key} adicionada',
          tag: 'DB.Migration',
        );
      } catch (e) {
        AppLogger.debug(
          'V14: ${entry.key} já existe — $e',
          tag: 'DB.Migration',
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════

  /// V15 — Expansão da tabela clients com campos pessoais, agronômicos e foto.
  /// Cria tabela client_culturas (sub-entidade).
  /// Idempotente: cada ALTER TABLE é envolvido em try/catch individual.
  static Future<void> migrateToV15(Database db) async {
    final Map<String, String> newClientColumns = {
      'cidade': 'TEXT',
      'uf': 'TEXT',
      'foto_path': 'TEXT',
      'observacoes': 'TEXT',
      'data_nascimento': 'TEXT',
      'cpf_cnpj': 'TEXT',
      'area_total': 'REAL',
      'tipo_propriedade': 'TEXT',
      'sistema_irrigacao': 'TEXT',
      'solo_tipo': 'TEXT',
      'regiao_agricola': 'TEXT',
      'safra_atual': 'TEXT',
      'usa_assistencia_tecnica': 'INTEGER',
      'tecnico_responsavel': 'TEXT',
      'ativo': 'INTEGER NOT NULL DEFAULT 1',
    };

    for (final entry in newClientColumns.entries) {
      try {
        await db.execute(
          'ALTER TABLE clients ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V15: coluna ${entry.key} adicionada em clients',
          tag: 'DB.Migration',
        );
      } catch (_) {
        AppLogger.debug(
          'V15: ${entry.key} já existe em clients — ignorado',
          tag: 'DB.Migration',
        );
      }
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_culturas (
        id           TEXT PRIMARY KEY,
        user_id      TEXT NOT NULL DEFAULT '',
        client_id    TEXT NOT NULL,
        cultura      TEXT NOT NULL,
        area_ha      REAL NOT NULL,
        variedade    TEXT,
        safra        TEXT,
        observacao   TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_culturas_client ON client_culturas(client_id)',
    );
  }

  /// V16 — Adiciona producer_id em agenda_visit_sessions (WS-3 / ADR-017)
  /// Idempotente: envolve ALTER TABLE em try/catch.
  static Future<void> migrateToV16(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE agenda_visit_sessions ADD COLUMN producer_id TEXT',
      );
      AppLogger.debug(
        'V16: producer_id adicionado em agenda_visit_sessions',
        tag: 'DB.Migration',
      );
    } catch (_) {
      AppLogger.debug(
        'V16: producer_id já existe em agenda_visit_sessions — ignorado',
        tag: 'DB.Migration',
      );
    }
  }

  /// V17 — Campos agronômicos em drawings (Sprint 6)
  ///
  /// Adiciona: cultura, safra, soil_sampling_scheme, rec_by_nutrient.
  /// Idempotente: cada ALTER TABLE é envolvido em try/catch individual.
  static Future<void> migrateToV17(Database db) async {
    final columns = <String, String>{
      'cultura': 'TEXT',
      'safra': 'TEXT',
      'soil_sampling_scheme': 'TEXT',
      'rec_by_nutrient': 'TEXT', // JSON Map<String, double>
    };
    for (final entry in columns.entries) {
      try {
        await db.execute(
          'ALTER TABLE drawings ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V17: coluna ${entry.key} adicionada em drawings',
          tag: 'DB.Migration',
        );
      } catch (e) {
        AppLogger.debug(
          'V17: ${entry.key} já existe em drawings — $e',
          tag: 'DB.Migration',
        );
      }
    }
  }

  /// V18 — Remove NOT NULL de area_id e activity_type em visit_sessions
  ///
  /// Contexto: check-in agora exige apenas producer_id. Fazenda/Talhão/Atividade
  /// passaram a ser opcionais na criação da sessão (podem ser preenchidos depois).
  ///
  /// SQLite não suporta ALTER COLUMN — reconstrução de tabela via:
  /// 1. Criar visit_sessions_v18 com colunas nullable
  /// 2. Copiar todos os dados existentes
  /// 3. Drop visit_sessions original
  /// 4. Renomear visit_sessions_v18
  /// 5. Recriar índice
  ///
  /// Idempotente: IF NOT EXISTS + DROP IF EXISTS garantem segurança em re-execução.
  static Future<void> migrateToV18(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_sessions_v18 (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        producer_id TEXT NOT NULL,
        area_id TEXT,
        activity_type TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        initial_lat REAL,
        initial_long REAL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 1
      )
    ''');

    // Copia dados existentes. Linhas com area_id='' (workaround anterior)
    // são convertidas para NULL para consistência semântica.
    await db.execute('''
      INSERT INTO visit_sessions_v18 (
        id,
        user_id,
        producer_id,
        area_id,
        activity_type,
        start_time,
        end_time,
        initial_lat,
        initial_long,
        status,
        created_at,
        updated_at,
        sync_status
      )
        SELECT
          id,
          user_id,
          producer_id,
          NULLIF(area_id, ''),
          NULLIF(activity_type, ''),
          start_time,
          end_time,
          initial_lat,
          initial_long,
          status,
          created_at,
          updated_at,
          sync_status
        FROM visit_sessions
    ''');

    await DatabaseSchemaUtils.renameTableIfExists(
      db,
      'visit_sessions',
      'visit_sessions_v17_legacy',
    );
    await db.execute('ALTER TABLE visit_sessions_v18 RENAME TO visit_sessions');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_sessions_status ON visit_sessions(status)',
    );

    AppLogger.debug(
      'V18: visit_sessions reconstruída — area_id e activity_type agora nullable',
      tag: 'DB.Migration',
    );
  }

  // ════════════════════════════════════════════════════════════════

  /// V20 — Cache local de dados climáticos (módulo clima/).
  ///
  /// Cria 3 tabelas com TTL de 15 minutos (gerenciado pelo ClimaLocalDatasource):
  ///   - [clima_atual_cache]   → condição atual por coordenada
  ///   - [clima_horaria_cache] → previsão horária (payload JSON)
  ///   - [clima_diaria_cache]  → previsão semanal (payload JSON)
  /// Idempotente: CREATE TABLE IF NOT EXISTS.
  static Future<void> migrateToV20(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clima_atual_cache (
        cache_key        TEXT PRIMARY KEY,
        user_id          TEXT NOT NULL DEFAULT '',
        temperatura      REAL NOT NULL,
        sensacao_termica REAL NOT NULL,
        condicao         TEXT NOT NULL,
        condicao_codigo  TEXT NOT NULL,
        vento_velocidade REAL NOT NULL,
        vento_direcao    TEXT NOT NULL,
        umidade          INTEGER NOT NULL,
        precipitacao     REAL NOT NULL,
        pressao          REAL NOT NULL,
        visibilidade     REAL NOT NULL,
        cobertura_nuvens INTEGER NOT NULL,
        indice_uv        INTEGER NOT NULL,
        nascer_sol       TEXT NOT NULL,
        por_sol          TEXT NOT NULL,
        latitude         REAL NOT NULL,
        longitude        REAL NOT NULL,
        cidade           TEXT NOT NULL,
        atualizado_em    TEXT NOT NULL,
        cached_at        TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clima_horaria_cache (
        cache_key TEXT PRIMARY KEY,
        user_id   TEXT NOT NULL DEFAULT '',
        payload   TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clima_diaria_cache (
        cache_key TEXT PRIMARY KEY,
        user_id   TEXT NOT NULL DEFAULT '',
        payload   TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    AppLogger.debug('V20: tabelas de cache clima criadas', tag: 'DB.Migration');
  }

  // ════════════════════════════════════════════════════════════════════

  /// V19 — Cache local de imagens NDVI (módulo ndvi/).
  ///
  /// Cria tabela [ndvi_cache] para armazenar a última imagem NDVI por talhão
  /// (area_id + date), com validade de 24h.
  /// Idempotente: CREATE TABLE IF NOT EXISTS.
  static Future<void> migrateToV19(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ndvi_cache (
        id           TEXT PRIMARY KEY,
        user_id      TEXT NOT NULL DEFAULT '',
        area_id      TEXT NOT NULL,
        date         TEXT NOT NULL,
        source       TEXT NOT NULL,
        image_path   TEXT NOT NULL,
        cloud_coverage REAL,
        available_dates TEXT NOT NULL,
        cached_at    TEXT NOT NULL,
        UNIQUE(area_id, date)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ndvi_cache_area ON ndvi_cache(area_id)',
    );

    AppLogger.debug('V19: tabela ndvi_cache criada', tag: 'DB.Migration');
  }

  /// V21 — Isolamento local por usuário autenticado.
  ///
  /// Adiciona a coluna `user_id` em todas as tabelas locais persistidas.
  /// Idempotente: cada ALTER TABLE é envolvido em try/catch individual.
  static Future<void> migrateToV21(Database db) async {
    const tables = [
      'clients',
      'farms',
      'fields',
      'visit_sessions',
      'occurrences',
      'visit_reports',
      'agenda_events',
      'agenda_visit_sessions',
      'drawings',
      'client_culturas',
      'clima_atual_cache',
      'clima_horaria_cache',
      'clima_diaria_cache',
      'ndvi_cache',
      'publicacoes_tecnicas',
      'relatorios',
      'relatorios_v2',
    ];

    for (final table in tables) {
      try {
        await db.execute(
          "ALTER TABLE $table ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
        );
        AppLogger.debug(
          'V21: user_id adicionado em $table',
          tag: 'DB.Migration',
        );
      } catch (_) {
        AppLogger.debug(
          'V21: user_id já existe em $table ou tabela ausente — ignorado',
          tag: 'DB.Migration',
        );
      }
    }
  }

  /// V22 — Módulo carteira (categorias e percentual por cliente).
  ///
  /// Cria tabelas locais do bounded context carteira/.
  /// Idempotente: CREATE TABLE/INDEX IF NOT EXISTS.
  static Future<void> migrateToV22(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_categorias (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL DEFAULT '',
        nome        TEXT NOT NULL,
        cor         TEXT NOT NULL DEFAULT '#4ADE80',
        ativo       INTEGER NOT NULL DEFAULT 1,
        ordem       INTEGER NOT NULL DEFAULT 0,
        valor_real  REAL,
        valor_dolar REAL,
        sacas_por_ha REAL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS carteira_cliente_categorias (
        id                  TEXT PRIMARY KEY,
        user_id             TEXT NOT NULL DEFAULT '',
        cliente_id          TEXT NOT NULL,
        categoria_id        TEXT NOT NULL,
        percentual_fechado  INTEGER NOT NULL DEFAULT 0,
        observacao          TEXT,
        updated_at          TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES carteira_categorias(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_carteira_cliente_user
        ON carteira_cliente_categorias(user_id, cliente_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_carteira_cat_user
        ON carteira_categorias(user_id, ativo)
    ''');

    AppLogger.debug(
      'V22: tabelas do módulo carteira criadas',
      tag: 'DB.Migration',
    );
  }

  /// V23 — Carteira: valores opcionais por categoria.
  ///
  /// Adiciona colunas opcionais em `carteira_categorias`.
  /// Idempotente: cada ALTER TABLE é envolvido em try/catch individual.
  static Future<void> migrateToV23(Database db) async {
    const statements = <String>[
      'ALTER TABLE carteira_categorias ADD COLUMN valor_real REAL',
      'ALTER TABLE carteira_categorias ADD COLUMN valor_dolar REAL',
      'ALTER TABLE carteira_categorias ADD COLUMN sacas_por_ha REAL',
    ];

    for (final sql in statements) {
      try {
        await db.execute(sql);
        AppLogger.debug('V23: executado "$sql"', tag: 'DB.Migration');
      } catch (_) {
        AppLogger.debug(
          'V23: coluna já existe ou tabela ausente — ignorado',
          tag: 'DB.Migration',
        );
      }
    }
  }

  /// V24 — ADR-022: Sistema de Metas, Safra e Lançamentos.
  /// Cria tabelas: carteira_config, carteira_safras,
  ///               carteira_metas, carteira_lancamentos.
  /// Adiciona colunas em carteira_categorias: unidade, valor_referencia.
}
