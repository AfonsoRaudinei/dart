import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('occurrence_repo_test');
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

  setUp(LocalSessionIdentity.resetForTesting);

  tearDown(() async {
    LocalSessionIdentity.resetForTesting();
    await db.delete('occurrences');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'cria ocorrência offline e relê depois mesmo sem currentUser hidratado',
    () async {
      final repository = OccurrenceRepository();
      final occurrence = Occurrence(
        id: 'occ-offline-1',
        visitSessionId: 'session-1',
        type: 'Info',
        description: 'Ocorrência criada offline',
        createdAt: DateTime.utc(2026, 7, 20, 12),
      );

      await repository.saveOccurrence(occurrence);

      final reread = await OccurrenceRepository().getOccurrencesBySession(
        'session-1',
      );

      expect(reread, hasLength(1));
      expect(reread.single.id, 'occ-offline-1');
      expect(reread.single.syncStatus, 'local_only');
      expect(reread.single.ownerUserId, '');
    },
  );

  test(
    'bootstrap sem currentUser não causa perda silenciosa em releitura global',
    () async {
      final repository = OccurrenceRepository();
      final occurrence = Occurrence(
        id: 'occ-offline-2',
        type: 'Info',
        description: 'Permanece local',
        createdAt: DateTime.utc(2026, 7, 20, 12),
      );

      await repository.saveOccurrence(occurrence);

      final all = await OccurrenceRepository().getAllOccurrences();
      final raw = await db.query(
        'occurrences',
        where: 'id = ?',
        whereArgs: ['occ-offline-2'],
      );

      expect(all.map((item) => item.id), contains('occ-offline-2'));
      expect(raw.single['user_id'], '');
      expect(raw.single['sync_status'], 'local_only');
    },
  );

  test(
    'com lastKnown preserva leitura apos gap de sessao (bootstrap)',
    () async {
      LocalSessionIdentity.remember('user-persist');
      final repository = OccurrenceRepository();
      final occurrence = Occurrence(
        id: 'occ-persist-1',
        visitSessionId: 'session-persist',
        type: 'Info',
        description: 'Deve sobreviver ao gap',
        createdAt: DateTime.utc(2026, 7, 23, 12),
      );

      await repository.saveOccurrence(occurrence);

      final reread = await OccurrenceRepository().getOccurrencesBySession(
        'session-persist',
      );

      expect(reread, hasLength(1));
      expect(reread.single.id, 'occ-persist-1');
      expect(reread.single.ownerUserId, 'user-persist');
    },
  );

  group('getById', () {
    Future<void> insertRaw(String id, Map<String, Object?> overrides) async {
      final map = Occurrence(
        id: id,
        type: 'Info',
        description: 'getById',
        createdAt: DateTime.utc(2026, 11, 6, 12),
      ).toMap();
      map.addAll(overrides);
      await db.insert('occurrences', map);
    }

    test('ocorrência de outro user_id não é retornada', () async {
      LocalSessionIdentity.remember('user-a');
      await insertRaw('occ-other', {'user_id': 'user-b'});

      expect(await OccurrenceRepository().getById('occ-other'), isNull);
    });

    test('cached_by_user_id do usuário atual é retornada', () async {
      LocalSessionIdentity.remember('user-a');
      await insertRaw('occ-cached', {
        'user_id': 'user-b',
        'cached_by_user_id': 'user-a',
      });

      final found = await OccurrenceRepository().getById('occ-cached');

      expect(found?.id, 'occ-cached');
    });

    test('deleted_local é retornada (tombstone)', () async {
      LocalSessionIdentity.remember('user-a');
      await insertRaw('occ-deleted', {
        'user_id': 'user-a',
        'sync_status': 'deleted_local',
        'deleted_at': '2026-11-06T12:00:00.000Z',
      });

      final found = await OccurrenceRepository().getById('occ-deleted');

      expect(found?.id, 'occ-deleted');
      expect(found?.syncStatus, 'deleted_local');
      expect(found?.deletedAt, isNotNull);
    });
  });

  test('Plantios do talhão: só categoria plantio, do talhão, não excluídos',
      () async {
    LocalSessionIdentity.remember('user-a');
    final repository = OccurrenceRepository();
    Occurrence build(String id, {String category = 'plantio', String? field}) {
      return Occurrence(
        id: id,
        type: 'Baixa',
        description: '',
        category: category,
        createdAt: DateTime.utc(2026, 10, 27),
        fieldId: field ?? 'field-1',
        cultura: 'Soja',
        safra: '2026/2027',
      );
    }

    await repository.saveOccurrence(build('p-1'));
    await repository.saveOccurrence(build('p-outro', field: 'field-2'));
    await repository.saveOccurrence(build('d-1', category: 'ervas_daninhas'));
    await repository.saveOccurrence(build('p-excluido'));
    await repository.softDeleteOccurrence('p-excluido');

    final found = await repository.getPlantioOccurrencesByFieldId(' field-1 ');

    expect(found.map((o) => o.id), ['p-1']);
    expect(found.single.cultura, 'Soja');
    expect(found.single.safra, '2026/2027');
    expect(await repository.getPlantioOccurrencesByFieldId(''), isEmpty);
  });
}
