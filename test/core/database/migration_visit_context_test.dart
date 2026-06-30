import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Migrações de contexto da visita', () {
    late Database db;
    late String dbPath;

    setUp(() async {
      dbPath =
          '${inMemoryDatabasePath}_${DateTime.now().microsecondsSinceEpoch}';
      db = await openDatabase(dbPath);
      await db.execute('''
        CREATE TABLE visit_sessions (
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
      await db.insert('visit_sessions', {
        'id': 'visit-1',
        'user_id': 'user-1',
        'producer_id': 'client-1',
        'area_id': 'field-1',
        'activity_type': 'Monitoramento',
        'start_time': '2026-05-31T08:00:00.000',
        'initial_lat': -10.0,
        'initial_long': -48.0,
        'status': 'active',
        'created_at': '2026-05-31T08:00:00.000',
        'updated_at': '2026-05-31T08:00:00.000',
        'sync_status': 1,
      });
    });

    tearDown(() async {
      await db.close();
      await deleteDatabase(dbPath);
    });

    test('v18 preserva user_id ao tornar área e atividade opcionais', () async {
      await db.execute('''
        CREATE TABLE visit_sessions_v18 (
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
      await db.execute('''
        INSERT INTO visit_sessions_v18 (
          id, user_id, producer_id, area_id, activity_type, start_time,
          end_time, initial_lat, initial_long, status, created_at, updated_at,
          sync_status
        )
        SELECT
          id, user_id, producer_id, NULLIF(area_id, ''),
          NULLIF(activity_type, ''), start_time, end_time, initial_lat,
          initial_long, status, created_at, updated_at, sync_status
        FROM visit_sessions
      ''');

      final migrated = await db.query('visit_sessions_v18');

      expect(migrated.single['user_id'], 'user-1');
      expect(migrated.single['producer_id'], 'client-1');
    });

    test(
      'v33 adiciona farm_id opcional sem alterar sessões existentes',
      () async {
        await db.execute('ALTER TABLE visit_sessions ADD COLUMN farm_id TEXT');

        final columns = await db.rawQuery('PRAGMA table_info(visit_sessions)');
        final farmColumn = columns.singleWhere(
          (column) => column['name'] == 'farm_id',
        );
        final session = (await db.query('visit_sessions')).single;

        expect(farmColumn['type'], 'TEXT');
        expect(farmColumn['notnull'], 0);
        expect(session['farm_id'], isNull);
        expect(session['user_id'], 'user-1');
      },
    );
  });

  group('Migração v34 de branding de relatório', () {
    late Database db;
    late String dbPath;

    setUp(() async {
      dbPath =
          '${inMemoryDatabasePath}_${DateTime.now().microsecondsSinceEpoch}';
      db = await openDatabase(dbPath);
      await db.execute('''
        CREATE TABLE user_profile_cache (
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
    });

    tearDown(() async {
      await db.close();
      await deleteDatabase(dbPath);
    });

    test('adiciona colunas de marca sem alterar perfil existente', () async {
      await db.insert('user_profile_cache', {
        'id': 'user-1',
        'email': 'user@soloforte.app',
        'full_name': 'Usuario Teste',
        'created_at': '2026-06-05T10:00:00.000Z',
        'updated_at': '2026-06-05T10:00:00.000Z',
        'sync_status': 0,
      });

      await db.execute(
        'ALTER TABLE user_profile_cache ADD COLUMN report_brand_name TEXT',
      );
      await db.execute(
        'ALTER TABLE user_profile_cache ADD COLUMN report_logo_url TEXT',
      );

      final columns = await db.rawQuery(
        'PRAGMA table_info(user_profile_cache)',
      );
      final names = columns.map((column) => column['name']).toSet();
      final row = (await db.query('user_profile_cache')).single;

      expect(names, contains('report_brand_name'));
      expect(names, contains('report_logo_url'));
      expect(row['email'], 'user@soloforte.app');
      expect(row['report_brand_name'], isNull);
      expect(row['report_logo_url'], isNull);
    });
  });
}
