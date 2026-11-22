import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/ui/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arrastar a barrinha para baixo volta ao mapa público', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/public-map',
          builder: (_, _) => const Scaffold(body: Text('mapa publico')),
        ),
        GoRoute(
          path: '/recover-password',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(path: '/register', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketingCaseRepositoryProvider.overrideWithValue(_NoopRepo()),
          marketingSyncServiceProvider.overrideWith(
            (ref) => MarketingSyncService(
              ref.watch(marketingCaseRepositoryProvider),
            ),
          ),
          marketingCasesProvider.overrideWith((ref) {
            return _EmptyCasesNotifier(
              ref.watch(marketingCaseRepositoryProvider),
              ref.watch(marketingSyncServiceProvider),
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Entrar'), findsOneWidget);

    final handle = find.byKey(const Key('login-sheet-handle'));
    expect(handle, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();

    final translated = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((transform) => transform.transform.getTranslation().y)
        .reduce((a, b) => a > b ? a : b);
    expect(translated, greaterThan(40));

    await gesture.moveBy(const Offset(0, -80));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('mapa publico'), findsNothing);

    final dismiss = await tester.startGesture(tester.getCenter(handle));
    await dismiss.moveBy(const Offset(0, 40));
    await tester.pump();
    await dismiss.moveBy(const Offset(0, 180));
    await tester.pump();
    final mid = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((transform) => transform.transform.getTranslation().y)
        .reduce((a, b) => a > b ? a : b);
    expect(mid, greaterThan(120));
    await dismiss.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('mapa publico'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/public-map');
  });

  testWidgets('devolver o formulário à origem não fecha o login', (
    tester,
  ) async {
    final router = await _pumpLogin(tester, const Size(400, 2000));
    final subtitle = find.text('Entre para continuar seu trabalho no campo.');
    expect(subtitle, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(subtitle));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('Entrar'), findsOneWidget);
  });
}

Future<GoRouter> _pumpLogin(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/public-map',
        builder: (_, _) => const Scaffold(body: Text('mapa publico')),
      ),
      GoRoute(
        path: '/recover-password',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(path: '/register', builder: (_, _) => const SizedBox.shrink()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        marketingCaseRepositoryProvider.overrideWithValue(_NoopRepo()),
        marketingSyncServiceProvider.overrideWith(
          (ref) =>
              MarketingSyncService(ref.watch(marketingCaseRepositoryProvider)),
        ),
        marketingCasesProvider.overrideWith((ref) {
          return _EmptyCasesNotifier(
            ref.watch(marketingCaseRepositoryProvider),
            ref.watch(marketingSyncServiceProvider),
          );
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  expect(find.text('Entrar'), findsOneWidget);
  return router;
}

class _EmptyCasesNotifier extends MarketingCasesNotifier {
  _EmptyCasesNotifier(
    IMarketingCaseRepository repository,
    MarketingSyncService syncService,
  ) : super(repository, syncService, null) {
    state = const AsyncData([]);
  }
}

class _NoopRepo implements IMarketingCaseRepository {
  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => const [];

  @override
  Future<List<MarketingCase>> getLocalCases() async => const [];

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<MarketingCase> softDelete(String id) async =>
      throw UnimplementedError();
}
