import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/agenda/data/repositories/agenda_repository.dart';
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
    tempDir = await Directory.systemTemp.createTemp('agenda_soft_delete_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember('user-agenda-1');
    await db.delete('agenda_events');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  test('deleteEvent marca deleted_local e oculta das listagens ativas', () async {
    final repo = AgendaRepository();
    final event = _event('evt-soft-1');

    await repo.saveEvent(event);
    await repo.deleteEvent('evt-soft-1');

    final all = await repo.getAllEvents();
    final pending = await repo.getPendingSyncEvents();
    final byId = await repo.getEventById('evt-soft-1');

    expect(all, isEmpty);
    expect(pending.map((e) => e.id), contains('evt-soft-1'));
    expect(
      SyncStatusContract.normalize(byId?.syncStatus),
      SyncStatusContract.deletedLocal,
    );
  });

  test('purgeDeletedEvent remove registro após tombstone remoto', () async {
    final repo = AgendaRepository();
    await repo.saveEvent(_event('evt-purge-1'));
    await repo.deleteEvent('evt-purge-1');

    await repo.purgeDeletedEvent('evt-purge-1');

    expect(await repo.getEventById('evt-purge-1'), isNull);
    expect(await repo.getPendingSyncEvents(), isEmpty);
  });
}

Event _event(String id) {
  final start = DateTime.utc(2026, 8, 10, 12);
  final now = DateTime.utc(2026, 8, 6, 12);
  return Event(
    id: id,
    tipo: EventType.visitaTecnica,
    clienteId: 'cli-1',
    titulo: 'Visita teste',
    dataInicioPlanejada: start,
    dataFimPlanejada: start.add(const Duration(hours: 2)),
    status: EventStatus.agendado,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatusContract.synced,
  );
}
