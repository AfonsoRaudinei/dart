import 'package:flutter/material.dart';

import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_state.dart';
import '../controllers/drawing_controller.dart';

enum DrawingCloseIntent {
  dismissSheet,
  /// Fecha o sheet preservando ferramenta armed (ex.: após selecionar Polígono/Livre/Pivô).
  dismissSheetPreserveArmed,
  switchPanel,
  saveEditAndClose,
  cancelEditAndStaySelected,
  cancelFlowAndClose,
  completeSaveAndClose,
}

class DrawingCloseDecision {
  const DrawingCloseDecision({required this.shouldCloseSheet});

  final bool shouldCloseSheet;
}

class DrawingCloseCoordinator {
  const DrawingCloseCoordinator._();

  static Future<DrawingCloseDecision> handle(
    BuildContext context, {
    required DrawingController controller,
    required DrawingCloseIntent intent,
  }) async {
    switch (intent) {
      case DrawingCloseIntent.saveEditAndClose:
        final saved = controller.saveEdit();
        if (!saved) {
          return const DrawingCloseDecision(shouldCloseSheet: false);
        }
        controller.exitDrawingContext();
        return const DrawingCloseDecision(shouldCloseSheet: true);

      case DrawingCloseIntent.cancelEditAndStaySelected:
        controller.cancelEdit();
        return const DrawingCloseDecision(shouldCloseSheet: false);

      case DrawingCloseIntent.cancelFlowAndClose:
        controller.cancelOperation();
        return const DrawingCloseDecision(shouldCloseSheet: true);

      case DrawingCloseIntent.completeSaveAndClose:
        controller.exitDrawingContext();
        return const DrawingCloseDecision(shouldCloseSheet: true);

      case DrawingCloseIntent.dismissSheetPreserveArmed:
        if (controller.currentState == DrawingState.armed &&
            controller.currentTool != DrawingTool.none) {
          return const DrawingCloseDecision(shouldCloseSheet: true);
        }
        return _handleDismissOrSwitchPanel(
          context,
          controller,
          intent: DrawingCloseIntent.dismissSheet,
        );

      case DrawingCloseIntent.dismissSheet:
      case DrawingCloseIntent.switchPanel:
        return _handleDismissOrSwitchPanel(
          context,
          controller,
          intent: intent,
        );
    }
  }

  static Future<DrawingCloseDecision> _handleDismissOrSwitchPanel(
    BuildContext context,
    DrawingController controller, {
    required DrawingCloseIntent intent,
  }) async {
    // 1A / REGRA-EDIT: dismiss não cancela edição de vértices.
    // Sair da edição: Cancelar / Salvar, ou switchPanel com confirmação.
    if (controller.currentState == DrawingState.editing ||
        controller.interactionMode == DrawingInteraction.editing) {
      if (intent == DrawingCloseIntent.switchPanel) {
        if (controller.hasPendingEditChanges) {
          final shouldDiscard = await _confirmDiscardEditingChanges(context);
          if (!shouldDiscard) {
            return const DrawingCloseDecision(shouldCloseSheet: false);
          }
        }
        controller.cancelEdit();
        return const DrawingCloseDecision(shouldCloseSheet: true);
      }
      // dismissSheet: host deve recolher (compact) sem cancelar.
      return const DrawingCloseDecision(shouldCloseSheet: false);
    }

    if (controller.hasSelection) {
      controller.exitDrawingContext();
      return const DrawingCloseDecision(shouldCloseSheet: true);
    }

    if (controller.currentState != DrawingState.idle ||
        controller.currentTool != DrawingTool.none) {
      controller.cancelOperation();
      return const DrawingCloseDecision(shouldCloseSheet: true);
    }

    return const DrawingCloseDecision(shouldCloseSheet: true);
  }

  static Future<bool> _confirmDiscardEditingChanges(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Existem alterações de geometria não salvas. Deseja descartar e sair da edição?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
