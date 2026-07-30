import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/share_position.dart';

/// Botão circular âmbar que compartilha o HTML injetado da story.
class StoryShareButton extends StatefulWidget {
  final String htmlContent;
  final String caseId;

  const StoryShareButton({
    required this.htmlContent,
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

    final html = widget.htmlContent;
    if (html.isEmpty) {
      AppLogger.warning(
        'StoryShareButton: htmlContent vazio — share abortado',
        tag: 'MarketingStory',
      );
      return;
    }

    setState(() => _sharing = true);
    try {
      final dir = await getTemporaryDirectory();
      final safeId = widget.caseId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/soloforte_case_$safeId.html');
      await file.writeAsString(html, encoding: utf8);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: 'Resultado de Campo — SoloForte',
        sharePositionOrigin: resolveSharePositionOrigin(context),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível preparar o arquivo para compartilhar',
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
