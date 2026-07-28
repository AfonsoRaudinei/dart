// lib/core/contracts/i_visit_session_writer_provider.dart
//
// Provider neutro de IVisitSessionWriter (ADR-048).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_visit_session_writer.dart';

final visitSessionWriterProvider = Provider<IVisitSessionWriter>((ref) {
  throw UnimplementedError(
    'visitSessionWriterProvider: registrar VisitSessionWriterAdapter no '
    'ProviderScope (veja main.dart e ADR-048)',
  );
});
