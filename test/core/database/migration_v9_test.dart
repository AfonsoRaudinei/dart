import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// ✅ TESTE DE VALIDAÇÃO: Migração v8 → v9
/// 
/// Este teste valida que a migração adiciona as colunas cliente_id e fazenda_id
/// corretamente na tabela drawings.
void main() {
  setUpAll(() {
    // Inicializar sqflite para testes
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Migração v8 → v9: cliente_id e fazenda_id', () {
    late Database db;
    late String dbPath;

    setUp(() async {
      // Criar caminho único para cada teste
      dbPath = '${inMemoryDatabasePath}_${DateTime.now().millisecondsSinceEpoch}';

      // PASSO 1: Criar banco v8 (sem as novas colunas)
      db = await openDatabase(
        dbPath,
        version: 8,
        onCreate: (db, version) async {
          // Estrutura v8 (SEM cliente_id e fazenda_id)
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
        },
      );

      // Fechar o banco v8
      await db.close();

      // PASSO 2: Reabrir com v9 para forçar migração
      db = await openDatabase(
        dbPath,
        version: 9,
        onUpgrade: (db, oldVersion, newVersion) async {
          // Aplicar migração v9
          if (oldVersion < 9) {
            await db.execute('ALTER TABLE drawings ADD COLUMN cliente_id TEXT');
            await db.execute('ALTER TABLE drawings ADD COLUMN fazenda_id TEXT');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_drawings_cliente_id 
              ON drawings(cliente_id)
            ''');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_drawings_fazenda_id 
              ON drawings(fazenda_id)
            ''');
          }
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Deve adicionar coluna cliente_id', () async {
      // Verificar estrutura da tabela
      final result = await db.rawQuery('PRAGMA table_info(drawings)');
      
      final clienteIdColumn = result.firstWhere(
        (col) => col['name'] == 'cliente_id',
        orElse: () => {},
      );
      
      expect(clienteIdColumn, isNotEmpty, reason: 'Coluna cliente_id deve existir');
      expect(clienteIdColumn['type'], equals('TEXT'));
    });

    test('Deve adicionar coluna fazenda_id', () async {
      final result = await db.rawQuery('PRAGMA table_info(drawings)');
      
      final fazendaIdColumn = result.firstWhere(
        (col) => col['name'] == 'fazenda_id',
        orElse: () => {},
      );
      
      expect(fazendaIdColumn, isNotEmpty, reason: 'Coluna fazenda_id deve existir');
      expect(fazendaIdColumn['type'], equals('TEXT'));
    });

    test('Deve criar índice para cliente_id', () async {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_drawings_cliente_id'",
      );
      
      expect(result, isNotEmpty, reason: 'Índice idx_drawings_cliente_id deve existir');
    });

    test('Deve criar índice para fazenda_id', () async {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_drawings_fazenda_id'",
      );
      
      expect(result, isNotEmpty, reason: 'Índice idx_drawings_fazenda_id deve existir');
    });

    test('Deve permitir inserir drawing com cliente_id e fazenda_id', () async {
      await db.insert('drawings', {
        'id': 'test-001',
        'nome': 'Talhão Teste',
        'tipo': 'talhao',
        'origem': 'desenho_manual',
        'status': 'rascunho',
        'geojson': '{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}',
        'area_ha': 100.5,
        'autor_id': 'user-001',
        'autor_tipo': 'consultor',
        'sync_status': 'local_only',
        'versao': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'ativo': 1,
        'cliente_id': 'cliente-001', // ✅ NOVO
        'fazenda_id': 'fazenda-001',  // ✅ NOVO
      });

      final result = await db.query(
        'drawings',
        where: 'id = ?',
        whereArgs: ['test-001'],
      );

      expect(result, hasLength(1));
      expect(result.first['cliente_id'], equals('cliente-001'));
      expect(result.first['fazenda_id'], equals('fazenda-001'));
    });

    test('Deve permitir cliente_id e fazenda_id nulos', () async {
      await db.insert('drawings', {
        'id': 'test-002',
        'nome': 'Talhão Sem Cliente',
        'tipo': 'talhao',
        'origem': 'desenho_manual',
        'status': 'rascunho',
        'geojson': '{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}',
        'area_ha': 50.0,
        'autor_id': 'user-001',
        'autor_tipo': 'consultor',
        'sync_status': 'local_only',
        'versao': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'ativo': 1,
        // cliente_id e fazenda_id omitidos (NULL)
      });

      final result = await db.query(
        'drawings',
        where: 'id = ?',
        whereArgs: ['test-002'],
      );

      expect(result, hasLength(1));
      expect(result.first['cliente_id'], isNull);
      expect(result.first['fazenda_id'], isNull);
    });
  });
}
