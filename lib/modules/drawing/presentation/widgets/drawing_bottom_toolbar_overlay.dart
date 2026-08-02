import 'package:flutter/material.dart';

import '../../../../core/constants/layout_constants.dart';
import 'drawing_bottom_toolbar.dart';

/// Posiciona [DrawingBottomToolbar] acima do SmartButton durante o desenho.
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
      right: 16,
      bottom: kFabSafeArea + safeBottom,
      child: DrawingBottomToolbar(
        onConfirm: onConfirm,
        onUndo: onUndo,
        onCancel: onCancel,
        canUndo: canUndo,
        canConfirm: canConfirm,
      ),
    );
  }
}
