import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/utils/local_media_path_resolver.dart';

import '../../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/occurrence.dart';

/// Reprodução read-only do áudio gravado no pin.
class OccurrenceDetailAudioSection extends StatefulWidget {
  final Occurrence occurrence;
  final Color cardBg;
  final double cardRadius;
  final bool isIos;
  final bool isDark;

  const OccurrenceDetailAudioSection({
    super.key,
    required this.occurrence,
    required this.cardBg,
    required this.cardRadius,
    required this.isIos,
    required this.isDark,
  });

  @override
  State<OccurrenceDetailAudioSection> createState() =>
      _OccurrenceDetailAudioSectionState();
}

class _OccurrenceDetailAudioSectionState
    extends State<OccurrenceDetailAudioSection> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final path = widget.occurrence.audioPath;
    if (path == null || path.isEmpty) return;
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final resolved = await LocalMediaPathResolver.resolveLocalPath(path);
    if (resolved == null) return;
    await _player.play(DeviceFileSource(resolved));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.occurrence.audioPath;
    if (path == null || path.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final sec = widget.occurrence.audioDurationSec;
    final subtitle = sec != null && sec > 0 ? '${sec}s gravados no ponto' : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(widget.cardRadius),
          border: widget.isIos
              ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
              : null,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _toggle,
              icon: Icon(
                _playing ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                color: widget.isIos
                    ? SoloForteSheetSkinIos.iconStroke
                    : context.themeAccent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Áudio no ponto',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isIos
                          ? SoloForteSheetSkinIos.subtitleColor
                          : (widget.isDark
                              ? PremiumTokens.textSecondaryDark
                              : context.premiumTextSecondary),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isIos
                            ? SoloForteSheetSkinIos.subtitleColor
                            : PremiumTokens.textSecondaryDark,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
