import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gps_walk_session.dart';
import '../controllers/gps_walk_controller.dart';

/// Provider autoDispose para a sessão GPS Walk.
///
/// AutoDispose garante que o estado da sessão é descartado ao sair do
/// modo de medição, sem vazar memória.
///
/// Padrão: [NotifierProvider.autoDispose] — consistente com o módulo drawing.
///
/// Uso:
/// ```dart
/// // Ler estado:
/// final session = ref.watch(gpsWalkProvider);
///
/// // Acionar operações:
/// ref.read(gpsWalkProvider.notifier).activate();
/// ref.read(gpsWalkProvider.notifier).startMeasuring();
/// ```
final gpsWalkProvider =
    NotifierProvider.autoDispose<GpsWalkNotifier, GpsWalkSession?>(
  GpsWalkNotifier.new,
);
