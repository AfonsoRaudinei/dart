import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/share_position.dart';
import '../../../../core/utils/user_facing_error.dart';

/// Botão circular âmbar que captura o [repaintKey] e abre o Share Sheet.
class StoryShareButton extends StatefulWidget {
  final GlobalKey repaintKey;
  final String caseId;

  const StoryShareButton({
    required this.repaintKey,
    required this.caseId,
    super.key,
  });

  @override
  State<StoryShareButton> createState() => _StoryShareButtonState();
}

class _StoryShareButtonState extends State<StoryShareButton> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = widget.repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Story ainda não está pronta para compartilhar.');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('Falha ao gerar imagem da story.');
      }

      final dir = await getTemporaryDirectory();
      final safeId = widget.caseId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/soloforte_story_$safeId.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Resultado de Campo — SoloForte',
        sharePositionOrigin: resolveSharePositionOrigin(context),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, action: 'Erro ao compartilhar story'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5B935),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _sharing ? null : _share,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: _sharing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF1D1D1F),
                    ),
                  )
                : const Icon(
                    Icons.ios_share_rounded,
                    color: Color(0xFF1D1D1F),
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
