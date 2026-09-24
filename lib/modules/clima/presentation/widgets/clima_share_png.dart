import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:soloforte_app/core/utils/share_position.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_card.dart';

Future<Uint8List?> _capturePng(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

/// Renderiza [ClimaShareCard] off-screen, captura PNG e abre o share sheet.
/// Retorna `false` se a captura ou o share falhar.
Future<bool> shareClimaCardAsPng(
  BuildContext context,
  ClimaSharePayload payload,
) async {
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -ClimaShareCard.cardWidth - 40,
      top: 0,
      child: Material(
        color: Colors.transparent,
        child: RepaintBoundary(
          key: boundaryKey,
          child: ClimaShareCard(payload: payload),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 48));
    final bytes = await _capturePng(boundaryKey);
    if (bytes == null || !context.mounted) return false;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/soloforte_clima_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    if (!context.mounted) return false;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: 'Previsão do tempo — ${payload.cidade}',
      sharePositionOrigin: resolveSharePositionOrigin(context),
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    entry.remove();
  }
}
