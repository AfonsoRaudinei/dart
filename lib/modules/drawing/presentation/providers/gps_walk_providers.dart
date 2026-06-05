import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gps_walk_session.dart';
import '../controllers/gps_walk_controller.dart';

/// Provider autoDispose para a sessão GPS Walk.
///
/// O MapBuildOrchestrator também escuta este provider, então a sessão sobrevive
/// ao fechamento do DrawingSheet e é descartada ao sair da tela do mapa.
///
/// O ciclo de vida é encerrado explicitamente por `cancel()` ou `finish()`.
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
