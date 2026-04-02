// lib/core/contracts/i_report_writer_provider.dart
//
// Provider neutro de IReportWriter.
// A implementação concreta deve ser registrada via ProviderScope.overrides.
// ADR-025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_report_writer.dart';

final reportWriterProvider = Provider<IReportWriter>((ref) {
  throw UnimplementedError(
    'reportWriterProvider: registrar ReportWriterAdapter no '
    'ProviderScope (veja main.dart e ADR-025)',
  );
});
