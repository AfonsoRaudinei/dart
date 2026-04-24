// ignore_for_file: use_build_context_synchronously
part of 'private_map_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// Extensão de _PrivateMapScreenState: Lógica de sheets e modais
// ════════════════════════════════════════════════════════════════════════════
// Extraído para manter private_map_screen.dart abaixo de 900 linhas.
// (Sprint 7 — Bounded Context Hygiene)
//
// Contém:

//   · _handleMapLongPress           — modal NovoCaseSheet + DraftSavedSheet
//   · _openSheetAsModal             — wrapper DraggableScrollableSheet
//   · _buildSheetContent            — switch de conteúdo por MapSheetType
//   · _buildActiveVisitContent      — UI de visita ativa no checkIn sheet
//   · _toggleDrawMode               — alternar modo desenho

extension _PrivateMapSheets on _PrivateMapScreenState {

  // ── _handleMapLongPress ───────────────────────────────────────────────────

  // 🔧 MODAL: delegate para NovoCaseModalLauncher.launch — ADR-031 F5
  void _handleMapLongPress(TapPosition tapPos, LatLng latLng) {
    NovoCaseModalLauncher.launch(
      position: latLng,
      context: context,
      ref: ref,
    );
  }

  // ── _openSheetAsModal ─────────────────────────────────────────────────────

  // 🔧 MODAL: delegate para MapSheetController.openSheet — ADR-031 F4
  void _openSheetAsModal(BuildContext context, MapSheetState state) {
    MapSheetController.openSheet(
      context,
      ref,
      state,
      _armOccurrenceMode,
      _setSheetState,
      _setModalOpen,
    );
  }

  // ── _finishDrawing ────────────────────────────────────────────────────────

  // 🔧 Helper to finish drawing
  Future<void> _finishDrawing() async {
    final controller = ref.read(drawingControllerProvider);

    // 🔒 GUARD: Evitar re-entrância ou chamadas duplicadas (Fix Duplication)
    // Só processar se estiver no estado de desenho
    if (controller.currentState != DrawingState.drawing) {
      return;
    }

    // Verificar se há pontos suficientes
    if (controller.liveGeometry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 3 pontos para criar um polígono'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔧 CHANGE STATE: Mudar para modo de revisão
    controller.completeDrawing();

    // 🔒 VALIDATION: Garantir que a transição ocorreu com sucesso
    if (controller.currentState != DrawingState.reviewing) {
      return;
    }
  }

  // ── _toggleDrawMode ───────────────────────────────────────────────────────

  // 🔧 delegate para MapSheetController.toggleDrawMode — ADR-031 F4
  void _toggleDrawMode() {
    MapSheetController.toggleDrawMode(context, ref, _setSheetState);
  }
}
