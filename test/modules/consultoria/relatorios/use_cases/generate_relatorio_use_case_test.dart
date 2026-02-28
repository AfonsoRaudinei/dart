import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_repository_provider.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/use_cases/generate_relatorio_use_case.dart';
import '../../helpers/fake_relatorio_repository.dart';
import '../../helpers/consultoria_test_factories.dart';

// ── Helpers de conveniência ────────────────────────────────────────────────

/// Cria um ProviderContainer com o FakeRelatorioRepository injetado.
ProviderContainer makeContainer(FakeRelatorioRepository repo) {
  return ProviderContainer(
    overrides: [relatorioRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  late FakeRelatorioRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeRelatorioRepository();
    container = makeContainer(repo);
  });

  tearDown(() {
    container.dispose();
  });

  // =========================================================================
  group('Happy Path', () {
    test('gera relatório com status pendente_revisao', () async {
      final snapshot = makeSnapshot();

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.status, equals(RelatorioStatus.pendente_revisao));
    });

    test('gera relatório com syncStatus local_only', () async {
      final snapshot = makeSnapshot();

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.syncStatus, equals(RelatorioSyncStatus.local_only));
    });

    test('relatorio.id é UUID v4 não vazio', () async {
      final snapshot = makeSnapshot();

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.id, isNotEmpty);
      // UUID v4: 8-4-4-4-12 dígitos hexadecimais separados por hífens
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(relatorio.id),
        isTrue,
        reason: 'ID deve ser UUID v4 válido',
      );
    });

    test('relatorio.clientId == snapshot.clientId', () async {
      final snapshot = makeSnapshot(clientId: 'cli-xyz');

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.clientId, equals('cli-xyz'));
    });

    test('relatorio.agronomistId == snapshot.agronomistId', () async {
      final snapshot = makeSnapshot(agronomistId: 'agro-xyz');

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.agronomistId, equals('agro-xyz'));
    });

    test('relatorio.farmName == snapshot.farmName', () async {
      final snapshot = makeSnapshot(farmName: 'Fazenda Boa Vista');

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.farmName, equals('Fazenda Boa Vista'));
    });

    test('relatorio.periodStart == snapshot.startedAt', () async {
      final start = DateTime(2026, 1, 10, 8, 0).toUtc();
      final snapshot = makeSnapshot(
        startedAt: start,
        finishedAt: start.add(const Duration(hours: 2)),
      );

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.periodStart, equals(snapshot.startedAt));
    });

    test('relatorio.periodEnd == snapshot.finishedAt', () async {
      final start = DateTime(2026, 1, 10, 8, 0).toUtc();
      final end = start.add(const Duration(hours: 3));
      final snapshot = makeSnapshot(startedAt: start, finishedAt: end);

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.periodEnd, equals(end));
    });

    test('relatorio persiste no repositório após geração', () async {
      final snapshot = makeSnapshot();

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(repo.get(relatorio.id), isNotNull);
    });

    test('relatorio.ocorrencias == snapshot.ocorrencias', () async {
      final snapshot = makeSnapshot(ocorrencias: const []);

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.ocorrencias, equals(snapshot.ocorrencias));
    });

    test('relatorio.talhoes == snapshot.talhoes', () async {
      final snapshot = makeSnapshot(talhoes: const []);

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.talhoes, equals(snapshot.talhoes));
    });
  });

  // =========================================================================
  group('Snapshot com campos mínimos', () {
    test('ocorrencias vazia → relatorio.ocorrencias == []', () async {
      final snapshot = makeSnapshot(ocorrencias: const []);

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.ocorrencias, isEmpty);
    });

    test('talhoes vazia → relatorio.talhoes == []', () async {
      final snapshot = makeSnapshot(talhoes: const []);

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.talhoes, isEmpty);
    });

    test('fotos vazia → relatorio.fotos == []', () async {
      final snapshot = makeSnapshot();

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.fotos, isEmpty);
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('dois snapshots diferentes geram IDs diferentes', () async {
      final snapshotA = makeSnapshot(sessionId: 'sess-a', clientId: 'cli-a');
      final snapshotB = makeSnapshot(sessionId: 'sess-b', clientId: 'cli-b');

      // Containers separados para evitar cache do provider
      final containerA = makeContainer(FakeRelatorioRepository());
      final containerB = makeContainer(FakeRelatorioRepository());
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      final relatorioA = await containerA.read(
        generateRelatorioProvider(snapshotA).future,
      );
      final relatorioB = await containerB.read(
        generateRelatorioProvider(snapshotB).future,
      );

      expect(relatorioA.id, isNot(equals(relatorioB.id)));
    });

    test(
      'snapshot idêntico chamado duas vezes gera dois relatórios distintos',
      () async {
        final snapshot = makeSnapshot();

        final containerA = makeContainer(FakeRelatorioRepository());
        final containerB = makeContainer(FakeRelatorioRepository());
        addTearDown(containerA.dispose);
        addTearDown(containerB.dispose);

        final relatorioA = await containerA.read(
          generateRelatorioProvider(snapshot).future,
        );
        final relatorioB = await containerB.read(
          generateRelatorioProvider(snapshot).future,
        );

        expect(relatorioA.id, isNot(equals(relatorioB.id)));
      },
    );

    test('createdAt e updatedAt são preenchidos na geração', () async {
      final snapshot = makeSnapshot();

      final relatorio = await container.read(
        generateRelatorioProvider(snapshot).future,
      );

      expect(relatorio.createdAt, isNotNull);
      expect(relatorio.updatedAt, isNotNull);
    });
  });

  // =========================================================================
  group('Falha de persistência', () {
    test('se repo.throwOnNextWrite = true → lança Exception', () async {
      repo.throwOnNextWrite = true;
      final snapshot = makeSnapshot();

      expect(
        () => container.read(generateRelatorioProvider(snapshot).future),
        throwsException,
      );
    });

    test('repositório permanece sem o relatório após falha', () async {
      repo.throwOnNextWrite = true;
      final snapshot = makeSnapshot();

      try {
        await container.read(generateRelatorioProvider(snapshot).future);
      } catch (_) {}

      expect(repo.count, equals(0));
    });
  });
}
