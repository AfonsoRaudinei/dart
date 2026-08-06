import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/agenda/data/repositories/agenda_repository.dart';
import 'package:soloforte_app/modules/agenda/data/services/agenda_sync_service.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('agenda_sync_tombstone_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
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
    LocalSessionIdentity.remember('user-sync-1');
    await db.delete('agenda_events');
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'pushEventsForTesting envia tombstone remoto e purga evento local',
    () async {
      final repo = AgendaRepository();
      final remoteDeletes = <({String eventId, String userId})>[];
      final service = AgendaSyncService(
        Supabase.instance.client,
        repo,
        remoteEventDeleteForTest: (eventId, userId) async {
          remoteDeletes.add((eventId: eventId, userId: userId));
        },
      );

      const eventId = 'evt-tombstone-remote';
      await repo.saveEvent(_event(eventId));
      await repo.deleteEvent(eventId);

      expect(await repo.getAllEvents(), isEmpty);
      expect(await repo.getPendingSyncEvents(), isNotEmpty);

      await service.pushEventsForTesting();

      expect(remoteDeletes, hasLength(1));
      expect(remoteDeletes.single.eventId, eventId);
      expect(remoteDeletes.single.userId, 'user-sync-1');
      expect(await repo.getEventById(eventId), isNull);
      expect(await repo.getPendingSyncEvents(), isEmpty);
    },
  );
}

Event _event(String id) {
  final start = DateTime.utc(2026, 8, 12, 9);
  final now = DateTime.utc(2026, 8, 6, 12);
  return Event(
    id: id,
    tipo: EventType.visitaTecnica,
    clienteId: 'cli-sync-1',
    titulo: 'Visita sync',
    dataInicioPlanejada: start,
    dataFimPlanejada: start.add(const Duration(hours: 2)),
    status: EventStatus.agendado,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatusContract.synced,
  );
}
