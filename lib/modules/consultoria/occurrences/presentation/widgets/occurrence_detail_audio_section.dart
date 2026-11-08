import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:soloforte_app/core/utils/local_media_path_resolver.dart';

import '../../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/occurrence.dart';

typedef AudioPathResolver = Future<String?> Function(String storedPath);

typedef OccurrenceAudioDownloader =
    Future<bool> Function(Occurrence occurrence);

/// Reprodução read-only do áudio gravado no pin.
class OccurrenceDetailAudioSection extends StatefulWidget {
  static const missingLocalFileLabel = 'Áudio gravado em outro aparelho';

  final Occurrence occurrence;
  final Color cardBg;
  final double cardRadius;
  final bool isIos;
  final bool isDark;
  final AudioPathResolver resolvePath;
  final OccurrenceAudioDownloader? downloadMissing;

  const OccurrenceDetailAudioSection({
    super.key,
    required this.occurrence,
    required this.cardBg,
    required this.cardRadius,
    required this.isIos,
    required this.isDark,
    this.resolvePath = LocalMediaPathResolver.resolveLocalPath,
    this.downloadMissing,
  });

  @override
  State<OccurrenceDetailAudioSection> createState() =>
      _OccurrenceDetailAudioSectionState();
}

class _OccurrenceDetailAudioSectionState
    extends State<OccurrenceDetailAudioSection> {
  AudioPlayer? _player;
  bool _playing = false;
  Future<String?>? _resolvedFuture;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant OccurrenceDetailAudioSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.occurrence.audioPath != widget.occurrence.audioPath) {
      _resolve();
    }
  }

  void _resolve() {
    final path = widget.occurrence.audioPath?.trim();
    _resolvedFuture = path == null || path.isEmpty
        ? null
        : _resolvePlayable(path);
  }

  Future<String?> _resolvePlayable(String path) async {
    final first = await widget.resolvePath(path);
    if (first != null && first.isNotEmpty) return first;
    final download = widget.downloadMissing;
    if (download == null) return null;
    try {
      final ok = await download(widget.occurrence);
      if (!ok) return null;
    } catch (_) {
      return null;
    }
    final second = await widget.resolvePath(path);
    if (second == null || second.isEmpty) return null;
    return second;
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playing = false);
    });
    return _player = player;
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle(String resolved) async {
    final player = _ensurePlayer();
    if (_playing) {
      await player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await player.play(DeviceFileSource(resolved));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final secondaryColor = widget.isIos
        ? v.subtitleColor
        : PremiumTokens.textSecondaryDark;
    final future = _resolvedFuture;
    if (future == null) return const SizedBox.shrink();
    final sec = widget.occurrence.audioDurationSec;
    final subtitle = sec != null && sec > 0
        ? '${sec}s gravados no ponto'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(widget.cardRadius),
          border: widget.isIos
              ? Border.all(color: v.cardBorder)
              : null,
        ),
        child: FutureBuilder<String?>(
          future: future,
          builder: (context, snapshot) {
            final done = snapshot.connectionState == ConnectionState.done;
            final resolved = snapshot.data;
            final missing = done && resolved == null;
            return Row(
              children: [
                if (resolved != null)
                  IconButton(
                    onPressed: () => _toggle(resolved),
                    icon: Icon(
                      _playing
                          ? Icons.stop_circle_outlined
                          : Icons.play_arrow_rounded,
                      color: widget.isIos
                          ? v.iconStroke
                          : context.themeAccent,
                    ),
                  )
                else
                  const SizedBox(width: 8),
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
                              ? v.subtitleColor
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
                            color: secondaryColor,
                          ),
                        ),
                      if (missing)
                        Text(
                          OccurrenceDetailAudioSection.missingLocalFileLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
