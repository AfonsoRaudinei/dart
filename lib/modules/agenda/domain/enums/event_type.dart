/// Tipos de evento suportados pela agenda
enum EventType {
  /// Visita técnica a fazenda/talhão
  visitaTecnica,

  /// Aplicação de produto
  aplicacao,

  /// Consultoria técnica
  consultoria,

  /// Acompanhamento de colheita
  colheita,

  /// Manutenção de equipamentos/áreas
  manutencao,

  /// Reunião com cliente ou equipe
  reuniao,

  /// Lembrete simples
  lembrete,

  /// Evento personalizado pelo usuário
  personalizado;

  /// Retorna o label em português
  String get label {
    switch (this) {
      case EventType.visitaTecnica:
        return 'Visita Técnica';
      case EventType.aplicacao:
        return 'Aplicação';
      case EventType.consultoria:
        return 'Consultoria';
      case EventType.colheita:
        return 'Colheita';
      case EventType.manutencao:
        return 'Manutenção';
      case EventType.reuniao:
        return 'Reunião';
      case EventType.lembrete:
        return 'Lembrete';
      case EventType.personalizado:
        return 'Personalizado';
    }
  }

  /// Retorna ícone sugerido (emoji ou nome do ícone)
  String get icon {
    switch (this) {
      case EventType.visitaTecnica:
        return '🚜';
      case EventType.aplicacao:
        return '💧';
      case EventType.consultoria:
        return '📋';
      case EventType.colheita:
        return '🌾';
      case EventType.manutencao:
        return '🔧';
      case EventType.reuniao:
        return '👥';
      case EventType.lembrete:
        return '⏰';
      case EventType.personalizado:
        return '📌';
    }
  }

  /// Indica se o tipo requer talhão
  bool get requiresTalhao {
    return this == EventType.visitaTecnica ||
        this == EventType.aplicacao ||
        this == EventType.colheita;
  }
}
