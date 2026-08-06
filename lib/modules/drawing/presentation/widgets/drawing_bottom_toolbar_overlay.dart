import 'package:flutter/material.dart';

import '../../../../core/constants/layout_constants.dart';
import 'drawing_bottom_toolbar.dart';

/// Posiciona [DrawingBottomToolbar] na base da tela durante o desenho.
///
/// A barra ocupa `bottom: 0` com safe area interna e recuo direito para
/// não conflitar com o SmartButton nem com a coluna flutuante do mapa.
class DrawingBottomToolbarOverlay extends StatelessWidget {
  const DrawingBottomToolbarOverlay({
    super.key,
    required this.onConfirm,
    required this.onUndo,
    required this.onCancel,
    required this.canUndo,
    this.canConfirm = true,
  });

  final VoidCallback onConfirm;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final bool canUndo;
  final bool canConfirm;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 16,
      right: kDrawingBottomToolbarRightInset,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: kDrawingBottomToolbarHeight),
          child: DrawingBottomToolbar(
            onConfirm: onConfirm,
            onUndo: onUndo,
            onCancel: onCancel,
            canUndo: canUndo,
            canConfirm: canConfirm,
          ),
        ),
      ),
    );
  }
}
