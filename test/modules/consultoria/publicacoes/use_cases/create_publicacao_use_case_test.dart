import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/models/publicacao_tecnica.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/models/publicacao_tema.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/providers/publicacao_repository_provider.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/use_cases/create_publicacao_use_case.dart';
import '../../helpers/fake_publicacao_repository.dart';

// ── Helpers de conveniência ────────────────────────────────────────────────

ProviderContainer makeContainer(FakePublicacaoRepository repo) {
  return ProviderContainer(
    overrides: [publicacaoRepositoryProvider.overrideWithValue(repo)],
  );
}

/// Input padrão válido para os testes.
CreatePublicacaoInput makeInput({
  String? authorId,
  PublicacaoTema? tema,
  String? titulo,
  String? conteudo,
  PublicacaoVisibility? visibility,
  String? safra,
}) {
  return CreatePublicacaoInput(
    authorId: authorId ?? 'agro-test-1',
    tema: tema ?? PublicacaoTema.doenca,
    titulo: titulo ?? 'Mancha Foliar em Soja',
    conteudo: conteudo ?? 'Conteúdo técnico detalhado sobre mancha foliar.',
    visibility: visibility ?? PublicacaoVisibility.restrita,
    safra: safra,
  );
}

void main() {
  late FakePublicacaoRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakePublicacaoRepository();
    container = makeContainer(repo);
  });

  tearDown(() {
    container.dispose();
  });

  // =========================================================================
  group('Happy Path', () {
    test('cria publicação com dados válidos sem lançar erro', () {
      expect(
        () => container.read(createPublicacaoProvider(makeInput()).future),
        returnsNormally,
      );
    });

    test('retorna PublicacaoTecnica com id não vazio', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput()).future,
      );

      expect(result.id, isNotEmpty);
    });

    test('syncStatus == local_only após criação', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput()).future,
      );

      expect(result.syncStatus, equals(PublicacaoSyncStatus.local_only));
    });

    test('titulo é salvo com .trim() aplicado', () async {
      final result = await container.read(
        createPublicacaoProvider(
          makeInput(titulo: '  Título com espaços  '),
        ).future,
      );

      expect(result.titulo, equals('Título com espaços'));
    });

    test('conteudo é salvo com .trim() aplicado', () async {
      final result = await container.read(
        createPublicacaoProvider(
          makeInput(conteudo: '  Conteúdo com espaços  '),
        ).future,
      );

      expect(result.conteudo, equals('Conteúdo com espaços'));
    });

    test('tema é preservado corretamente', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput(tema: PublicacaoTema.solo)).future,
      );

      expect(result.tema, equals(PublicacaoTema.solo));
    });

    test('safra é preservada quando fornecida', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput(safra: '2024/25')).future,
      );

      expect(result.safra, equals('2024/25'));
    });

    test('safra é null quando não fornecida', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput(safra: null)).future,
      );

      expect(result.safra, isNull);
    });

    test('authorId é preservado', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput(authorId: 'agro-xyz')).future,
      );

      expect(result.authorId, equals('agro-xyz'));
    });

    test('publicação persiste no repositório após criação', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput()).future,
      );

      expect(repo.get(result.id), isNotNull);
    });
  });

  // =========================================================================
  group('Validações — ArgumentError esperado', () {
    test("titulo vazio ('') → lança ArgumentError", () {
      expect(
        () => container.read(
          createPublicacaoProvider(makeInput(titulo: '')).future,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("titulo só espaços ('   ') → lança ArgumentError", () {
      expect(
        () => container.read(
          createPublicacaoProvider(makeInput(titulo: '   ')).future,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("conteudo vazio ('') → lança ArgumentError", () {
      expect(
        () => container.read(
          createPublicacaoProvider(makeInput(conteudo: '')).future,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("conteudo só espaços ('   ') → lança ArgumentError", () {
      expect(
        () => container.read(
          createPublicacaoProvider(makeInput(conteudo: '   ')).future,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('mensagem do ArgumentError menciona o campo inválido', () async {
      Object? caughtError;
      try {
        await container.read(
          createPublicacaoProvider(makeInput(titulo: '')).future,
        );
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<ArgumentError>());
      // A mensagem deve mencionar 'título' ou 'titulo'
      expect(
        (caughtError as ArgumentError).message.toString().toLowerCase(),
        contains('título'),
      );
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('dois inputs idênticos geram IDs diferentes', () async {
      final input = makeInput();

      final containerA = makeContainer(FakePublicacaoRepository());
      final containerB = makeContainer(FakePublicacaoRepository());
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      final pubA = await containerA.read(
        createPublicacaoProvider(input).future,
      );
      final pubB = await containerB.read(
        createPublicacaoProvider(input).future,
      );

      expect(pubA.id, isNot(equals(pubB.id)));
    });

    test('createdAt é preenchido na criação', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput()).future,
      );

      expect(result.createdAt, isNotNull);
    });

    test('updatedAt == createdAt na criação', () async {
      final result = await container.read(
        createPublicacaoProvider(makeInput()).future,
      );

      // Mesmos milissegundos — criação nova não tem divergência
      expect(
        result.updatedAt.millisecondsSinceEpoch,
        equals(result.createdAt.millisecondsSinceEpoch),
      );
    });

    test('titulo com espaços nas bordas é salvo sem eles', () async {
      final result = await container.read(
        createPublicacaoProvider(
          makeInput(titulo: '   Título limpo   '),
        ).future,
      );

      expect(result.titulo, equals('Título limpo'));
      expect(result.titulo, isNot(startsWith(' ')));
      expect(result.titulo, isNot(endsWith(' ')));
    });
  });

  // =========================================================================
  group('Falha de persistência', () {
    test('repo.throwOnNextWrite = true → lança Exception', () {
      repo.throwOnNextWrite = true;

      expect(
        () => container.read(createPublicacaoProvider(makeInput()).future),
        throwsException,
      );
    });

    test('repositório permanece vazio após falha', () async {
      repo.throwOnNextWrite = true;

      try {
        await container.read(createPublicacaoProvider(makeInput()).future);
      } catch (_) {}

      expect(repo.count, equals(0));
    });
  });
}
