/// Enum para as diferentes views/abas da agenda
enum AgendaView {
  /// View de calendário mensal (padrão atual)
  calendario,

  /// View de planejamento semanal (modelo da skill)
  planejamento,

  /// View de indicadores e métricas
  indicadores,
}

extension AgendaViewExtension on AgendaView {
  String get label {
    switch (this) {
      case AgendaView.calendario:
        return 'Calendário';
      case AgendaView.planejamento:
        return 'Planejamento';
      case AgendaView.indicadores:
        return 'Indicadores';
    }
  }

  String get icon {
    switch (this) {
      case AgendaView.calendario:
        return '📅';
      case AgendaView.planejamento:
        return '📋';
      case AgendaView.indicadores:
        return '📊';
    }
  }
}
