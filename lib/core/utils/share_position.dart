import 'package:flutter/material.dart';

/// Resolve um [Rect] não-zero para [Share.shareXFiles] no iPad.
///
/// Usa [anchorKey] quando disponível; caso contrário tenta o [context]
/// atual. Fallback: centro da tela (evita crash `sharePositionOrigin`).
Rect resolveSharePositionOrigin(
  BuildContext context, {
  GlobalKey? anchorKey,
}) {
  final anchorContext = anchorKey?.currentContext ?? context;
  final renderObject = anchorContext.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    final offset = renderObject.localToGlobal(Offset.zero);
    final rect = offset & renderObject.size;
    if (rect.width > 0 && rect.height > 0) {
      return rect;
    }
  }

  final size = MediaQuery.sizeOf(context);
  const width = 120.0;
  const height = 44.0;
  return Rect.fromLTWH(
    (size.width - width) / 2,
    (size.height - height) / 2,
    width,
    height,
  );
}
