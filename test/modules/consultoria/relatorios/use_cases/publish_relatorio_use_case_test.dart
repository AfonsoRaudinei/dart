import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_repository_provider.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/use_cases/publish_relatorio_use_case.dart';
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
    test('relatório pendente_revisao → publicado com sucesso', () async {
      final relatorio = makeRelatorio(status: RelatorioStatus.pendente_revisao);
      repo.seed([relatorio]);

      final publicado = await container.read(
        publishRelatorioProvider(relatorio.id).future,
      );

      expect(publicado.status, equals(RelatorioStatus.publicado));
    });

    test('retorna RelatorioTecnico com status == publicado', () async {
      final relatorio = makeRelatorio(status: RelatorioStatus.pendente_revisao);
      repo.seed([relatorio]);

      final result = await container.read(
        publishRelatorioProvider(relatorio.id).future,
      );

      expect(result.status, equals(RelatorioStatus.publicado));
    });

    test('syncStatus muda para pending_sync após publicação', () async {
      final relatorio = makeRelatorio(
        status: RelatorioStatus.pendente_revisao,
        syncStatus: RelatorioSyncStatus.local_only,
      );
      repo.seed([relatorio]);

      await container.read(publishRelatorioProvider(relatorio.id).future);

      expect(
        repo.get(relatorio.id)?.syncStatus,
        equals(RelatorioSyncStatus.pending_sync),
      );
    });

    test('relatório persiste no repositório com novo status', () async {
      final relatorio = makeRelatorio(status: RelatorioStatus.pendente_revisao);
      repo.seed([relatorio]);

      await container.read(publishRelatorioProvider(relatorio.id).future);

      expect(repo.get(relatorio.id)?.status, equals(RelatorioStatus.publicado));
    });
  });

  // =========================================================================
  group('Idempotência', () {
    test('relatório já publicado → retorna sem lançar erro', () async {
      final relatorio = makeRelatorio(status: RelatorioStatus.publicado);
      repo.seed([relatorio]);

      expect(
        () => container.read(publishRelatorioProvider(relatorio.id).future),
        returnsNormally,
      );
    });

    test(
      'relatório já publicado → status permanece publicado (não regride)',
      () async {
        final relatorio = makeRelatorio(status: RelatorioStatus.publicado);
        repo.seed([relatorio]);

        final result = await container.read(
          publishRelatorioProvider(relatorio.id).future,
        );

        expect(result.status, equals(RelatorioStatus.publicado));
      },
    );

    test('relatório já publicado → não chama update() no repositório', () async {
      final relatorio = makeRelatorio(status: RelatorioStatus.publicado);
      repo.seed([relatorio]);

      // A lógica em publish retorna early sem chamar update() se já publicado.
      // Verificamos: updatedAt não muda após a chamada.
      final updatedAtAntes = repo.get(relatorio.id)!.updatedAt;

      await container.read(publishRelatorioProvider(relatorio.id).future);

      // update() bumpa updatedAt — se não foi chamado, updatedAt permanece igual
      expect(repo.get(relatorio.id)?.updatedAt, equals(updatedAtAntes));
    });
  });

  // =========================================================================
  group('Validações — erros esperados', () {
    test('id inexistente → lança ArgumentError', () {
      expect(
        () => container.read(
          publishRelatorioProvider('id-que-nao-existe').future,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('relatório arquivado → lança StateError', () {
      final relatorio = makeRelatorio(status: RelatorioStatus.arquivado);
      repo.seed([relatorio]);

      expect(
        () => container.read(publishRelatorioProvider(relatorio.id).future),
        throwsA(isA<StateError>()),
      );
    });

    test("mensagem do StateError menciona 'arquivado'", () async {
      final relatorio = makeRelatorio(status: RelatorioStatus.arquivado);
      repo.seed([relatorio]);

      Object? caughtError;
      try {
        await container.read(publishRelatorioProvider(relatorio.id).future);
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<StateError>());
      expect((caughtError as StateError).message, contains('arquivado'));
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('updatedAt é renovado após publicação', () async {
      // Cria com updatedAt no passado para garantir diferença
      final updatedAtOriginal = DateTime(2024, 1, 1).toUtc();
      final relatorio = makeRelatorio(
        status: RelatorioStatus.pendente_revisao,
        updatedAt: updatedAtOriginal,
      );
      repo.seed([relatorio]);

      await container.read(publishRelatorioProvider(relatorio.id).future);

      final updatedAtNovo = repo.get(relatorio.id)!.updatedAt;
      expect(updatedAtNovo.isAfter(updatedAtOriginal), isTrue);
    });

    test('clientId não muda após publicação', () async {
      final relatorio = makeRelatorio(
        clientId: 'cli-original',
        status: RelatorioStatus.pendente_revisao,
      );
      repo.seed([relatorio]);

      final result = await container.read(
        publishRelatorioProvider(relatorio.id).future,
      );

      expect(result.clientId, equals('cli-original'));
    });

    test('agronomistId não muda após publicação', () async {
      final relatorio = makeRelatorio(
        agronomistId: 'agro-original',
        status: RelatorioStatus.pendente_revisao,
      );
      repo.seed([relatorio]);

      final result = await container.read(
        publishRelatorioProvider(relatorio.id).future,
      );

      expect(result.agronomistId, equals('agro-original'));
    });
  });

  // =========================================================================
  group('Falha de persistência', () {
    test('repo.throwOnNextWrite = true → lança Exception', () {
      final relatorio = makeRelatorio(status: RelatorioStatus.pendente_revisao);
      repo.seed([relatorio]);
      repo.throwOnNextWrite = true;

      expect(
        () => container.read(publishRelatorioProvider(relatorio.id).future),
        throwsException,
      );
    });

    test(
      'status do relatório não muda após falha (ainda pendente_revisao)',
      () async {
        final relatorio = makeRelatorio(
          status: RelatorioStatus.pendente_revisao,
        );
        repo.seed([relatorio]);
        repo.throwOnNextWrite = true;

        try {
          await container.read(publishRelatorioProvider(relatorio.id).future);
        } catch (_) {}

        expect(
          repo.get(relatorio.id)?.status,
          equals(RelatorioStatus.pendente_revisao),
        );
      },
    );
  });
}
