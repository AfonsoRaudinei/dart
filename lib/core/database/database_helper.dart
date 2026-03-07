import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../utils/app_logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'soloforte.db');

    final db = await openDatabase(
      path,
      version: 19,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // 🎯 Validação de integridade pós-boot
    await _validateSchema(db);

    return db;
  }

  // ════════════════════════════════════════════════════════════════════
  // ORQUESTRADOR DE SCHEMA
  // ════════════════════════════════════════════════════════════════════

  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      AppLogger.debug('Database: Instalação limpa (v0 → v$version)', tag: 'DB');
    }
    await _runMigrations(db, 0, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      AppLogger.debug(
        'Database Upgrade: v$oldVersion → v$newVersion',
        tag: 'DB',
      );
    }
    await _runMigrations(db, oldVersion, newVersion);
  }

  /// 🔁 Orquestrador Determinístico de Migrações
  Future<void> _runMigrations(
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    for (int v = fromVersion + 1; v <= toVersion; v++) {
      if (kDebugMode) AppLogger.debug('Aplicando migração: v$v', tag: 'DB');
      switch (v) {
        case 1:
          await _migrateToV1(db);
          break;
        case 2:
          await _migrateToV2(db);
          break;
        case 3:
          await _migrateToV3(db);
          break;
        case 4:
          await _migrateToV4(db);
          break;
        case 5:
          await _migrateToV5(db);
          break;
        case 6:
          await _migrateToV6(db);
          break;
        case 7:
          await _migrateToV7(db);
          break;
        case 8:
          await _migrateToV8(db);
          break;
        case 9:
          await _migrateToV9(db);
          break;
        case 10:
          await _migrateToV10(db);
          break;
        case 11:
          await _migrateToV11(db);
          break;
        case 12:
          await _migrateToV12(db);
          break;
        case 13:
          await _migrateToV13(db);
          break;
        case 14:
          await _migrateToV14(db);
          break;
        case 15:
          await _migrateToV15(db);
          break;
        case 16:
          await _migrateToV16(db);
          break;
        case 17:
          await _migrateToV17(db);
          break;
        case 18:
          await _migrateToV18(db);
          break;
        case 19:
          await _migrateToV19(db);
          break;
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MIGRAÇÃO (ISOLADOS E INCREMENTAIS)
  // ════════════════════════════════════════════════════════════════════

  Future<void> _migrateToV1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id TEXT PRIMARY KEY,
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

  Future<void> _migrateToV2(Database db) async {
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

  Future<void> _migrateToV3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_sessions (
        id TEXT PRIMARY KEY,
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

  Future<void> _migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS occurrences (
        id TEXT PRIMARY KEY,
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_reports (
        id TEXT PRIMARY KEY,
        visit_session_id TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (visit_session_id) REFERENCES visit_sessions (id)
      )
    ''');
  }

  Future<void> _migrateToV5(Database db) async {
    // Tabela legada da agenda (será destruída na v10)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agenda_events (
        id TEXT PRIMARY KEY,
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

  Future<void> _migrateToV6(Database db) async {
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

  Future<void> _migrateToV7(Database db) async {
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN geometry TEXT');
    } catch (e) {
      AppLogger.debug(
        'V7: geometry em occurrences já existe — $e',
        tag: 'DB.Migration',
      );
    }
  }

  Future<void> _migrateToV8(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS drawings (
        id TEXT PRIMARY KEY,
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

  Future<void> _migrateToV9(Database db) async {
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

  Future<void> _migrateToV10(Database db) async {
    // 🎯 RECONSTRUÇÃO DA AGENDA (Incompatibilidade com schema v5)
    await db.execute('DROP TABLE IF EXISTS agenda_events');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS agenda_events (
        id TEXT PRIMARY KEY,
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
  }

  // ── V11, V12, V13: reservadas para próximas features ──────────────────
  Future<void> _migrateToV11(Database db) async {
    // Reservada — sem alterações nesta versão
    AppLogger.debug('V11: reservada (no-op)', tag: 'DB.Migration');
  }

  Future<void> _migrateToV12(Database db) async {
    // Reservada — sem alterações nesta versão
    AppLogger.debug('V12: reservada (no-op)', tag: 'DB.Migration');
  }

  Future<void> _migrateToV13(Database db) async {
    // Reservada — sem alterações nesta versão
    AppLogger.debug('V13: reservada (no-op)', tag: 'DB.Migration');
  }

  /// V14 — Schema agronômico de ocorrências (ADR-014)
  ///
  /// Adiciona 11 colunas opcionais à tabela [occurrences].
  /// Usa try/catch por coluna: idempotente em caso de re-execução.
  Future<void> _migrateToV14(Database db) async {
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
  Future<void> _migrateToV15(Database db) async {
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

  // ════════════════════════════════════════════════════════════════════

  Future<void> _validateSchema(Database db) async {
    if (!kDebugMode) return;

    final criticalTables = ['clients', 'drawings', 'agenda_events'];
    for (final table in criticalTables) {
      final res = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (res.isEmpty) {
        AppLogger.error(
          'ERRO CRÍTICO: Tabela "$table" não encontrada após boot.',
          tag: 'DB',
        );
      } else {
        AppLogger.debug('Database: Tabela "$table" validada.', tag: 'DB');
      }
    }
  }

  /// V16 — Adiciona producer_id em agenda_visit_sessions (WS-3 / ADR-017)
  /// Idempotente: envolve ALTER TABLE em try/catch.
  Future<void> _migrateToV16(Database db) async {
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
  Future<void> _migrateToV17(Database db) async {
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
  Future<void> _migrateToV18(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_sessions_v18 (
        id TEXT PRIMARY KEY,
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
      INSERT INTO visit_sessions_v18
        SELECT
          id,
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

    await db.execute('DROP TABLE IF EXISTS visit_sessions');
    await db.execute(
      'ALTER TABLE visit_sessions_v18 RENAME TO visit_sessions',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_sessions_status ON visit_sessions(status)',
    );

    AppLogger.debug(
      'V18: visit_sessions reconstruída — area_id e activity_type agora nullable',
      tag: 'DB.Migration',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ════════════════════════════════════════════════════════════════════

  /// V19 — Cache local de imagens NDVI (módulo ndvi/).
  ///
  /// Cria tabela [ndvi_cache] para armazenar a última imagem NDVI por talhão
  /// (area_id + date), com validade de 24h.
  /// Idempotente: CREATE TABLE IF NOT EXISTS.
  Future<void> _migrateToV19(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ndvi_cache (
        id           TEXT PRIMARY KEY,
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
}
