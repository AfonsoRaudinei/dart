import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'marketing_case_report_snapshot.dart';
import 'marketing_case_reports_list_policy.dart';

/// Lista observável de Marketing Cases visíveis em Relatórios → Gerados.
///
/// Critérios de elegibilidade: ADR-051 + [isEligibleForGeradosTab].
/// Implementação: `marketingCaseReportsListImplProvider` em
/// `marketing/infra/marketing_case_reports_lookup_adapter.dart`.
/// Ações (delete, edit, export) permanecem em `IMarketingCaseReportsLookup`.
final marketingCaseReportsListProvider =
    Provider<AsyncValue<List<MarketingCaseReportSnapshot>>>((ref) {
      throw UnimplementedError(
        'marketingCaseReportsListProvider: registrar override em main.dart '
        '(veja ADR-050 e ADR-051)',
      );
    });
