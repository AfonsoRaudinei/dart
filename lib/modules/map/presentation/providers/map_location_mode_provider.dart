import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados do botão de localização no mapa
enum MapLocationMode {
  /// Sem rastreamento — ícone seta normal (navigation_outlined)
  idle,

  /// Centralizando no usuário com norte para cima — ícone seta preenchida
  following,

  /// Seguindo + norte travado — ícone bússola (explore)
  northLocked,
}

/// Provider do estado atual do modo de localização no mapa
///
/// Ciclo de estados no tap:
/// - idle → following: centraliza no usuário com norte para cima (0°)
/// - following → northLocked: mantém centralizado + norte em 0°
/// - northLocked → idle: para de seguir
///
/// A câmera é sempre norte-acima em following/northLocked (sem course-up).
/// Quando o usuário move o mapa manualmente, o estado regride para idle.
final mapLocationModeProvider = StateProvider<MapLocationMode>(
  (ref) => MapLocationMode.idle,
);
