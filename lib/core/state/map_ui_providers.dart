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
