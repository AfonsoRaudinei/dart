import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/utils/local_media_path_resolver.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../../relatorio_visita/data/occurrence_audio_storage.dart';
import 'occurrence_form_widgets.dart';

/// Gravação de áudio de campo (máx. 30 s) no pin da ocorrência.
class OccurrenceAudioField extends StatefulWidget {
  static const maxDurationSec = 30;

  final String? storedPath;
  final int? durationSec;
  final ValueChanged<({String? path, int? durationSec})> onChanged;
  final bool enabled;

  const OccurrenceAudioField({
    super.key,
    this.storedPath,
    this.durationSec,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<OccurrenceAudioField> createState() => _OccurrenceAudioFieldState();
}

class _OccurrenceAudioFieldState extends State<OccurrenceAudioField> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  Timer? _tick;
  int _elapsedSec = 0;
  bool _recording = false;
  bool _playing = false;
  String? _pendingTempPath;

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
    _tick?.cancel();
    if (_recording) {
      _recorder.stop();
    }
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!widget.enabled || _recording) return;
    final ok = await _recorder.hasPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permita o microfone para gravar áudio no ponto.'),
        ),
      );
      return;
    }

    await _player.stop();
    if (mounted) setState(() => _playing = false);

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/occ_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _pendingTempPath = path;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _recording = true;
      _elapsedSec = 0;
    });

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      final next = _elapsedSec + 1;
      if (next >= OccurrenceAudioField.maxDurationSec) {
        await _stopRecording(save: true);
        return;
      }
      setState(() => _elapsedSec = next);
    });
  }

  Future<void> _stopRecording({required bool save}) async {
    _tick?.cancel();
    _tick = null;
    if (!_recording) return;

    final path = await _recorder.stop();
    _recording = false;
    if (!mounted) return;

    final source = path ?? _pendingTempPath;
    _pendingTempPath = null;

    if (!save || source == null || source.isEmpty) {
      await _deleteFile(source);
      setState(() => _elapsedSec = 0);
      return;
    }

    final stored = await OccurrenceAudioStorage.instance.persistLocalCopy(source);
    await _deleteFile(source);
    if (stored == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o áudio.')),
      );
      setState(() => _elapsedSec = 0);
      return;
    }

    final duration = _elapsedSec.clamp(1, OccurrenceAudioField.maxDurationSec);
    if (widget.storedPath != null && widget.storedPath != stored) {
      await OccurrenceAudioStorage.instance.deleteAudio(widget.storedPath);
    }
    widget.onChanged((path: stored, durationSec: duration));
    if (mounted) setState(() => _elapsedSec = 0);
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _togglePlayback() async {
    final path = widget.storedPath;
    if (path == null || path.isEmpty || _recording) return;

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

  Future<void> _removeAudio() async {
    HapticFeedback.selectionClick();
    await _player.stop();
    await OccurrenceAudioStorage.instance.deleteAudio(widget.storedPath);
    widget.onChanged((path: null, durationSec: null));
    if (mounted) {
      setState(() {
        _playing = false;
        _elapsedSec = 0;
      });
    }
  }

  String get _statusLabel {
    if (_recording) {
      final left = OccurrenceAudioField.maxDurationSec - _elapsedSec;
      return 'Gravando… ${left}s restantes';
    }
    final d = widget.durationSec;
    if (widget.storedPath != null && d != null && d > 0) {
      return 'Áudio gravado · ${d}s';
    }
    return 'Até ${OccurrenceAudioField.maxDurationSec}s — mais rápido que digitar no talhão.';
  }

  @override
  Widget build(BuildContext context) {
    final isIos = occurrenceFormIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : context.themeAccent;
    final hasAudio = widget.storedPath?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          isIos ? SoloForteSheetSkinIos.cardRadius : 14,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OccurrenceSectionHeader(
            icon: '🎙️',
            title: 'Áudio no ponto',
          ),
          const SizedBox(height: 6),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isIos
                  ? SoloForteSheetSkinIos.subtitleColor
                  : PremiumTokens.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_recording)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.enabled
                        ? () => _stopRecording(save: true)
                        : null,
                    icon: const Icon(Icons.stop_rounded, size: 20),
                    label: const Text('Parar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PremiumTokens.alertError,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 44),
                    ),
                  ),
                )
              else if (!hasAudio)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.enabled ? _startRecording : null,
                    icon: Icon(Icons.mic_rounded, color: accent),
                    label: Text(
                      'Gravar',
                      style: TextStyle(
                        color: isIos
                            ? SoloForteSheetSkinIos.ctaText
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withValues(alpha: 0.8)),
                      minimumSize: const Size(48, 44),
                      backgroundColor: v.cardBackground,
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.enabled ? _togglePlayback : null,
                    icon: Icon(
                      _playing ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                      color: accent,
                    ),
                    label: Text(
                      _playing ? 'Parar' : 'Ouvir',
                      style: TextStyle(
                        color: isIos
                            ? SoloForteSheetSkinIos.ctaText
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withValues(alpha: 0.8)),
                      minimumSize: const Size(48, 44),
                      backgroundColor: v.cardBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Excluir áudio',
                  onPressed: widget.enabled ? _removeAudio : null,
                  icon: Icon(Icons.delete_outline, color: accent),
                ),
                IconButton(
                  tooltip: 'Gravar de novo',
                  onPressed: widget.enabled ? _startRecording : null,
                  icon: Icon(Icons.mic_rounded, color: accent),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
