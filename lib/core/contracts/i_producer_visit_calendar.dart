/// Visita confirmada pelo consultor, no calendário do produtor.
class ProducerVisitCalendarEntry {
  const ProducerVisitCalendarEntry({
    required this.sessionId,
    required this.clientId,
    required this.visitedAt,
    required this.confirmedAt,
    required this.farmName,
    required this.fieldName,
    required this.occurrences,
  });

  final String sessionId;
  final String clientId;
  final DateTime visitedAt;
  final DateTime confirmedAt;
  final String farmName;
  final String fieldName;
  final List<ProducerVisitOccurrenceLine> occurrences;
}

/// Ocorrência feita durante a visita confirmada.
class ProducerVisitOccurrenceLine {
  const ProducerVisitOccurrenceLine({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Dados que o consultor confirma para o produtor.
class ProducerVisitConfirmationInput {
  const ProducerVisitConfirmationInput({
    required this.sessionId,
    required this.clientId,
    required this.visitedAt,
    this.farmName,
    this.fieldName,
  });

  final String sessionId;
  final String clientId;
  final DateTime visitedAt;
  final String? farmName;
  final String? fieldName;
}

/// Calendário do produtor. A agenda do consultor não é exposta.
/// ADR-061
abstract interface class IProducerVisitCalendar {
  Future<void> confirmVisit(ProducerVisitConfirmationInput input);

  Future<bool> isConfirmed(String sessionId);

  /// Visitas confirmadas dos clientes vinculados ao produtor atual.
  Future<List<ProducerVisitCalendarEntry>> listForProducer();
}
