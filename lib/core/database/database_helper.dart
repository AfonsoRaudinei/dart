import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

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
      version: 10,
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
      debugPrint('🛠️ Database: Iniciando instalação limpa (v0 → v$version)');
    }
    await _runMigrations(db, 0, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint('🚀 Database Upgrade: v$oldVersion → v$newVersion');
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
      if (kDebugMode) debugPrint('📦 Aplicando migração: v$v');
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
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE farms ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE fields ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
    } catch (_) {}

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
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN category TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN status TEXT');
    } catch (_) {}
    await db.execute(
      "UPDATE occurrences SET status = 'draft' WHERE status IS NULL",
    );
  }

  Future<void> _migrateToV7(Database db) async {
    try {
      await db.execute('ALTER TABLE occurrences ADD COLUMN geometry TEXT');
    } catch (_) {}
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
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE drawings ADD COLUMN fazenda_id TEXT');
    } catch (_) {}
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

  // ════════════════════════════════════════════════════════════════════
  // INTEGRIDADE E OBSERVAÇÃO
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
        debugPrint('❌ ERRO CRÍTICO: Tabela "$table" não encontrada após boot.');
      } else {
        debugPrint('✅ Database: Tabela "$table" validada com sucesso.');
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
