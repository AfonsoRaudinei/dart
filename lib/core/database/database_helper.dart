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
    return await openDatabase(
      path,
      version: 10, // 🆕 Incrementado para v10 (Agenda)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        documento TEXT,
        telefone TEXT,
        email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_clients_nome ON clients(nome);
    ''');

    await db.execute('''
      CREATE INDEX idx_clients_sync ON clients(sync_status);
    ''');

    await db.execute('''
      CREATE TABLE farms (
        id TEXT PRIMARY KEY,
        cliente_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        area_total REAL,
        municipio TEXT,
        uf TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (cliente_id) REFERENCES clients (id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_farms_cliente_id ON farms(cliente_id);
    ''');

    await db.execute('''
      CREATE INDEX idx_farms_sync ON farms(sync_status);
    ''');

    await db.execute('''
      CREATE TABLE fields (
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
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (fazenda_id) REFERENCES farms (id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_fields_fazenda_id ON fields(fazenda_id);
    ''');

    await db.execute('''
      CREATE INDEX idx_fields_sync ON fields(sync_status);
    ''');

    await db.execute('''
      CREATE TABLE visit_sessions (
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

    await db.execute('''
      CREATE INDEX idx_visit_sessions_status ON visit_sessions(status);
    ''');

    await db.execute('''
      CREATE TABLE occurrences (
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
      'CREATE INDEX idx_occurrences_session ON occurrences(visit_session_id)',
    );

    await db.execute('''
      CREATE TABLE visit_reports (
        id TEXT PRIMARY KEY,
        visit_session_id TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (visit_session_id) REFERENCES visit_sessions (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_visit_reports_session ON visit_reports(visit_session_id)',
    );

    await db.execute('''
      CREATE TABLE agenda_events (
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
    await db.execute(
      'CREATE INDEX idx_agenda_date ON agenda_events(scheduled_date)',
    );
    await db.execute(
      'CREATE INDEX idx_agenda_producer ON agenda_events(producer_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE clients ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
      await db.execute('CREATE INDEX idx_clients_sync ON clients(sync_status)');

      await db.execute(
        'ALTER TABLE farms ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
      await db.execute('CREATE INDEX idx_farms_sync ON farms(sync_status)');

      await db.execute(
        'ALTER TABLE fields ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
      await db.execute('CREATE INDEX idx_fields_sync ON fields(sync_status)');
      await db.execute(
        'ALTER TABLE fields ADD COLUMN sync_status INTEGER DEFAULT 1',
      );
      await db.execute('CREATE INDEX idx_fields_sync ON fields(sync_status)');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE visit_sessions (
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

      await db.execute('''
        CREATE INDEX idx_visit_sessions_status ON visit_sessions(status);
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE occurrences (
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
        'CREATE INDEX idx_occurrences_session ON occurrences(visit_session_id)',
      );

      await db.execute('''
        CREATE TABLE visit_reports (
          id TEXT PRIMARY KEY,
          visit_session_id TEXT NOT NULL UNIQUE,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          sync_status INTEGER DEFAULT 1,
          FOREIGN KEY (visit_session_id) REFERENCES visit_sessions (id)
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_visit_reports_session ON visit_reports(visit_session_id)',
      );
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE agenda_events (
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
      await db.execute(
        'CREATE INDEX idx_agenda_date ON agenda_events(scheduled_date)',
      );
      await db.execute(
        'CREATE INDEX idx_agenda_producer ON agenda_events(producer_id)',
      );
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE occurrences ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE occurrences ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE occurrences ADD COLUMN status TEXT');
      await db.execute(
        'UPDATE occurrences SET updated_at = created_at WHERE updated_at IS NULL',
      );
      await db.execute(
        "UPDATE occurrences SET status = 'draft' WHERE status IS NULL",
      );
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE occurrences ADD COLUMN geometry TEXT');
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE drawings (
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
        'CREATE INDEX idx_drawings_sync ON drawings(sync_status)',
      );
      await db.execute('CREATE INDEX idx_drawings_ativo ON drawings(ativo)');
    }

    // 🆕 MIGRAÇÃO v9: Adicionar cliente_id e fazenda_id
    if (oldVersion < 9) {
      // Adicionar coluna cliente_id
      await db.execute('ALTER TABLE drawings ADD COLUMN cliente_id TEXT');

      // Adicionar coluna fazenda_id (se ainda não existir)
      try {
        await db.execute('ALTER TABLE drawings ADD COLUMN fazenda_id TEXT');
      } catch (e) {
        // Coluna pode já existir, ignorar erro
      }

      // Criar índice para melhorar performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_drawings_cliente_id 
        ON drawings(cliente_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_drawings_fazenda_id 
        ON drawings(fazenda_id)
      ''');

      if (kDebugMode) {
        debugPrint(
          '✅ Migração v8 → v9: cliente_id e fazenda_id adicionados à tabela drawings',
        );
      }
    }

    // 🆕 MIGRAÇÃO v10: Tabelas da Agenda
    if (oldVersion < 10) {
      // Tabela de eventos da agenda
      await db.execute('''
        CREATE TABLE agenda_events (
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

      // Tabela de sessões de visita
      await db.execute('''
        CREATE TABLE agenda_visit_sessions (
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

      // Índices para performance
      await db.execute('''
        CREATE INDEX idx_agenda_events_cliente 
        ON agenda_events(cliente_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_agenda_events_status 
        ON agenda_events(status)
      ''');

      await db.execute('''
        CREATE INDEX idx_agenda_events_data 
        ON agenda_events(data_inicio_planejada)
      ''');

      await db.execute('''
        CREATE INDEX idx_agenda_events_sync 
        ON agenda_events(sync_status)
      ''');

      await db.execute('''
        CREATE INDEX idx_agenda_sessions_evento 
        ON agenda_visit_sessions(evento_id)
      ''');

      if (kDebugMode) {
        debugPrint(
          '✅ Migração v9 → v10: Tabelas agenda_events e agenda_visit_sessions criadas',
        );
      }
    }
  }

  // Future helpers to close DB if needed
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
