import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/components/map/map_sheet_state.dart';

/// Estados da máquina de inicialização do viewport do mapa.
/// Controla se o posicionamento inicial da câmera já foi aplicado.
enum InitialViewportState {
  /// Aguardando início
  idle,

  /// Aguardando mapa estar pronto
  waitingForMap,

  /// Aguardando dados (campos ou GPS)
  waitingForData,

  /// Viewport aplicado com sucesso
  applied,

  /// Abortado (fallback ou erro)
  aborted,
}

/// Provider do estado do sheet inferior do mapa.
///
/// null = sheet fechado.
/// autoDispose garante reset ao sair da tela, evitando estado residual.
/// Controla também a abertura/fechamento do DrawingSheet
/// (toggle do ícone de desenho no mapa).
/// Documentado em: PROMPT_04 / verificação pós-execução.
/// Reuso intencional no lugar de um drawingSheetOpenProvider dedicado.
final mapSheetStateProvider = StateProvider.autoDispose<MapSheetState?>(
  (ref) => null,
);

/// Provider do estado da máquina de inicialização do viewport do mapa.
///
/// autoDispose garante reset ao sair da tela, voltando para [InitialViewportState.idle].
final viewportStateProvider = StateProvider.autoDispose<InitialViewportState>(
  (ref) => InitialViewportState.idle,
);

/// Toggle do overlay de radar de precipitação (RainViewer — ADR-028).
///
/// false = radar oculto (padrão).
/// true  = radar visível sobre o mapa base.
/// autoDispose garante reset ao sair da tela.
// TODO(DT-028): showRadarProvider (StateProvider<bool>) é proxy temporário.
// Condição de remoção: quando MapContext.clima for implementado no enum MapContext
// (pendente decomposição de private_map_screen.dart — ~955 linhas).
// Ver: docs/DT-028-SHOW-RADAR-PROVIDER.md
final showRadarProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
