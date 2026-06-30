import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../modules/drawing/presentation/coordinators/drawing_close_coordinator.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../ui/components/map/map_sheet_state.dart';
import '../widgets/map_sheet_content_builder.dart';

/// Controla abertura de modais e toggle do modo de desenho no mapa.
///
/// Extraído de `_PrivateMapSheets._openSheetAsModal` + `_toggleDrawMode` — ADR-031 F4.
///
/// [openSheet] — abre qualquer [MapSheetState] como sheet modal com
///   [DraggableScrollableSheet]. Preserva lógica de [modalGenerationProvider]
///   para invalidar callbacks [whenComplete] de modais anteriores.
///   ⚠️ NÃO simplificar a lógica de geração — previne race condition real.
///
/// [toggleDrawMode] — toggle de [MapSheetType.draw] no [mapSheetStateProvider].
class MapSheetController {
  /// Abre [state] como modal nativo (DraggableScrollableSheet).
  ///
  /// Guard: retorna imediatamente se [isModalOpenProvider] == true.
  /// Preserva [modalGenerationProvider] para invalidar whenComplete stale.
  static void openSheet(
    BuildContext context,
    WidgetRef ref,
    MapSheetState state,
    VoidCallback onArmOccurrenceMode,
    void Function(MapSheetState? s, String reason) setSheetState,
    void Function(bool v) setModalOpen,
  ) {
    if (ref.read(isModalOpenProvider)) return;
    if (!context.mounted) return;
    setModalOpen(true);
    // Captura geração APÓS incremento — invalida whenComplete de modais antigos.
    // ⚠️ NÃO simplificar — a lógica de geração previne race condition real.
    final gen = ++ref.read(modalGenerationProvider.notifier).state;

    // Bug 1: checkIn precisa de mais altura inicial e máxima para exibir
    // 4 dropdowns + botão sem corte. Outros tipos mantêm valores anteriores.
    final isCheckIn = state.type == MapSheetType.checkIn;
    final isLayers = state.type == MapSheetType.layers;
    final initialSize = isCheckIn ? 0.6 : 0.5;
    final maxSize = isCheckIn ? 0.92 : 0.9;
    final snapSizesList = isCheckIn ? [0.6, 0.92] : [0.5, 0.9];

    showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: 0.3,
        maxChildSize: maxSize,
        expand: false,
        snap: true,
        snapSizes: snapSizesList,
        builder: (_, scrollController) {
          final content = buildSheetContent(
            context,
            ref,
            state,
            scrollController,
            onArmOccurrenceMode,
          );

          if (isCheckIn) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: ColoredBox(
                color: SoloForteSheetTokens.sheetBackground,
                child: content,
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: isLayers
                  ? SoloForteSheetTokens.sheetBackground
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (!context.mounted) return;
      // R-3: Sempre limpar isModalOpenProvider ao fechar (cobre swipe dismiss).
      // Se outra geração foi aberta entre meio-tempo, apenas limpa o flag sem
      // alterar o sheetState — evita fechar sheet que não foi aberto por este modal.
      if (ref.read(modalGenerationProvider) != gen) {
        // Outro modal foi aberto: só garantir que flag não ficou preso.
        // NÃO chamar setSheetState — seria o modal errado fechando o estado.
        setModalOpen(false);
        return;
      }
      setModalOpen(false);
      final currentState = ref.read(mapSheetStateProvider);
      if (currentState?.type == state.type) {
        setSheetState(null, 'Modal: whenComplete dismiss');
      }
    });
  }

  /// Toggle de [MapSheetType.draw] no [mapSheetStateProvider].
  ///
  /// Reuso intencional de [mapSheetStateProvider] como estado de abertura do
  /// DrawingSheet — não há drawingSheetOpenProvider separado.
  static Future<void> toggleDrawMode(
    BuildContext context,
    WidgetRef ref,
    void Function(MapSheetState? s, String reason) setSheetState,
  ) async {
    HapticFeedback.mediumImpact();
    final controller = ref.read(drawingControllerProvider);
    final currentSheet = ref.read(mapSheetStateProvider);

    // Toggle explícito: se draw já está aberto, fecha.
    if (currentSheet?.type == MapSheetType.draw) {
      final wasDrawing = controller.currentState != DrawingState.idle;
      final decision = await DrawingCloseCoordinator.handle(
        context,
        controller: controller,
        intent: DrawingCloseIntent.dismissSheet,
      );
      if (!decision.shouldCloseSheet) {
        return;
      }
      setSheetState(null, 'ToggleDrawMode: Closing draw sheet');

      if (wasDrawing) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desenho cancelado'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Abrir draw quando estiver fechado.
    setSheetState(
      const MapSheetState(type: MapSheetType.draw),
      'ToggleDrawMode: Opening draw sheet',
    );
  }
}
