import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agenda providers usam @riverpod codegen (Fase 4)', () {
    final provider = File(
      'lib/modules/agenda/presentation/providers/agenda_provider.dart',
    ).readAsStringSync();
    final filters = File(
      'lib/modules/agenda/presentation/providers/agenda_filters_provider.dart',
    ).readAsStringSync();

    expect(provider, contains('@Riverpod(keepAlive: true)'));
    expect(provider, contains('class Agenda extends _\$Agenda'));
    expect(provider, isNot(contains('StateNotifierProvider')));
    expect(provider, isNot(contains('extends StateNotifier')));

    expect(filters, contains('@Riverpod(keepAlive: true)'));
    expect(filters, contains('class AgendaFilters extends _\$AgendaFilters'));
    expect(filters, isNot(contains('StateNotifierProvider')));
  });

  test('modulo agenda nao declara StateNotifier', () {
    final result = Process.runSync('rg', [
      '-l',
      'extends StateNotifier|StateNotifierProvider',
      'lib/modules/agenda/',
    ]);

    expect(result.exitCode, isNot(0));
  });
}
