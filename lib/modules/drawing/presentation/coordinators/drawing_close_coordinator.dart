import 'package:flutter/material.dart';

import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_state.dart';
import '../controllers/drawing_controller.dart';

enum DrawingCloseIntent {
  dismissSheet,
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

      case DrawingCloseIntent.dismissSheet:
      case DrawingCloseIntent.switchPanel:
        if (controller.interactionMode == DrawingInteraction.editing) {
          if (controller.hasPendingEditChanges) {
            final shouldDiscard = await _confirmDiscardEditingChanges(context);
            if (!shouldDiscard) {
              return const DrawingCloseDecision(shouldCloseSheet: false);
            }
          }
          controller.exitDrawingContext();
          return const DrawingCloseDecision(shouldCloseSheet: true);
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
