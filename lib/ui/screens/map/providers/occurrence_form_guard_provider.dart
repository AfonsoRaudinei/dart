import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../modules/consultoria/occurrences/presentation/coordinators/occurrence_form_guard.dart';

/// Guard efêmero do formulário de criação no mapa — consultado antes de fechar.
final occurrenceFormGuardProvider =
    StateProvider.autoDispose<OccurrenceFormGuard?>((ref) => null);
