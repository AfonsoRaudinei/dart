import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/utils/local_media_path_resolver.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../../relatorio_visita/data/occurrence_audio_storage.dart';
import 'occurrence_detail_audio_section.dart';
import 'occurrence_form_widgets.dart';

/// Gravação de áudio de campo (máx. 30 s) no pin da ocorrência.
class OccurrenceAudioField extends StatefulWidget {
  static const maxDurationSec = 30;

  final String? storedPath;
  final int? durationSec;
  final ValueChanged<({String? path, int? durationSec})> onChanged;
  final bool enabled;
  final AudioPathResolver resolvePath;

  const OccurrenceAudioField({
    super.key,
    this.storedPath,
    this.durationSec,
    required this.onChanged,
    this.enabled = true,
    this.resolvePath = LocalMediaPathResolver.resolveLocalPath,
  });

  @override
  State<OccurrenceAudioField> createState() => _OccurrenceAudioFieldState();
}

class _OccurrenceAudioFieldState extends State<OccurrenceAudioField>
    with WidgetsBindingObserver {
  AudioRecorder? _recorderInstance;
  AudioPlayer? _playerInstance;
  Timer? _tick;
  int _elapsedSec = 0;
  bool _recording = false;
  bool _stopping = false;
  bool _playing = false;
  String? _pendingTempPath;

  int _resolveGeneration = 0;
  bool _resolved = false;
  String? _resolvedPath;

  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();

  AudioPlayer get _player {
    final existing = _playerInstance;
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playing = false);
    });
    return _playerInstance = player;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveStoredPath();
  }

  @override
  void didUpdateWidget(covariant OccurrenceAudioField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedPath != widget.storedPath) {
      _resolveStoredPath();
    }
  }

  void _resolveStoredPath() {
    final generation = ++_resolveGeneration;
    final path = widget.storedPath?.trim();
    _resolved = false;
    _resolvedPath = null;
    if (path == null || path.isEmpty) return;
    widget
        .resolvePath(path)
        .then(
          (resolved) {
            if (!mounted || generation != _resolveGeneration) return;
            setState(() {
              _resolved = true;
              _resolvedPath = resolved;
            });
          },
          onError: (Object _) {
            if (!mounted || generation != _resolveGeneration) return;
            setState(() => _resolved = true);
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_recording) return;
    final backgrounded =
        state == AppLifecycleState.paused ||
        (state == AppLifecycleState.inactive &&
            defaultTargetPlatform == TargetPlatform.iOS);
    if (backgrounded) unawaited(_stopRecording(save: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _tick = null;
    final temp = _pendingTempPath;
    _pendingTempPath = null;
    final recorder = _recorderInstance;
    if (recorder != null) {
      final discard = _recording ? recorder.cancel() : Future<void>.value();
      _recording = false;
      unawaited(
        discard
            .catchError((Object _) {})
            .whenComplete(recorder.dispose)
            .whenComplete(() => _deleteFile(temp)),
      );
    } else {
      unawaited(_deleteFile(temp));
    }
    _playerInstance?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!widget.enabled || _recording || _stopping) return;
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

    await _playerInstance?.stop();
    if (!mounted) return;
    setState(() => _playing = false);

    final dir = await getTemporaryDirectory();
    if (!mounted) return;
    final path =
        '${dir.path}/occ_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _pendingTempPath = path;

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: path,
      );
    } catch (_) {
      await _deleteFile(path);
      _pendingTempPath = null;
      if (!mounted) return;
      setState(() {
        _recording = false;
        _elapsedSec = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gravar o áudio.')),
      );
      return;
    }
    if (!mounted) {
      await _recorder.stop();
      await _deleteFile(path);
      _pendingTempPath = null;
      return;
    }

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
        timer.cancel();
        setState(() => _elapsedSec = OccurrenceAudioField.maxDurationSec);
        await _stopRecording(save: true);
        return;
      }
      setState(() => _elapsedSec = next);
    });
  }

  Future<void> _stopRecording({required bool save}) async {
    _tick?.cancel();
    _tick = null;
    if (!_recording || _stopping) return;
    _stopping = true;
    try {
      await _finishRecording(save: save);
    } finally {
      _stopping = false;
    }
  }

  Future<void> _finishRecording({required bool save}) async {
    final path = await _recorder.stop();
    _recording = false;
    final source = path ?? _pendingTempPath;
    _pendingTempPath = null;
    if (!mounted) {
      await _deleteFile(source);
      return;
    }

    if (!save || source == null || source.isEmpty) {
      await _deleteFile(source);
      if (!mounted) return;
      setState(() => _elapsedSec = 0);
      return;
    }

    final stored = await OccurrenceAudioStorage.instance.persistLocalCopy(
      source,
    );
    await _deleteFile(source);
    if (!mounted) {
      await OccurrenceAudioStorage.instance.deleteAudio(stored);
      return;
    }
    if (stored == null) {
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
    final resolved = _resolvedPath;
    if (resolved == null || _recording) return;

    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }

    await _player.play(DeviceFileSource(resolved));
    if (mounted) setState(() => _playing = true);
  }

  Future<void> _removeAudio() async {
    HapticFeedback.selectionClick();
    await _playerInstance?.stop();
    await OccurrenceAudioStorage.instance.deleteAudio(widget.storedPath);
    widget.onChanged((path: null, durationSec: null));
    if (mounted) {
      setState(() {
        _playing = false;
        _elapsedSec = 0;
      });
    }
  }

  bool get _hasAudio => widget.storedPath?.trim().isNotEmpty == true;

  bool get _audioMissingLocally =>
      _hasAudio && _resolved && _resolvedPath == null;

  String get _statusLabel {
    if (_recording) {
      final left = OccurrenceAudioField.maxDurationSec - _elapsedSec;
      return 'Gravando… ${left}s restantes';
    }
    if (_audioMissingLocally) {
      return OccurrenceDetailAudioSection.missingLocalFileLabel;
    }
    final d = widget.durationSec;
    if (widget.storedPath != null && d != null && d > 0) {
      return 'Áudio gravado · ${d}s';
    }
    return '';
  }

  /// Rótulos de outline no sheet Azul (iOS): nunca usar [SoloForteSheetSkinIos.ctaText]
  /// — é branco para botão preenchido, ilegível em [v.cardBackground].
  Color _outlineButtonLabelColor({
    required BuildContext context,
    required bool isIos,
  }) {
    return isIos
        ? SoloForteSheetSkinIos.iconStroke
        : Colors.white;
  }

  Widget _buildStatusArea({
    required BuildContext context,
    required bool isIos,
    required bool hasAudio,
  }) {
    final primaryStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: isIos
          ? SoloForteSheetSkinIos.titleColor
          : PremiumTokens.textPrimaryLight,
    );
    final secondaryStyle = TextStyle(
      fontSize: 12,
      height: 1.35,
      color: isIos
          ? SoloForteSheetSkinIos.subtitleColor
          : PremiumTokens.textSecondaryDark,
    );

    final line = _statusLabel;
    if (line.isNotEmpty) {
      return Text(line, style: secondaryStyle);
    }
    if (!hasAudio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30 segundos para relato após tocar no ícone do microfone.',
            style: primaryStyle,
          ),
          const SizedBox(height: 4),
          Text(
            'Até ${OccurrenceAudioField.maxDurationSec}s — mais rápido que digitar no talhão.',
            style: secondaryStyle,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isIos = occurrenceFormIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : context.themeAccent;
    final outlineLabelColor = _outlineButtonLabelColor(
      context: context,
      isIos: isIos,
    );
    final hasAudio = _hasAudio;
    final canPlay = _resolvedPath != null;

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
          const OccurrenceSectionHeader(icon: '🎙️', title: 'Áudio no ponto'),
          const SizedBox(height: 8),
          _buildStatusArea(
            context: context,
            isIos: isIos,
            hasAudio: hasAudio,
          ),
          const SizedBox(height: 14),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: accent.withValues(alpha: isIos ? 0.14 : 0.18),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: widget.enabled ? _startRecording : null,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: Icon(
                              Icons.mic_rounded,
                              size: 36,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gravar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: outlineLabelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (!_audioMissingLocally)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.enabled && canPlay
                          ? _togglePlayback
                          : null,
                      icon: Icon(
                        _playing
                            ? Icons.stop_circle_outlined
                            : Icons.play_arrow_rounded,
                        color: accent,
                      ),
                      label: Text(
                        _playing ? 'Parar' : 'Ouvir',
                        style: TextStyle(
                          color: outlineLabelColor,
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
                else
                  const Spacer(),
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
