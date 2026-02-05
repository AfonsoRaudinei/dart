enum ReportType { semanal, ndvi, safra, pragas, personalizado }

class Report {
  final String id;
  final String title;
  final ReportType type;
  final String clientId;
  final DateTime startDate;
  final DateTime endDate;
  final String content;
  final DateTime createdAt;
  final String author;
  final List<String> images;
  final String? observations;

  Report({
    required this.id,
    required this.title,
    required this.type,
    required this.clientId,
    required this.startDate,
    required this.endDate,
    required this.content,
    required this.createdAt,
    required this.author,
    this.images = const [],
    this.observations,
  });

  String get typeDisplayName {
    switch (type) {
      case ReportType.semanal:
        return 'Relatório Semanal';
      case ReportType.ndvi:
        return 'Análise de NDVI';
      case ReportType.safra:
        return 'Acompanhamento de Safra';
      case ReportType.pragas:
        return 'Controle de Pragas';
      case ReportType.personalizado:
        return 'Personalizado';
    }
  }
}
