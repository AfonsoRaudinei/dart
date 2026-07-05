import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'agenda_ai_recommendation_context.dart';
import 'i_agenda_ai_launcher.dart';

/// Contexto efêmero definido pelo mapa imediatamente antes de abrir o sheet.
final agendaAiLaunchContextProvider = StateProvider<AgendaAiLaunchContext?>(
  (ref) => null,
);

final agendaAiLauncherProvider = Provider<IAgendaAiLauncher>((ref) {
  throw UnimplementedError(
    'agendaAiLauncherProvider: registrar AgendaAiLauncherAdapter no ProviderScope.',
  );
});
