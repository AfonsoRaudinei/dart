import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/infra/preferences_service.dart';
import '../../data/datasources/rainviewer_radar_datasource.dart';
import '../../domain/entities/radar_fetch_result.dart';

export '../../data/datasources/rainviewer_radar_datasource.dart'
    show ClimaRadarFetch, parseClimaRadarFrames;
export '../../domain/entities/radar_fetch_result.dart';
export '../../domain/radar_frame_age_label.dart';
export '../../domain/entities/radar_rain_frame.dart';
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
final climaRadarEnabledProvider =
    NotifierProvider<ClimaRadarEnabled, bool>(ClimaRadarEnabled.new);

class ClimaRadarEnabled extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(preferencesServiceProvider).getBool(
          climaRadarEnabledPreferenceKey,
        ) ??
        false;
  }

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    ref.read(preferencesServiceProvider).setBool(
      climaRadarEnabledPreferenceKey,
      enabled,
    );
  }
}

/// Índice do frame atual da animação do radar.
final climaRadarFrameIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Manifesto RainViewer parseado com status explícito para UX e telemetria.
final climaRadarFramesProvider =
    FutureProvider.autoDispose<ClimaRadarFetchResult>((ref) async {
      return ref.watch(climaRadarDatasourceProvider).fetchPastFrames();
    });
