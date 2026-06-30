import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('artefatos Fase 6 sync existem', () {
    expect(File('lib/core/services/sync_module_runner.dart').existsSync(), isTrue);
    expect(File('lib/core/services/sync_status_contract.dart').existsSync(), isTrue);
    expect(File('test/core/services/sync_orchestrator_test.dart').existsSync(), isTrue);
    expect(File('test/core/services/sync_module_runner_test.dart').existsSync(), isTrue);
    expect(File('docs/04_AUDITORIAS/FASE6_SYNC_OFFLINE_HARDENING.md').existsSync(), isTrue);
  });

  test('AgronomicSyncModule declara syncTier 0', () {
    final source = File('lib/app/sync_registration.dart').readAsStringSync();
    expect(source, contains('int get syncTier => 0'));
    expect(source, contains('class AgronomicSyncModule'));
  });

  test('SyncOrchestrator expõe lastResults pós-execução', () {
    final source = File('lib/core/services/sync_orchestrator.dart').readAsStringSync();
    expect(source, contains('List<SyncModuleResult> get lastResults'));
    expect(source, contains('runSyncModulesByTier'));
    expect(source, contains('_pendingImmediateSync'));
  });
}
