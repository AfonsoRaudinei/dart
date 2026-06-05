import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/visita_html_renderer.dart';

import '../../domain/entities/event.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/enums/event_status.dart';

class AgendaVisitHtmlService {
  const AgendaVisitHtmlService(
    this._clientLookup, [
    this._farmLookup,
    this._fieldLookup,
  ]);

  final IClientLookup _clientLookup;
  final IFarmLookup? _farmLookup;
  final IFieldLookup? _fieldLookup;

  Future<String> renderEventVisit({
    required Event event,
    VisitSession? session,
    required String agronomistNome,
  }) async {
    final clienteNome = await _resolveClientName(event.clienteId);
    final farmName = await _resolveFarmName(event);
    final talhoes = await _talhoes(event);
    final notes = _buildNotes(event, session);

    return VisitaHtmlRenderer.render(
      relatorio: {
        'id': event.visitSessionId ?? event.id,
        'visitSessionId': event.visitSessionId ?? event.id,
        'clientId': event.clienteId,
        'agronomistId': session?.createdBy ?? agronomistNome,
        'farmName': farmName,
        'periodStart': event.dataInicioPlanejada.toIso8601String(),
        'periodEnd': event.dataFimPlanejada.toIso8601String(),
        'status': _statusForTemplate(event.status),
        'syncStatus': event.syncStatus,
        'createdAt': event.createdAt.toIso8601String(),
        'updatedAt': event.updatedAt.toIso8601String(),
        'deletedAt': null,
        'title': event.titulo,
        'customNotes': notes,
        'publicacoesRefs': const <String>[],
        'ocorrencias': const <Map<String, dynamic>>[],
        'talhoes': talhoes,
        'fotos': const <String>[],
        'monitoramentos': const <Map<String, dynamic>>[],
      },
      agronomistNome: agronomistNome,
      clienteNome: clienteNome,
      publicacoesTitulos: const {},
    );
  }

  Future<String> _resolveClientName(String clientId) async {
    try {
      final client = await _clientLookup.findById(clientId);
      if (client?.name.trim().isNotEmpty == true) return client!.name;
    } catch (_) {
      // Fallback abaixo.
    }
    return 'Cliente ${RelatorioHtmlRenderer.shortId(clientId)}';
  }

  Future<String> _resolveFarmName(Event event) async {
    final farmId = event.fazendaId;
    if (farmId != null && farmId.isNotEmpty && _farmLookup != null) {
      try {
        final farm = await _farmLookup.findById(farmId);
        if (farm?.name.trim().isNotEmpty == true) return farm!.name;
      } catch (_) {
        // Fallback abaixo.
      }
    }
    return event.titulo.trim().isNotEmpty ? event.titulo : 'Visita agendada';
  }

  String _buildNotes(Event event, VisitSession? session) {
    final parts = <String>[
      'Origem: agenda de visita.',
      'Tipo: ${event.tipo.label}.',
      'Status atual: ${event.status.label}.',
      if (session?.notasFinais?.trim().isNotEmpty == true)
        'Notas finais: ${session!.notasFinais!.trim()}',
    ];
    return parts.join('\n');
  }

  Future<List<Map<String, dynamic>>> _talhoes(Event event) async {
    final talhaoId = event.talhaoId;
    if (talhaoId == null || talhaoId.isEmpty) return const [];

    final field = await _resolveField(talhaoId, event.fazendaId);
    if (field != null) {
      return [
        {
          'talhaoId': field.id,
          'nomeTalhao': field.name,
          'cultura': field.crop ?? '',
          'safra': field.harvest ?? '',
          'areaHectares': field.areaHa,
        },
      ];
    }

    return [
      {
        'talhaoId': talhaoId,
        'nomeTalhao': 'Talhão ${RelatorioHtmlRenderer.shortId(talhaoId)}',
        'cultura': '',
        'safra': '',
        'areaHectares': null,
      },
    ];
  }

  Future<FieldSummary?> _resolveField(String fieldId, String? farmId) async {
    final lookup = _fieldLookup;
    if (lookup == null) return null;

    try {
      final direct = await lookup.findById(fieldId);
      if (direct != null) return direct;

      if (farmId != null && farmId.isNotEmpty) {
        final fields = await lookup.listByFarmId(farmId);
        return fields.where((field) => field.id == fieldId).firstOrNull;
      }
    } catch (_) {
      // Fallback com ID curto abaixo.
    }
    return null;
  }

  String _statusForTemplate(EventStatus status) {
    switch (status) {
      case EventStatus.concluido:
        return 'publicado';
      case EventStatus.cancelado:
        return 'arquivado';
      case EventStatus.agendado:
      case EventStatus.emAndamento:
      case EventStatus.finalizando:
        return 'pendente_revisao';
    }
  }
}
