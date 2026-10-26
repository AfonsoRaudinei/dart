import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soloforte_app/core/database/database_migrations.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/data/relatorio_combinado_repository.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_combinado.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late Directory tempDir;
  late DateTime clock;
  late RelatorioCombinadoRepositoryImpl repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('relatorio_combinado_repo');
    db = await databaseFactoryFfi.openDatabase(
      p.join(tempDir.path, 'combo.db'),
    );
    await DatabaseMigrations.migrateToV46(db);
    clock = DateTime.utc(2026, 10, 26, 15);
    repo = RelatorioCombinadoRepositoryImpl(
      openDatabase: () async => db,
      resolveUserId: () => 'user-combo',
      clock: () {
        clock = clock.add(const Duration(seconds: 1));
        return clock;
      },
      newId: _ids(),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('insert, list ignora deleted e outro cliente', () async {
    final first = await repo.insert(
      clientId: 'cli-1',
      chapterKeys: const ['visita:a', 'ocorrencia:b'],
    );
    final second = await repo.insert(
      clientId: 'cli-1',
      chapterKeys: const ['visita:c', 'mkt:d'],
    );
    final otherClient = await repo.insert(
      clientId: 'cli-2',
      chapterKeys: const ['visita:e', 'ocorrencia:f'],
    );
    await repo.softDelete(otherClient.id);

    expect(first.title, contains('Combinado ·'));
    expect(first.title, contains('2 relatórios'));
    expect(first.syncStatus, SyncStatusContract.pendingSync);

    final listed = await repo.listByClient('cli-1');
    expect(listed.map((row) => row.id), [second.id, first.id]);
    expect(await repo.listByClient('cli-2'), isEmpty);
  });

  test(
    'removeChapter atualiza chaves e softDelete no último capítulo',
    () async {
      final saved = await repo.insert(
        clientId: 'cli-1',
        chapterKeys: const ['visita:a', 'ocorrencia:b'],
      );

      final updated = await repo.removeChapter(saved.id, 'ocorrencia:b');
      expect(updated, isNotNull);
      expect(updated!.chapterKeys, ['visita:a']);
      expect(updated.syncStatus, SyncStatusContract.pendingSync);

      final gone = await repo.removeChapter(saved.id, 'visita:a');
      expect(gone, isNull);
      expect(await repo.listByClient('cli-1'), isEmpty);
    },
  );

  test('softDelete não apaga a linha física', () async {
    final saved = await repo.insert(
      clientId: 'cli-1',
      chapterKeys: const ['visita:a', 'mkt:b'],
    );
    await repo.softDelete(saved.id);

    final rows = await db.query(
      relatoriosCombinadosTable,
      where: 'id = ?',
      whereArgs: [saved.id],
    );
    expect(rows, hasLength(1));
    expect(rows.single['deleted_at'], isNotNull);
    expect(rows.single['sync_status'], SyncStatusContract.pendingSync);
    expect(await repo.listByClient('cli-1'), isEmpty);
  });

  test('listagem de outro usuário fica vazia', () async {
    await repo.insert(
      clientId: 'cli-1',
      chapterKeys: const ['visita:a', 'ocorrencia:b'],
    );
    final other = RelatorioCombinadoRepositoryImpl(
      openDatabase: () async => db,
      resolveUserId: () => 'user-outro',
      clock: DateTime.now,
    );
    expect(await other.listByClient('cli-1'), isEmpty);
  });
}

String Function() _ids() {
  var n = 0;
  return () => 'id-${n++}';
}
