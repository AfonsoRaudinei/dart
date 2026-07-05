import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

/// Bloqueia o viewport GPS inicial quando a rota pede foco em um drawing
/// (`/map?drawingId=...`). Evita race onde GPS sobrescreve fitCamera do talhão.
final prioritizeDrawingFocusProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// ── ADR-031 F1: migrados de setState em private_map_screen.dart ──────────────

/// Guard de modal aberto — impede abertura simultânea de dois modais.
/// TODO(ADR-031-F1): migrado de _isModalOpen (setState) em private_map_screen.dart
final isModalOpenProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Contador de geração de modal — invalida callbacks whenComplete de modais
/// anteriores quando um novo modal sobrepõe o antigo.
/// ⚠️ NÃO simplificar — previne race condition real em troca rápida de tabs.
/// TODO(ADR-031-F1): migrado de _modalGeneration (setState) em private_map_screen.dart
final modalGenerationProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Localização pendente para criação de ocorrência.
/// != null → abre OccurrenceCreationSheet; null → OccurrenceListSheet.
/// TODO(ADR-031-F1): migrado de _pendingOccurrenceLocation (setState) em private_map_screen.dart
final pendingOccurrenceLocationProvider = StateProvider.autoDispose<LatLng?>(
  (ref) => null,
);

/// Marcador efêmero de destino para navegação por coordenadas.
/// Null = sem marcador ativo.
final destinationCoordinateMarkerProvider = StateProvider.autoDispose<LatLng?>(
  (ref) => null,
);

class MapCameraSnapshot {
  final LatLng center;
  final double zoom;
  final LatLngBounds visibleBounds;

  const MapCameraSnapshot({
    required this.center,
    required this.zoom,
    required this.visibleBounds,
  });
}

/// Camera atual para indicadores reativos que dependem de pan/zoom.
final mapCameraSnapshotProvider = StateProvider.autoDispose<MapCameraSnapshot?>(
  (ref) => null,
);
