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
    // Varredura em Dart puro: não depender de binários externos (rg)
    // torna o teste portável para qualquer máquina/CI.
    final pattern = RegExp('extends StateNotifier|StateNotifierProvider');
    final offenders = Directory('lib/modules/agenda')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => pattern.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
