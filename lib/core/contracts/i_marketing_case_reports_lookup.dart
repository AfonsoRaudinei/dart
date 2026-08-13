import 'package:flutter/material.dart';

import 'marketing_case_report_snapshot.dart';

/// Lookup e ações de Marketing Cases para `consultoria/relatorios/`.
/// Implementação: `marketing/infra/marketing_case_reports_lookup_adapter.dart`
abstract interface class IMarketingCaseReportsLookup {
  Future<void> deleteCase(String id);

  Future<void> showEditSheet(BuildContext context, String caseId);

  /// Publica um rascunho se houver vaga no plano. Retorna `true` se publicado.
  Future<bool> publishDraftCase(BuildContext context, String caseId);

  Future<MarketingCaseReportExportBundle> buildExportBundle(
    String caseId, {
    required String? fallbackConsultantName,
    required String fallbackConsultantRole,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
  });
}
