import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import 'package:soloforte_app/ui/screens/private_map_bootstrap_screen.dart';

class _StaticConnectivityService extends ConnectivityService {
  _StaticConnectivityService(this._connected);

  final bool _connected;

  @override
  Future<bool> get isConnected async => _connected;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('restorePrivateMapLocalData', () {
    test('clientsCount > 0 não espera sync', () async {
      var syncCalls = 0;
      final hanging = Completer<void>();

      final result = await restorePrivateMapLocalData(
        userId: 'user-1',
        clientsCount: 3,
        agendaEventsCount: 1,
        recountClients: () async => 3,
        recountAgenda: () async => 1,
        triggerImmediateSync: () {
          syncCalls++;
          return hanging.future;
        },
        lastError: () => null,
        isOnline: () async => true,
        timeout: const Duration(milliseconds: 30),
      );

      expect(syncCalls, 0);
      expect(result.clientsCount, 3);
      hanging.complete();
    });

    test('userId vazio não espera sync', () async {
      var syncCalls = 0;

      final result = await restorePrivateMapLocalData(
        userId: '',
        clientsCount: 0,
        agendaEventsCount: 0,
        recountClients: () async => 0,
        recountAgenda: () async => 0,
        triggerImmediateSync: () async {
          syncCalls++;
        },
        lastError: () => null,
        isOnline: () async => true,
      );

      expect(syncCalls, 0);
      expect(result.clientsCount, 0);
    });

    test('DB vazio + userId espera sync e reabre com recount', () async {
      var syncCalls = 0;
      final gate = Completer<void>();
      var returnedBeforeSync = true;

      final future = restorePrivateMapLocalData(
        userId: 'user-1',
        clientsCount: 0,
        agendaEventsCount: 0,
        recountClients: () async => 4,
        recountAgenda: () async => 2,
        triggerImmediateSync: () {
          syncCalls++;
          return gate.future;
        },
        lastError: () => null,
        isOnline: () async => true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(syncCalls, 1);
      expect(returnedBeforeSync, isTrue);

      returnedBeforeSync = false;
      gate.complete();
      final result = await future;

      expect(returnedBeforeSync, isFalse);
      expect(result.clientsCount, 4);
      expect(result.agendaEventsCount, 2);
    });

    test('sync sem erro e recount 0 online abre mapa (conta nova)', () async {
      final result = await restorePrivateMapLocalData(
        userId: 'user-1',
        clientsCount: 0,
        agendaEventsCount: 0,
        recountClients: () async => 0,
        recountAgenda: () async => 0,
        triggerImmediateSync: () async {},
        lastError: () => null,
        isOnline: () async => true,
      );

      expect(result.clientsCount, 0);
    });

    test('timeout falha com PrivateMapRestoreException', () async {
      await expectLater(
        restorePrivateMapLocalData(
          userId: 'user-1',
          clientsCount: 0,
          agendaEventsCount: 0,
          recountClients: () async => 0,
          recountAgenda: () async => 0,
          triggerImmediateSync: () => Completer<void>().future,
          lastError: () => null,
          isOnline: () async => true,
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<PrivateMapRestoreException>()),
      );
    });

    test('lastError após sync falha com PrivateMapRestoreException', () async {
      await expectLater(
        restorePrivateMapLocalData(
          userId: 'user-1',
          clientsCount: 0,
          agendaEventsCount: 0,
          recountClients: () async => 0,
          recountAgenda: () async => 0,
          triggerImmediateSync: () async {},
          lastError: () => 'Erro em clientes: jwt',
          isOnline: () async => true,
        ),
        throwsA(isA<PrivateMapRestoreException>()),
      );
    });

    test('offline com recount 0 é falha recuperável', () async {
      await expectLater(
        restorePrivateMapLocalData(
          userId: 'user-1',
          clientsCount: 0,
          agendaEventsCount: 0,
          recountClients: () async => 0,
          recountAgenda: () async => 0,
          triggerImmediateSync: () async {},
          lastError: () => null,
          isOnline: () async => false,
        ),
        throwsA(isA<PrivateMapRestoreException>()),
      );
    });
  });

  group('PrivateMapBootstrapScreen', () {
    testWidgets('loading mostra Sincronizando seus dados…', (tester) async {
      final pending = Completer<PrivateMapBootstrapResult>();
      addTearDown(() {
        if (!pending.isCompleted) pending.complete((clientsCount: 0, agendaEventsCount: 0));
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(
              _StaticConnectivityService(true),
            ),
            syncOrchestratorProvider.overrideWith(
              (ref) => SyncOrchestrator(ref, enableObservers: false),
            ),
            privateMapBootstrapProvider.overrideWith((ref) => pending.future),
          ],
          child: const MaterialApp(home: PrivateMapBootstrapScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Sincronizando seus dados…'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);
    });

    testWidgets('erro de restore mostra tentar novamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(
              _StaticConnectivityService(false),
            ),
            syncOrchestratorProvider.overrideWith(
              (ref) => SyncOrchestrator(ref, enableObservers: false),
            ),
            privateMapBootstrapProvider.overrideWith(
              (ref) async => throw const PrivateMapRestoreException(),
            ),
          ],
          child: const MaterialApp(home: PrivateMapBootstrapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível restaurar os dados. Verifique a conexão.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets(
      'sucesso após sync mostra o mapa e não o loading',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityServiceProvider.overrideWithValue(
                _StaticConnectivityService(true),
              ),
              syncOrchestratorProvider.overrideWith(
                (ref) => SyncOrchestrator(ref, enableObservers: false),
              ),
              privateMapBootstrapProvider.overrideWith(
                (ref) async => (clientsCount: 2, agendaEventsCount: 0),
              ),
            ],
            child: const MaterialApp(
              home: PrivateMapBootstrapScreen(
                mapOverride: SizedBox(key: Key('private-map')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('private-map')), findsOneWidget);
        expect(find.text('Sincronizando seus dados…'), findsNothing);
        expect(find.text('Tentar novamente'), findsNothing);
      },
    );
  });
}
