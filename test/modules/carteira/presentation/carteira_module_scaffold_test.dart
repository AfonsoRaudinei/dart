import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_module_scaffold.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

void main() {
  setUp(() {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember('user-carteira-test');
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  testWidgets('CarteiraModuleScaffold mantém segment bar visível', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CarteiraModuleScaffold(
            title: 'Carteira',
            body: Center(child: Text('Conteúdo')),
          ),
        ),
      ),
    );

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Oportunidades'), findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
  });

  test('carteiraSegmentProvider inicia em Clientes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(carteiraSegmentProvider), CarteiraSegment.clientes);
  });
}
