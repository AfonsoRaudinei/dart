// lib/core/contracts/i_visit_report_provider.dart
//
// Provider neutro de IVisitReportRepository.
// A implementação concreta deve ser registrada via ProviderScope.overrides.
// ADR-024

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_visit_report_repository.dart';

final visitReportProvider = Provider<IVisitReportRepository>((ref) {
  throw UnimplementedError(
    'visitReportProvider: registrar VisitReportAdapter no '
    'ProviderScope (veja main.dart e ADR-024)',
  );
});
