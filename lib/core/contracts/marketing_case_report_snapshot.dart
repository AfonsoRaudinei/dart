/// DTO neutro para Marketing Cases na aba Relatórios → Gerados.
/// Não importa entidades de `marketing/`.
class MarketingCaseReportSnapshot {
  final String id;
  final String tipo;
  final String tipoLabel;
  final String produtorFazenda;
  final String statusValue;
  final DateTime criadoEm;
  final double lat;
  final double lng;
  final String? nomeVendedor;
  final String? clientId;

  const MarketingCaseReportSnapshot({
    required this.id,
    required this.tipo,
    required this.tipoLabel,
    required this.produtorFazenda,
    required this.statusValue,
    required this.criadoEm,
    required this.lat,
    required this.lng,
    this.nomeVendedor,
    this.clientId,
  });
}

/// Payload de exportação HTML/JSON/CSV para um case de marketing.
class MarketingCaseReportExportBundle {
  final String title;
  final String fileBaseName;
  final String html;
  final Map<String, dynamic> json;
  final String csv;

  const MarketingCaseReportExportBundle({
    required this.title,
    required this.fileBaseName,
    required this.html,
    required this.json,
    required this.csv,
  });
}
