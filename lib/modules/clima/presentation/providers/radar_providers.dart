import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/map_config.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/infra/preferences_service.dart';
import '../../data/datasources/rainviewer_radar_datasource.dart';
import '../../domain/entities/radar_fetch_result.dart';
import '../../domain/entities/radar_rain_frame.dart';
import '../../domain/radar_frame_index_utils.dart';

export '../../data/datasources/rainviewer_radar_datasource.dart'
    show ClimaRadarFetch, parseClimaRadarFrames;
export '../../domain/entities/radar_fetch_result.dart';
export '../../domain/radar_frame_age_label.dart';
export '../../domain/entities/radar_rain_frame.dart';
export '../../domain/radar_frame_index_utils.dart';
export '../../domain/radar_overlay_state.dart';

/// Chave de persistência do toggle de radar (SharedPreferences).
const climaRadarEnabledPreferenceKey = 'clima_radar_enabled_v1';

final climaRadarFetchProvider = Provider<ClimaRadarFetch>((ref) {
  return (uri) => http.get(uri).timeout(const Duration(seconds: 8));
});

final climaRadarDatasourceProvider = Provider<RainviewerRadarDatasource>((ref) {
  return RainviewerRadarDatasource(fetch: ref.watch(climaRadarFetchProvider));
});

/// Liga/desliga o overlay de radar de chuva no mapa (persistido offline).
final climaRadarEnabledProvider = NotifierProvider<ClimaRadarEnabled, bool>(
  ClimaRadarEnabled.new,
);

class ClimaRadarEnabled extends Notifier<bool> {
  @override
  bool build() {
    SessionController.registerLogoutInvalidation(
      key: 'climaRadarEnabledProvider',
      invalidate: (ref) => ref.invalidate(climaRadarEnabledProvider),
    );
    return ref
            .read(preferencesServiceProvider)
            .getBool(climaRadarEnabledPreferenceKey) ??
        false;
  }

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    ref
        .read(preferencesServiceProvider)
        .setBool(climaRadarEnabledPreferenceKey, enabled);
  }
}

/// Índice do frame atual da animação do radar.
final climaRadarFrameIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Estado de reprodução do radar (reproduzindo ou pausado).
final climaRadarPlayingProvider = StateProvider.autoDispose<bool>((ref) => true);

/// Esquema de cores selecionado (2 = Universal Blue, 6 = NEXRAD Level III, etc.).
final climaRadarColorSchemeProvider =
    StateProvider.autoDispose<int>((ref) => MapConfig.rainViewerDefaultColorScheme);

/// Exibição da máscara de cobertura dos radares terrestres.
final climaRadarCoverageEnabledProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Manifesto RainViewer parseado com status explícito para UX e telemetria.
final climaRadarFramesProvider =
    FutureProvider.autoDispose<ClimaRadarFetchResult>((ref) async {
      final colorScheme = ref.watch(climaRadarColorSchemeProvider);
      return ref
          .watch(climaRadarDatasourceProvider)
          .fetchPastFrames(colorScheme: colorScheme);
    });

/// Frame ativo correspondente ao índice atual.
final climaRadarActiveFrameProvider =
    Provider.autoDispose<ClimaRadarFrame?>((ref) {
      final framesAsync = ref.watch(climaRadarFramesProvider);
      final frames = framesAsync.asData?.value.frames ?? const [];
      if (frames.isEmpty) return null;
      final rawIndex = ref.watch(climaRadarFrameIndexProvider);
      final index = rawIndex.clamp(0, frames.length - 1);
      return frames[index];
    });

/// Controlador de playback e navegação temporal do radar RainViewer.
class ClimaRadarPlaybackController {
  final Ref _ref;

  const ClimaRadarPlaybackController(this._ref);

  void play() {
    _ref.read(climaRadarPlayingProvider.notifier).state = true;
  }

  void pause() {
    _ref.read(climaRadarPlayingProvider.notifier).state = false;
  }

  void togglePlayPause() {
    final current = _ref.read(climaRadarPlayingProvider);
    _ref.read(climaRadarPlayingProvider.notifier).state = !current;
  }

  void stepNext(int totalFrames) {
    if (totalFrames <= 0) return;
    pause();
    final indexNotifier = _ref.read(climaRadarFrameIndexProvider.notifier);
    indexNotifier.state = (indexNotifier.state + 1) % totalFrames;
  }

  void stepPrevious(int totalFrames) {
    if (totalFrames <= 0) return;
    pause();
    final indexNotifier = _ref.read(climaRadarFrameIndexProvider.notifier);
    indexNotifier.state = (indexNotifier.state - 1 + totalFrames) % totalFrames;
  }

  void seekTo(int targetIndex, int totalFrames) {
    if (totalFrames <= 0) return;
    pause();
    _ref.read(climaRadarFrameIndexProvider.notifier).state =
        targetIndex.clamp(0, totalFrames - 1);
  }

  void setColorScheme(int scheme) {
    if (_ref.read(climaRadarColorSchemeProvider) == scheme) return;
    _ref.read(climaRadarColorSchemeProvider.notifier).state = scheme;
  }

  void setCoverageEnabled(bool enabled) {
    _ref.read(climaRadarCoverageEnabledProvider.notifier).state = enabled;
  }

  void toggleCoverage() {
    final current = _ref.read(climaRadarCoverageEnabledProvider);
    setCoverageEnabled(!current);
  }

  void snapToLatestPastFrame(List<ClimaRadarFrame> frames) {
    if (frames.isEmpty) return;
    _ref.read(climaRadarFrameIndexProvider.notifier).state =
        climaRadarLatestPastFrameIndex(frames);
  }

  void clampFrameIndex(int totalFrames) {
    if (totalFrames <= 0) return;
    final indexNotifier = _ref.read(climaRadarFrameIndexProvider.notifier);
    indexNotifier.state = indexNotifier.state.clamp(0, totalFrames - 1);
  }
}

final climaRadarPlaybackControllerProvider =
    Provider.autoDispose<ClimaRadarPlaybackController>((ref) {
      return ClimaRadarPlaybackController(ref);
    });
