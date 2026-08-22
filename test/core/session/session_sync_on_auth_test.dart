import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';

class _RecordingOrchestrator extends SyncOrchestrator {
  _RecordingOrchestrator(super.ref) : super(enableObservers: false);

  int triggerCount = 0;
  final List<SyncPriority> priorities = <SyncPriority>[];

  @override
  Future<void> triggerSync(SyncPriority priority) async {
    triggerCount++;
    priorities.add(priority);
  }
}

class _StaticConnectivityService extends ConnectivityService {
  @override
  Future<bool> get isConnected async => true;
}

class _BareSessionController extends SessionController {
  @override
  SessionState build() => const SessionUnknown();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _RecordingOrchestrator orchestrator;
  late SessionController session;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        connectivityServiceProvider.overrideWithValue(
          _StaticConnectivityService(),
        ),
        syncOrchestratorProvider.overrideWith((ref) {
          return _RecordingOrchestrator(ref);
        }),
        sessionControllerProvider.overrideWith(_BareSessionController.new),
      ],
    );
    orchestrator =
        container.read(syncOrchestratorProvider) as _RecordingOrchestrator;
    session = container.read(sessionControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('requestHydrateAfterAuth dispara triggerSync uma vez por userId', () {
    session.requestHydrateAfterAuth('user-1');
    session.requestHydrateAfterAuth('user-1');
    session.requestHydrateAfterAuth(' user-1 ');

    expect(orchestrator.triggerCount, 1);
    expect(orchestrator.priorities, [SyncPriority.immediate]);
  });

  test('userId novo dispara outro hydrate', () {
    session.requestHydrateAfterAuth('user-1');
    session.requestHydrateAfterAuth('user-2');

    expect(orchestrator.triggerCount, 2);
  });

  test('logout/reset libera hydrate do mesmo userId', () {
    session.requestHydrateAfterAuth('user-1');
    session.resetHydrateAfterAuth();
    session.requestHydrateAfterAuth('user-1');

    expect(orchestrator.triggerCount, 2);
  });
}
