import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('farm_repo_crud_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory' ||
              call.method == 'getApplicationDocumentsPath') {
            return tempDir.path;
          }
          return tempDir.path;
        });
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember('user-farm-crud');
    await db.delete('farms');
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('saveFarm atualiza pelo mesmo id (upsert)', () async {
    const clientId = 'client-upsert';
    const farmId = 'farm-upsert-1';
    final repository = FarmRepository();

    await repository.saveFarm(
      Farm(
        id: farmId,
        name: 'Nome original',
        city: 'Pugmil',
        state: 'TO',
        totalAreaHa: 100,
      ),
      clientId,
    );

    await repository.saveFarm(
      Farm(
        id: farmId,
        name: 'Nome editado',
        city: 'Palmas',
        state: 'TO',
        totalAreaHa: 120,
      ),
      clientId,
    );

    final updated = await repository.getFarmById(farmId);
    expect(updated, isNotNull);
    expect(updated!.name, 'Nome editado');
    expect(updated.city, 'Palmas');
    expect(updated.totalAreaHa, 120);
  });

  test('deleteFarm faz soft delete e remove da listagem', () async {
    const clientId = 'client-delete';
    const farmId = 'farm-delete-1';
    final repository = FarmRepository();

    await repository.saveFarm(
      Farm(
        id: farmId,
        name: 'Fazenda Temp',
        city: 'Pugmil',
        state: 'TO',
        totalAreaHa: 50,
      ),
      clientId,
    );

    await repository.deleteFarm(farmId);

    expect(await repository.getFarmById(farmId), isNull);
    expect(await repository.getFarmsByClientId(clientId), isEmpty);

    final row = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [farmId],
    );
    expect(row, hasLength(1));
    expect(row.first['deleted_at'], isNotNull);
  });
}
