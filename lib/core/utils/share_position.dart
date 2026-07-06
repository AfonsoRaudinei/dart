import 'package:flutter/material.dart';

/// Retorna um retângulo válido para `Share.shareXFiles` (obrigatório no iPad).
Rect sharePositionOriginFor(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    final origin = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    if (size.width > 0 && size.height > 0) {
      return origin & size;
    }
  }

  final media = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(media.width * 0.5, media.height * 0.5),
    width: 1,
    height: 1,
  );
}
