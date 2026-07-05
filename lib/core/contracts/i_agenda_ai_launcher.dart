import 'package:flutter/widgets.dart';

import 'agenda_ai_recommendation_context.dart';

abstract interface class IAgendaAiLauncher {
  Future<void> showSheet(
    BuildContext context, {
    AgendaAiLaunchContext? launchContext,
  });
}
