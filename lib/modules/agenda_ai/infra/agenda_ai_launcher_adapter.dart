import 'package:flutter/widgets.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_launcher.dart';
import 'package:soloforte_app/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart';

class AgendaAiLauncherAdapter implements IAgendaAiLauncher {
  const AgendaAiLauncherAdapter();

  @override
  Future<void> showSheet(BuildContext context) {
    return showAgendaAiSheet(context);
  }
}
