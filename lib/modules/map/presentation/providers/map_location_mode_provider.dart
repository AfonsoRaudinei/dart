import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados do botão de localização no mapa
enum MapLocationMode {
  /// Sem rastreamento — ícone seta normal (navigation_outlined)
  idle,

  /// Centralizando no usuário — ícone seta azul preenchida (navigation)
  following,

  /// Seguindo + norte travado — ícone bússola (explore)
  northLocked,
}

/// Provider do estado atual do modo de localização no mapa
///
/// Ciclo de estados no tap:
/// - idle → following: centraliza o mapa na posição do usuário
/// - following → northLocked: mantém centralizado + trava norte em 0°
/// - northLocked → idle: para de seguir
///
/// Quando o usuário move o mapa manualmente, o estado regride para idle
final mapLocationModeProvider = StateProvider<MapLocationMode>(
  (ref) => MapLocationMode.idle,
);
