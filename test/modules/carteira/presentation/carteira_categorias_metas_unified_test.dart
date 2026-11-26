import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_meta.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_safra.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_ajuda_card.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_metas_tab.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

void main() {
  const userId = 'user-unified-carteira';

  setUp(() {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember(userId);
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  final categoria = CategoriaGlobal(
    id: 'cat-1',
    userId: userId,
    nome: 'Nutrição',
    cor: '#4ADE80',
    ativo: true,
    ordem: 0,
    unidadeCodigo: 'rs_ha',
    unidadeLabel: r'R$/ha',
    converteSacasHa: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final safra = CarteiraSafra(
    id: 'safra-1',
    userId: userId,
    nome: '2025/26',
    dataInicio: DateTime(2025, 9, 1),
    dataFim: DateTime(2026, 8, 31),
    ativa: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  ProviderScope scope({required Widget child}) {
    return ProviderScope(
      overrides: [
        valorGraoProvider.overrideWith((ref) async => 120.0),
        safraAtivaProvider.overrideWith((ref) async => safra),
        categoriasGlobaisProvider(userId).overrideWith((ref) async => [categoria]),
        metasSafraAtivaProvider.overrideWith((ref) async => const <CarteiraMeta>[]),
        progressoCategoriaProvider('cat-1')
            .overrideWith((ref) async => 0.0),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('aba Categorias unificada mostra grão e Nova categoria', (
    tester,
  ) async {
    await tester.pumpWidget(scope(child: const CarteiraMetasTab()));
    await tester.pumpAndSettle();

    expect(find.text('Valor do grão'), findsOneWidget);
    expect(find.text('Safra ativa'), findsNothing);
    expect(find.text('Nenhuma safra ativa'), findsNothing);
    expect(find.text('Nova categoria'), findsOneWidget);
    expect(
      find.text(CarteiraAjudaTextos.resumo(CarteiraSegment.categorias)),
      findsOneWidget,
    );
    expect(find.text('Nutrição'), findsOneWidget);
    expect(find.text('Metas da safra ativa'), findsOneWidget);
  });

  testWidgets('item de categoria oferece menu Editar e Desativar categoria', (
    tester,
  ) async {
    await tester.pumpWidget(scope(child: const CarteiraMetasTab()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Editar categoria'), findsOneWidget);
    expect(find.text('Desativar categoria'), findsOneWidget);
  });

  testWidgets(
    'sem safra ativa ainda lista categorias com banner e menu',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            valorGraoProvider.overrideWith((ref) async => 120.0),
            safraAtivaProvider.overrideWith((ref) async => null),
            categoriasGlobaisProvider(userId)
                .overrideWith((ref) async => [categoria]),
            metasSafraAtivaProvider
                .overrideWith((ref) async => const <CarteiraMeta>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CarteiraMetasTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma safra ativa'), findsOneWidget);
      expect(find.text('+ Nova safra'), findsOneWidget);
      expect(
        find.text('Crie uma safra para definir metas por categoria.'),
        findsOneWidget,
      );
      expect(find.text('Nutrição'), findsOneWidget);
      expect(find.text('Sem meta definida'), findsOneWidget);
      final menu = find.byIcon(Icons.more_vert);
      expect(menu, findsOneWidget);

      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();

      expect(find.text('Editar categoria'), findsOneWidget);
      expect(find.text('Desativar categoria'), findsOneWidget);
    },
  );
}