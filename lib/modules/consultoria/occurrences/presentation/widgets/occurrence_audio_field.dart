import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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

  static String _formatClock(int totalSec) {
    final clamped = totalSec.clamp(0, OccurrenceAudioField.maxDurationSec);
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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

  void _onMicTap() {
    if (!widget.enabled || _stopping) return;
    if (_recording) {
      unawaited(_stopRecording(save: true));
    } else {
      unawaited(_startRecording());
    }
  }

  bool get _hasAudio => widget.storedPath?.trim().isNotEmpty == true;

  bool get _audioMissingLocally =>
      _hasAudio && _resolved && _resolvedPath == null;

  TextStyle _timerStyle(BuildContext context) {
    final color = _recording
        ? PremiumTokens.alertError
        : SoloForteSheetVisuals.of(context).onSheetPrimary;
    return TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );
  }

  /// Linha única de 48 pt (padrão lista do iOS): ícone + texto à esquerda,
  /// ações compactas à direita. Substitui o botão redondo de 72 pt.
  Widget _row({
    required Color accent,
    required Widget leading,
    required Widget title,
    List<Widget> trailing = const [],
    VoidCallback? onTap,
  }) {
    final v = SoloForteSheetVisuals.of(context);
    return Material(
      color: accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 4),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: v.onSheetPrimary),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Expanded(child: title),
                  ...trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = occurrenceFormIsIos(context);
    final accent = isIos ? v.iconStroke : context.themeAccent;
    final hasAudio = _hasAudio;
    final canPlay = _resolvedPath != null;
    final savedDuration = widget.durationSec;
    final timerStyle = _timerStyle(context);
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: v.onSheetPrimary,
    );

    Widget row;
    if (_recording) {
      row = _row(
        accent: PremiumTokens.alertError,
        onTap: _onMicTap,
        leading: const Icon(
          Icons.fiber_manual_record_rounded,
          size: 16,
          color: PremiumTokens.alertError,
        ),
        title: Text(_formatClock(_elapsedSec), style: timerStyle),
        trailing: [
          Tooltip(
            message: 'Parar',
            child: TextButton(
              onPressed: widget.enabled ? _onMicTap : null,
              child: const Text(
                'Parar',
                style: TextStyle(color: PremiumTokens.alertError),
              ),
            ),
          ),
        ],
      );
    } else if (!hasAudio) {
      row = Tooltip(
        message: 'Gravar',
        child: _row(
          accent: accent,
          onTap: _onMicTap,
          leading: Icon(Icons.mic_rounded, size: 22, color: accent),
          title: Text('Gravar áudio', style: labelStyle),
          trailing: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                'até ${OccurrenceAudioField.maxDurationSec} s',
                style: TextStyle(
                  fontSize: 13,
                  color: isIos
                      ? v.subtitleColor
                      : PremiumTokens.textSecondaryDark,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      row = _row(
        accent: accent,
        leading: Icon(Icons.graphic_eq_rounded, size: 22, color: accent),
        title: Text(
          savedDuration != null && savedDuration > 0
              ? _formatClock(savedDuration)
              : 'Áudio gravado',
          style: savedDuration != null && savedDuration > 0
              ? timerStyle
              : labelStyle,
        ),
        trailing: [
          if (!_audioMissingLocally)
            IconButton(
              tooltip: _playing ? 'Parar' : 'Ouvir',
              onPressed: widget.enabled && canPlay ? _togglePlayback : null,
              icon: Icon(
                _playing
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow_rounded,
                color: accent,
              ),
            ),
          IconButton(
            tooltip: 'Gravar de novo',
            onPressed: widget.enabled ? _startRecording : null,
            icon: Icon(Icons.mic_rounded, color: accent),
          ),
          IconButton(
            tooltip: 'Excluir áudio',
            onPressed: widget.enabled ? _removeAudio : null,
            icon: Icon(Icons.delete_outline, color: accent),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_audioMissingLocally)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                OccurrenceDetailAudioSection.missingLocalFileLabel,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isIos
                      ? v.subtitleColor
                      : PremiumTokens.textSecondaryDark,
                ),
              ),
            ),
          row,
        ],
      ),
    );
  }
}
