import 'agenda_ai_recommendation_context.dart';

/// Cria visita sugerida pela IA sem importar agenda/ em agenda_ai/. ADR-046.
abstract interface class IAgendaAiVisitWriter {
  Future<void> createSuggestedVisit(AgendaAiSuggestedVisitRequest request);
}
