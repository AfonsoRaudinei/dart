// lib/core/contracts/i_agenda_observable_provider.dart
//
// Provider neutro de AgendaObservableState.
// A implementação concreta deve ser registrada via ProviderScope.overrides.
// ADR-025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_agenda_observable.dart';

final agendaObservableProvider = Provider<AgendaObservableState>((ref) {
  throw UnimplementedError(
    'agendaObservableProvider: registrar override em '
    'ProviderScope (veja main.dart e ADR-025)',
  );
});
