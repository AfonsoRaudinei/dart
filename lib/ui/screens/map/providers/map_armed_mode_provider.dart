// TODO(ADR-030): provider extraído de private_map_screen.dart — F1
// Migra _armedMode de setState local para StateProvider Riverpod.
// Remove DT futuro de setState para Riverpod.
// Valores reais confirmados no PASSO 0: none, occurrences, marketing.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ArmedMode { none, occurrences, marketing }

final armedModeProvider = StateProvider<ArmedMode>(
  (ref) => ArmedMode.none,
);
