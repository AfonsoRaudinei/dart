import '../entities/event.dart';
import '../enums/event_status.dart';

/// Regras de negócio para transição de estado de eventos
class EventRules {
  /// Valida se a transição de status é permitida
  static bool canTransitionTo(EventStatus from, EventStatus to) {
    switch (from) {
      case EventStatus.agendado:
        return to == EventStatus.emAndamento || to == EventStatus.cancelado;

      case EventStatus.emAndamento:
        return to == EventStatus.finalizando || to == EventStatus.cancelado;

      case EventStatus.finalizando:
        return to == EventStatus.concluido || to == EventStatus.emAndamento;

      case EventStatus.concluido:
        return false; // Evento concluído não pode mudar de estado

      case EventStatus.cancelado:
        return false; // Evento cancelado não pode mudar de estado
    }
  }

  /// Retorna o próximo status válido após iniciar um evento
  static EventStatus getNextStatusOnStart(EventStatus current) {
    if (current == EventStatus.agendado) {
      return EventStatus.emAndamento;
    }
    throw StateError('Evento deve estar AGENDADO para ser iniciado');
  }

  /// Retorna o próximo status válido ao finalizar um evento
  static EventStatus getNextStatusOnFinalize(EventStatus current) {
    if (current == EventStatus.emAndamento) {
      return EventStatus.finalizando;
    }
    throw StateError('Evento deve estar EM_ANDAMENTO para finalizar');
  }

  /// Retorna o status final após conclusão
  static EventStatus getNextStatusOnComplete(EventStatus current) {
    if (current == EventStatus.finalizando) {
      return EventStatus.concluido;
    }
    throw StateError('Evento deve estar FINALIZANDO para concluir');
  }

  /// Verifica se o evento pode ser cancelado
  static bool canCancel(EventStatus status) {
    return status == EventStatus.agendado || status == EventStatus.emAndamento;
  }

  /// Detecta conflitos entre eventos
  ///
  /// Retorna lista de eventos que conflitam com o evento fornecido
  static List<Event> detectConflicts(Event event, List<Event> allEvents) {
    final conflicts = <Event>[];

    for (final other in allEvents) {
      // Ignora eventos finalizados ou cancelados
      if (other.status.isFinished) continue;

      // Verifica conflito de horário
      if (event.hasConflictWith(other)) {
        conflicts.add(other);
      }
    }

    return conflicts;
  }

  /// Valida se as datas do evento são válidas
  static String? validateEventDates(
    DateTime dataInicio,
    DateTime dataFim,
  ) {
    if (dataFim.isBefore(dataInicio)) {
      return 'Data de fim deve ser posterior à data de início';
    }

    if (dataFim.isAtSameMomentAs(dataInicio)) {
      return 'Data de fim deve ser diferente da data de início';
    }

    final duracao = dataFim.difference(dataInicio);
    if (duracao.inMinutes < 5) {
      return 'Evento deve ter no mínimo 5 minutos de duração';
    }

    return null; // Validação OK
  }

  /// Valida se o título é válido
  static String? validateTitulo(String titulo) {
    if (titulo.trim().isEmpty) {
      return 'Título não pode estar vazio';
    }

    if (titulo.trim().length < 3) {
      return 'Título deve ter no mínimo 3 caracteres';
    }

    if (titulo.length > 200) {
      return 'Título deve ter no máximo 200 caracteres';
    }

    return null; // Validação OK
  }
}
