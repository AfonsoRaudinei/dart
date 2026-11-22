import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/html_templates/html_report_viewer.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

import '../../domain/entities/event.dart';
import '../providers/agenda_provider.dart';
import 'agenda_visit_html_service.dart';

/// Id da sessão exigido para enviar a visita. Vazio ou ausente é erro.
String requireAgendaVisitSessionId(Event event) {
  final sessionId = event.visitSessionId?.trim() ?? '';
  if (sessionId.isEmpty) {
    throw ArgumentError.value(event.id, 'event', 'Evento sem sessão de visita');
  }
  return sessionId;
}

/// Abre o HTML da visita no visualizador que já envia página e PDF.
Future<void> openAgendaVisitShare(
  BuildContext context,
  WidgetRef ref, {
  required Event event,
}) async {
  try {
    final sessionId = event.visitSessionId?.trim() ?? '';
    final agendaState = ref.read(agendaProvider);
    final session = sessionId.isEmpty
        ? agendaState.sessions
              .where((item) => item.eventoId == event.id)
              .firstOrNull
        : agendaState.sessions
              .where((item) => item.id == sessionId)
              .firstOrNull;
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = user?.userMetadata?['name']?.toString().trim();
    final agronomistNome = metadataName != null && metadataName.isNotEmpty
        ? metadataName
        : user?.email ?? 'Agrônomo';

    final service = AgendaVisitHtmlService(
      ref.read(clientLookupProvider),
      ref.read(iFarmLookupProvider),
      ref.read(iFieldLookupProvider),
    );
    final html = await service.renderEventVisit(
      event: event,
      session: session,
      agronomistNome: agronomistNome,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HtmlReportViewer(
          title: 'Visita - ${event.titulo}',
          htmlContent: html,
          enableWhatsAppShareLink: true,
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userFacingError(e, action: 'Erro ao gerar HTML da visita'),
        ),
      ),
    );
  }
}
