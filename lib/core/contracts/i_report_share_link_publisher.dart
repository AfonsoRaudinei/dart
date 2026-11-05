/// Publicação de HTML de relatório para link público (WhatsApp / browser).
/// ADR-053 — implementação em consultoria/relatorios/data/.
abstract interface class IReportShareLinkPublisher {
  Future<ReportShareLinkPublished> publishHtml({
    required String title,
    required String html,
    String? reportKind,
  });
}

class ReportShareLinkPublished {
  const ReportShareLinkPublished({
    required this.publicUrl,
    required this.token,
    required this.storagePath,
  });

  final String publicUrl;
  final String token;
  final String storagePath;
}
