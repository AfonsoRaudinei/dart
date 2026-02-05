import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
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
      version: 2,
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
    }
  }

  // Future helpers to close DB if needed
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
