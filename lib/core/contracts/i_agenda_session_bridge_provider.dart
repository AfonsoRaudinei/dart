// lib/core/contracts/i_agenda_session_bridge_provider.dart
//
// Provider neutro de IAgendaSessionBridge.
// A implementação concreta deve ser registrada via ProviderScope.overrides.
// ADR-024

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_agenda_session_bridge.dart';

final agendaSessionBridgeProvider = Provider<IAgendaSessionBridge>((ref) {
  throw UnimplementedError(
    'agendaSessionBridgeProvider: registrar AgendaSessionBridgeAdapter no '
    'ProviderScope (veja main.dart e ADR-024)',
  );
});
