import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'marketing_case_report_snapshot.dart';

/// Lista observável de Marketing Cases visíveis em Relatórios → Gerados.
final marketingCaseReportsListProvider =
    Provider<AsyncValue<List<MarketingCaseReportSnapshot>>>((ref) {
      throw UnimplementedError(
        'marketingCaseReportsListProvider: registrar override em main.dart '
        '(veja ADR-048)',
      );
    });
