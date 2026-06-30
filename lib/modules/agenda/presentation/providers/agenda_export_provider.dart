import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_opportunity_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/services/agenda_html_export_service.dart';

final agendaExportProvider = FutureProvider.autoDispose
    .family<String, List<Event>>((ref, events) async {
      final clientLookup = ref.watch(clientLookupProvider);
      final opportunityLookup = ref.watch(opportunityLookupProvider);
      final clientIds = events.map((event) => event.clienteId).toSet();

      final clientEntries = await Future.wait(
        clientIds.map((clientId) async {
          final client = await clientLookup.findById(clientId);
          return MapEntry(clientId, client);
        }),
      );

      final opportunityEntries = await Future.wait(
        clientIds.map((clientId) async {
          final opportunities = await opportunityLookup.getOpenOpportunities(
            clientId,
          );
          return MapEntry(clientId, opportunities);
        }),
      );

      return AgendaHtmlExportService().export(
        events: events,
        clientes: <String, ClientSummary>{
          for (final entry in clientEntries)
            if (entry.value != null) entry.key: entry.value!,
        },
        oportunidades: <String, List<OpportunitySummary>>{
          for (final entry in opportunityEntries) entry.key: entry.value,
        },
      );
    });
