import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  Future<Database> openLegacyVisitDb() {
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE visit_sessions (
            id TEXT PRIMARY KEY,
            producer_id TEXT NOT NULL
          )
        ''');
      },
    );
  }

  test(
    'migrateToV49 adiciona colunas locais da rota em visit_sessions',
    () async {
      final db = await openLegacyVisitDb();

      expect(
        await DatabaseSchemaUtils.columnExists(
          db,
          'visit_sessions',
          'route_stops_json',
        ),
        isFalse,
      );
      expect(
        await DatabaseSchemaUtils.columnExists(
          db,
          'visit_sessions',
          'route_current_index',
        ),
        isFalse,
      );

      await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

      expect(
        await DatabaseSchemaUtils.columnExists(
          db,
          'visit_sessions',
          'route_stops_json',
        ),
        isTrue,
      );
      expect(
        await DatabaseSchemaUtils.columnExists(
          db,
          'visit_sessions',
          'route_current_index',
        ),
        isTrue,
      );

      await db.insert('visit_sessions', {
        'id': 'visit-legado',
        'producer_id': 'produtor',
      });
      final row = (await db.query('visit_sessions')).single;
      expect(row['route_stops_json'], isNull);
      expect(row['route_current_index'], isNull);

      await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);
      expect(
        await DatabaseSchemaUtils.columnExists(
          db,
          'visit_sessions',
          'route_stops_json',
        ),
        isTrue,
      );

      await db.close();
    },
  );
}
