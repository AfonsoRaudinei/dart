import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_safra.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_module_scaffold.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_safra_chip.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

const _userId = 'user-carteira-test';

CarteiraSafra _safra(String id, int inicio, {required bool ativa}) =>
    CarteiraSafra(
      id: id,
      userId: _userId,
      nome: 'Safra $inicio/${inicio + 1}',
      dataInicio: DateTime(inicio, 9, 1),
      dataFim: DateTime(inicio + 1, 8, 31),
      ativa: ativa,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _app(_FakeSafraRepository repo) {
  return ProviderScope(
    overrides: [
      carteiraRepositoryProvider.overrideWithValue(repo),
      safraAtivaProvider.overrideWith(
        (ref) => ref.watch(carteiraRepositoryProvider).getSafraAtiva(_userId),
      ),
      safrasProvider.overrideWith(
        (ref) => ref.watch(carteiraRepositoryProvider).getSafras(_userId),
      ),
    ],
    child: const MaterialApp(
      home: CarteiraModuleScaffold(
        title: 'Carteira',
        body: Center(child: Text('Conteúdo')),
      ),
    ),
  );
}

void main() {
  setUp(() {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember(_userId);
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  testWidgets('CarteiraModuleScaffold mantém segment bar visível', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeSafraRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('Oportunidades'), findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
  });

  testWidgets('chip de safra fica acima das abas e mostra a safra ativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeSafraRepository([_safra('s26', 2026, ativa: true)])),
    );
    await tester.pumpAndSettle();

    final chip = find.byType(CarteiraSafraChip);
    expect(chip, findsOneWidget);
    expect(find.text('Safra 2026/2027'), findsOneWidget);
    expect(
      tester.getTopLeft(chip).dy,
      lessThan(tester.getTopLeft(find.byType(CarteiraSegmentBar)).dy),
    );
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
  });

  testWidgets('sem safra o chip convida a criar uma', (tester) async {
    await tester.pumpWidget(_app(_FakeSafraRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Criar safra'), findsOneWidget);
  });

  testWidgets('seletor troca a safra ativa e atualiza o chip', (tester) async {
    final repo = _FakeSafraRepository([
      _safra('s26', 2026, ativa: true),
      _safra('s25', 2025, ativa: false),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CarteiraSafraChip));
    await tester.pumpAndSettle();

    expect(find.text('Safra 2025/2026'), findsOneWidget);
    expect(find.text('01/09/2025 → 31/08/2026'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Nova safra'), findsOneWidget);

    await tester.tap(find.text('Safra 2025/2026'));
    await tester.pumpAndSettle();

    expect(repo.ativadas, ['s25']);
    expect(find.text('Nova safra'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CarteiraSafraChip),
        matching: find.text('Safra 2025/2026'),
      ),
      findsOneWidget,
    );
  });

  test('carteiraSegmentProvider inicia em Clientes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(carteiraSegmentProvider), CarteiraSegment.clientes);
  });
}

class _FakeSafraRepository extends Fake implements ICarteiraRepository {
  _FakeSafraRepository(this._safras);

  List<CarteiraSafra> _safras;
  final List<String> ativadas = [];

  @override
  Future<List<CarteiraSafra>> getSafras(String userId) async => _safras;

  @override
  Future<CarteiraSafra?> getSafraAtiva(String userId) async {
    for (final s in _safras) {
      if (s.ativa) return s;
    }
    return null;
  }

  @override
  Future<void> ativarSafra(String safraId, String userId) async {
    ativadas.add(safraId);
    _safras = [
      for (final s in _safras)
        CarteiraSafra(
          id: s.id,
          userId: s.userId,
          nome: s.nome,
          dataInicio: s.dataInicio,
          dataFim: s.dataFim,
          ativa: s.id == safraId,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
        ),
    ];
  }
}
