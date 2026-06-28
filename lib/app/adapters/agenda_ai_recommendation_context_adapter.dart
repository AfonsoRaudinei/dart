import 'package:soloforte_app/core/contracts/agenda_ai_recommendation_context.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_recommendation_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/modules/agenda/data/repositories/agenda_repository.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_meta.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';

/// Composição app-level: carteira + agenda + IClientLookup. ADR-046.
class AgendaAiRecommendationContextAdapter
    implements IAgendaAiRecommendationContextLookup {
  AgendaAiRecommendationContextAdapter({
    required ICarteiraRepository carteiraRepository,
    required AgendaRepository agendaRepository,
    required IClientLookup clientLookup,
  }) : _carteiraRepository = carteiraRepository,
       _agendaRepository = agendaRepository,
       _clientLookup = clientLookup;

  final ICarteiraRepository _carteiraRepository;
  final AgendaRepository _agendaRepository;
  final IClientLookup _clientLookup;

  @override
  Future<AgendaAiRecommendationContext> buildForUser(String userId) async {
    final safra = await _carteiraRepository.getSafraAtiva(userId);
    if (safra == null) {
      throw StateError('Crie uma safra ativa para habilitar sugestões da IA.');
    }

    final clients = await _clientLookup.listAtivos();
    if (clients.isEmpty) {
      throw StateError(
        'Cadastre ao menos 1 cliente para receber sugestões da IA.',
      );
    }

    final metas = await _carteiraRepository.getMetasBySafra(safra.id, userId);
    if (metas.isEmpty) {
      throw StateError(
        'Configure metas da carteira para liberar recomendações da IA.',
      );
    }

    final target = await _selectTargetMeta(metas, safra.id, userId);
    final targetAchieved = await _carteiraRepository.getRealizadoBySafraCategoria(
      safra.id,
      target.categoriaId,
      userId,
    );

    final registros = await _carteiraRepository.getTodosRegistros(userId);
    final targetRegistros = registros
        .where((r) => r.categoriaId == target.categoriaId)
        .where((r) => r.percentualFechado < 100)
        .toList(growable: false);

    final events = await _agendaRepository.getAllEvents();
    final byId = {for (final c in clients) c.id: c};

    final opportunities = targetRegistros
        .map((registro) {
          final client = byId[registro.clienteId];
          return AgendaAiClientOpportunity(
            clientId: registro.clienteId,
            clientName: client?.name ?? 'Cliente',
            categoryId: registro.categoriaId,
            categoryProgressPercent: registro.percentualFechado.toDouble(),
            categoryAchievedValue:
                (target.quantidade * registro.percentualFechado) / 100.0,
            lastVisitAt: _lastVisitAt(events, registro.clienteId),
          );
        })
        .toList(growable: false);

    return AgendaAiRecommendationContext(
      userId: userId,
      targetCategoryId: target.categoriaId,
      annualTargetValue: target.quantidade,
      annualAchievedValue: targetAchieved,
      opportunities: opportunities,
    );
  }

  Future<CarteiraMeta> _selectTargetMeta(
    List<CarteiraMeta> metas,
    String safraId,
    String userId,
  ) async {
    CarteiraMeta? selected;
    double maxGap = -1;

    for (final meta in metas) {
      final achieved = await _carteiraRepository.getRealizadoBySafraCategoria(
        safraId,
        meta.categoriaId,
        userId,
      );
      final gap = (meta.quantidade - achieved).clamp(0, double.infinity);
      if (gap > maxGap) {
        maxGap = gap.toDouble();
        selected = meta;
      }
    }

    return selected ?? metas.first;
  }

  DateTime? _lastVisitAt(List<dynamic> events, String clienteId) {
    DateTime? last;
    for (final event in events) {
      if (event.clienteId != clienteId) continue;
      final dt = event.dataInicioPlanejada as DateTime;
      if (last == null || dt.isAfter(last)) {
        last = dt;
      }
    }
    return last;
  }
}
