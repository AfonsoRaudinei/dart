/// Status possíveis de um evento na agenda
enum EventStatus {
  /// Evento planejado, ainda não iniciado
  agendado,

  /// Evento em execução no momento
  emAndamento,

  /// Evento em processo de finalização (aguardando confirmação)
  finalizando,

  /// Evento concluído com sucesso
  concluido,

  /// Evento cancelado
  cancelado;

  /// Retorna o label em português
  String get label {
    switch (this) {
      case EventStatus.agendado:
        return 'Agendado';
      case EventStatus.emAndamento:
        return 'Em Andamento';
      case EventStatus.finalizando:
        return 'Finalizando';
      case EventStatus.concluido:
        return 'Concluído';
      case EventStatus.cancelado:
        return 'Cancelado';
    }
  }

  /// Verifica se o evento pode ser editado
  bool get isEditable {
    return this == EventStatus.agendado;
  }

  /// Verifica se o evento está ativo (em execução)
  bool get isActive {
    return this == EventStatus.emAndamento || this == EventStatus.finalizando;
  }

  /// Verifica se o evento está finalizado
  bool get isFinished {
    return this == EventStatus.concluido || this == EventStatus.cancelado;
  }
}
